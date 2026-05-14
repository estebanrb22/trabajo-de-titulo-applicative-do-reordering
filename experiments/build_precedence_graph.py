#!/usr/bin/env python3
"""
build_precedence_graph.py

Construye el grafo de precedencia de un bloque do de Haskell muy simple.

Uso:
    python3 build_precedence_graph.py archivo.hs
    python3 build_precedence_graph.py archivo.hs --show-reasons

Subconjunto soportado:
    value_name = do
      x1 <- e1
      x2 <- e2
      ...
      xn <- en
      return expr

Restricciones:
    - Se analiza el primer bloque `= do` encontrado.
    - Cada statement monádico debe estar en una línea y tener la forma `x <- e`.
    - El lado izquierdo debe ser una sola variable.
    - Las variables libres del lado derecho se reconocen sintácticamente como
      identificadores Haskell que contienen al menos un dígito, por ejemplo:
      x1, x1a, y2, tmp3.
    - No se implementa un parser completo de Haskell.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, OrderedDict as OrderedDictType, Set, Tuple


# Identificadores Haskell simplificados que comienzan con minúscula o _.
# Luego se filtran solo aquellos que contienen al menos un dígito para evitar
# reconocer constructores como Just, Nothing o funciones como safeDiv.
IDENTIFIER_RE = re.compile(r"\b[a-z_][A-Za-z0-9_']*\b")
BIND_RE = re.compile(r"^\s*([a-z_][A-Za-z0-9_']*)\s*<-\s*(.+?)\s*$")
DO_START_RE = re.compile(r"=\s*do\b")
RETURN_RE = re.compile(r"^\s*return\b")


@dataclass(frozen=True)
class Statement:
    """Representación mínima de un statement `x <- e` dentro de do-notation."""

    index: int
    lhs: str
    rhs: str
    reads: Set[str]
    writes: Set[str]

    @property
    def label(self) -> str:
        return f"s{self.index}"

    @property
    def source(self) -> str:
        return f"{self.lhs} <- {self.rhs}"


def strip_line_comment(line: str) -> str:
    """Elimina comentarios de línea de Haskell introducidos por --.

    Esta función es deliberadamente simple: no distingue `--` dentro de strings.
    Para el subconjunto experimental descrito, esto es suficiente.
    """

    return line.split("--", 1)[0].rstrip("\n")


def indentation(line: str) -> int:
    """Retorna la indentación en espacios, tratando tabs como 4 espacios."""

    expanded = line.expandtabs(4)
    return len(expanded) - len(expanded.lstrip(" "))


def extract_first_do_block(lines: List[str]) -> List[str]:
    """Extrae las líneas del primer bloque `= do` encontrado en el archivo."""

    do_indent = None
    body: List[str] = []
    inside_do = False

    for line in lines:
        raw = line.rstrip("\n")
        no_comment = strip_line_comment(raw)

        if not inside_do:
            if DO_START_RE.search(no_comment):
                inside_do = True
                do_indent = indentation(raw)
            continue

        assert do_indent is not None

        # Las líneas vacías dentro del bloque no lo terminan.
        if not no_comment.strip():
            continue

        # Al volver a una indentación menor o igual que la línea `= do`, termina
        # el bloque. Esto calza con definiciones top-level simples.
        if indentation(raw) <= do_indent:
            break

        body.append(no_comment)

    if not inside_do:
        raise ValueError("No se encontró ningún bloque de la forma `= do` en el archivo.")

    return body


def extract_free_variables(expr: str) -> Set[str]:
    """Extrae variables libres sintácticas desde el RHS.

    Criterio usado por este prototipo: se consideran solo identificadores que
    contienen al menos un dígito. Así, `x1`, `x1a` o `tmp3` se reconocen como
    variables, mientras que `safeDiv`, `Just` o `return` no se consideran.
    """

    candidates = IDENTIFIER_RE.findall(expr)
    return {name for name in candidates if any(ch.isdigit() for ch in name)}


def parse_do_statements(do_lines: Iterable[str]) -> List[Statement]:
    """Parsea statements `x <- e` desde las líneas internas del bloque do."""

    statements: List[Statement] = []

    for line in do_lines:
        if RETURN_RE.match(line):
            # La expresión final no se incorpora como vértice, porque el usuario
            # pidió grafo sobre statements `xn <- en`.
            continue

        match = BIND_RE.match(line)
        if not match:
            # El subconjunto es deliberadamente pequeño. Se ignoran líneas que no
            # sean bind statements simples, pero se informa de forma explícita.
            raise ValueError(
                "Línea no soportada dentro del bloque do. "
                f"Se esperaba `x <- e`, pero se obtuvo: {line.strip()}"
            )

        lhs, rhs = match.group(1), match.group(2)
        reads = extract_free_variables(rhs)
        writes = {lhs}

        statements.append(
            Statement(
                index=len(statements) + 1,
                lhs=lhs,
                rhs=rhs,
                reads=reads,
                writes=writes,
            )
        )

    if not statements:
        raise ValueError("El bloque do no contiene statements de la forma `x <- e`.")

    return statements


def extract_return_expression(do_lines: Iterable[str]) -> str | None:
    """Extrae la expresión de la primera línea `return e` del bloque do.

    La expresión final no participa como vértice del grafo en este prototipo,
    pero se conserva para imprimir cada permutación en una notación similar a
    un programa Haskell.
    """

    for line in do_lines:
        if RETURN_RE.match(line):
            return re.sub(r"^\s*return\b", "", line).strip()

    return None


def dependency_kinds(si: Statement, sj: Statement) -> List[str]:
    """Determina las dependencias RAW, WAR y WAW entre si y sj, con i < j."""

    kinds: List[str] = []

    raw = si.writes & sj.reads
    war = si.reads & sj.writes
    waw = si.writes & sj.writes

    if raw:
        kinds.append("RAW(" + ",".join(sorted(raw)) + ")")
    if war:
        kinds.append("WAR(" + ",".join(sorted(war)) + ")")
    if waw:
        kinds.append("WAW(" + ",".join(sorted(waw)) + ")")

    return kinds


def analyze_precedence_graph_with_return(
    hs_filename: str,
) -> Tuple[
    OrderedDictType[str, List[str]],
    List[Statement],
    Dict[Tuple[str, str], List[str]],
    str | None,
]:
    """Construye el grafo junto con metadatos útiles para imprimir/debuggear."""

    path = Path(hs_filename)
    if not path.is_file():
        raise FileNotFoundError(f"No existe el archivo: {hs_filename}")

    lines = path.read_text(encoding="utf-8").splitlines()
    do_lines = extract_first_do_block(lines)
    statements = parse_do_statements(do_lines)
    return_expr = extract_return_expression(do_lines)

    adjacency: OrderedDictType[str, List[str]] = OrderedDict(
        (stmt.label, []) for stmt in statements
    )
    edge_reasons: Dict[Tuple[str, str], List[str]] = {}

    for i in range(len(statements)):
        for j in range(i + 1, len(statements)):
            si = statements[i]
            sj = statements[j]
            kinds = dependency_kinds(si, sj)

            if kinds:
                adjacency[si.label].append(sj.label)
                edge_reasons[(si.label, sj.label)] = kinds

    return adjacency, statements, edge_reasons, return_expr


def analyze_precedence_graph(
    hs_filename: str,
) -> Tuple[OrderedDictType[str, List[str]], List[Statement], Dict[Tuple[str, str], List[str]]]:
    """Construye el grafo junto con metadatos útiles para imprimir/debuggear.

    Se mantiene esta función con la misma firma de la versión anterior para no
    romper usos existentes.
    """

    adjacency, statements, edge_reasons, _return_expr = analyze_precedence_graph_with_return(
        hs_filename
    )
    return adjacency, statements, edge_reasons


def build_precedence_graph(hs_filename: str) -> OrderedDictType[str, List[str]]:
    """Construye la lista de adyacencia del grafo de precedencia.

    Para cada par de statements si, sj con i < j, se agrega la arista si -> sj
    si existe al menos una dependencia RAW, WAR o WAW:

        Wi ∩ Rj != ∅  o  Ri ∩ Wj != ∅  o  Wi ∩ Wj != ∅

    Retorna únicamente la lista de adyacencia con etiquetas s1, s2, ...
    """

    adjacency, _statements, _edge_reasons = analyze_precedence_graph(hs_filename)
    return adjacency


def get_all_valid_permutations(
    precedence_graph: OrderedDictType[str, List[str]],
) -> List[List[str]]:
    """Enumera todas las permutaciones válidas del DAG de precedencia.

    Cada permutación retornada es una lista de etiquetas de statements, por
    ejemplo `["s1", "s4", "s2"]`. La implementación corresponde al
    algoritmo clásico de enumeración de todos los ordenamientos topológicos:

    1. calcular el indegree de cada vértice;
    2. elegir cualquier vértice no emitido con indegree cero;
    3. emitirlo temporalmente, eliminar sus aristas salientes y continuar por
       backtracking;
    4. restaurar el estado para explorar otras alternativas.

    Si alguna arista apunta a un vértice inexistente, se reporta como error. Si
    el grafo tiene ciclos, no existe ningún ordenamiento topológico válido y se
    lanza ValueError.
    """

    vertices = list(precedence_graph.keys())
    vertex_set = set(vertices)

    indegree: Dict[str, int] = {vertex: 0 for vertex in vertices}
    for src, targets in precedence_graph.items():
        if src not in vertex_set:
            raise ValueError(f"Vértice fuente desconocido en el grafo: {src}")
        for dst in targets:
            if dst not in vertex_set:
                raise ValueError(
                    f"La arista {src} -> {dst} apunta a un vértice inexistente."
                )
            indegree[dst] += 1

    emitted: Set[str] = set()
    current_order: List[str] = []
    valid_permutations: List[List[str]] = []

    def backtrack() -> None:
        if len(current_order) == len(vertices):
            valid_permutations.append(list(current_order))
            return

        zero_indegree_vertices = [
            vertex
            for vertex in vertices
            if vertex not in emitted and indegree[vertex] == 0
        ]

        for vertex in zero_indegree_vertices:
            emitted.add(vertex)
            current_order.append(vertex)

            for target in precedence_graph[vertex]:
                indegree[target] -= 1

            backtrack()

            for target in precedence_graph[vertex]:
                indegree[target] += 1

            current_order.pop()
            emitted.remove(vertex)

    backtrack()

    if not valid_permutations and vertices:
        raise ValueError(
            "El grafo no tiene ordenamientos topológicos. "
            "Probablemente contiene un ciclo."
        )

    return valid_permutations


def print_graph(
    adjacency: OrderedDictType[str, List[str]],
    statements: List[Statement],
    edge_reasons: Dict[Tuple[str, str], List[str]],
    show_reasons: bool,
) -> None:
    """Imprime el grafo en consola como lista de adyacencia."""

    print("Statements detectados:")
    for stmt in statements:
        reads = "{" + ", ".join(sorted(stmt.reads)) + "}"
        writes = "{" + ", ".join(sorted(stmt.writes)) + "}"
        print(f"  {stmt.label}: {stmt.source}    W={writes}, R={reads}")

    print("\nLista de adyacencia:")
    for src, targets in adjacency.items():
        if not targets:
            print(f"  {src} -> ∅")
            continue

        if not show_reasons:
            print(f"  {src} -> " + ", ".join(targets))
            continue

        rendered_targets = []
        for dst in targets:
            reasons = "/".join(edge_reasons.get((src, dst), []))
            rendered_targets.append(f"{dst} [{reasons}]")

        print(f"  {src} -> " + ", ".join(rendered_targets))


def print_valid_permutations(
    permutations: List[List[str]],
    statements: List[Statement],
    return_expr: str | None,
) -> None:
    """Imprime las permutaciones válidas en notación simbólica y Haskell."""

    statements_by_label = {stmt.label: stmt for stmt in statements}

    print("\nPermutaciones semánticamente válidas en notación s_n:")
    for index, permutation in enumerate(permutations, start=1):
        print(f"  p{index}: " + "; ".join(permutation))

    print("\nPermutaciones semánticamente válidas en notación Haskell cruda:")
    for index, permutation in enumerate(permutations, start=1):
        print(f"\n-- p{index}: " + "; ".join(permutation))
        print("do")
        for label in permutation:
            print(f"  {statements_by_label[label].source}")
        if return_expr is not None:
            print(f"  return {return_expr}")
        else:
            print("  -- return <no detectado>")


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Construye el grafo de precedencia RAW/WAR/WAW y enumera sus permutaciones válidas."
    )
    parser.add_argument("hs_file", help="Archivo .hs de entrada")
    parser.add_argument(
        "--show-reasons",
        action="store_true",
        help="Muestra RAW/WAR/WAW junto a cada arista.",
    )

    args = parser.parse_args(argv)

    try:
        adjacency, statements, edge_reasons, return_expr = analyze_precedence_graph_with_return(
            args.hs_file
        )
        print_graph(adjacency, statements, edge_reasons, args.show_reasons)
        permutations = get_all_valid_permutations(adjacency)
        print_valid_permutations(permutations, statements, return_expr)
        return 0
    except Exception as exc:  # noqa: BLE001 - error legible para CLI experimental
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
