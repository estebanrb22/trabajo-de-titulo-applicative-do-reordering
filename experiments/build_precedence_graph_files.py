#!/usr/bin/env python3
"""
build_precedence_graph.py

Construye el grafo de precedencia de un bloque do de Haskell muy simple,
enumera todas sus permutaciones válidas y genera un archivo .hs por cada
permutación.

Uso:
    python3 build_precedence_graph.py archivo.hs directorio_salida
    python3 build_precedence_graph.py archivo.hs directorio_salida --show-reasons

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
    - Los archivos generados conservan todo el programa original y solo cambian
      el orden de las líneas `x <- e` detectadas dentro del primer bloque do.
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
class DoLine:
    """Línea interna de un bloque do, junto con su índice en el archivo."""

    line_index: int
    raw: str
    no_comment: str


@dataclass(frozen=True)
class Statement:
    """Representación mínima de un statement `x <- e` dentro de do-notation."""

    index: int
    lhs: str
    rhs: str
    reads: Set[str]
    writes: Set[str]
    line_index: int | None = None
    raw_source: str | None = None

    @property
    def label(self) -> str:
        return f"s{self.index}"

    @property
    def source(self) -> str:
        """Código fuente del statement sin indentación inicial."""

        if self.raw_source is not None:
            return self.raw_source.strip()
        return f"{self.lhs} <- {self.rhs}"


@dataclass(frozen=True)
class AnalysisResult:
    """Resultado completo del análisis del primer bloque do."""

    adjacency: OrderedDictType[str, List[str]]
    statements: List[Statement]
    edge_reasons: Dict[Tuple[str, str], List[str]]
    return_expr: str | None
    original_lines: List[str]
    original_text: str
    had_final_newline: bool


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


def leading_whitespace(line: str) -> str:
    """Retorna la indentación original de una línea."""

    return line[: len(line) - len(line.lstrip(" \t"))]


def extract_first_do_block_entries(lines: List[str]) -> List[DoLine]:
    """Extrae las líneas no vacías del primer bloque `= do` encontrado.

    Se conservan los índices originales para poder reescribir únicamente las
    líneas correspondientes a statements monádicos.
    """

    do_indent = None
    body: List[DoLine] = []
    inside_do = False

    for line_index, line in enumerate(lines):
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

        body.append(DoLine(line_index=line_index, raw=raw, no_comment=no_comment))

    if not inside_do:
        raise ValueError("No se encontró ningún bloque de la forma `= do` en el archivo.")

    return body


def extract_first_do_block(lines: List[str]) -> List[str]:
    """Compatibilidad: retorna solo las líneas internas del primer bloque do."""

    return [entry.no_comment for entry in extract_first_do_block_entries(lines)]


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
                raw_source=line.strip(),
            )
        )

    if not statements:
        raise ValueError("El bloque do no contiene statements de la forma `x <- e`.")

    return statements


def parse_do_statements_from_entries(do_entries: Iterable[DoLine]) -> List[Statement]:
    """Parsea statements `x <- e` conservando sus posiciones en el archivo."""

    statements: List[Statement] = []

    for entry in do_entries:
        if RETURN_RE.match(entry.no_comment):
            continue

        match = BIND_RE.match(entry.no_comment)
        if not match:
            raise ValueError(
                "Línea no soportada dentro del bloque do. "
                f"Se esperaba `x <- e`, pero se obtuvo: {entry.raw.strip()}"
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
                line_index=entry.line_index,
                raw_source=entry.raw.strip(),
            )
        )

    if not statements:
        raise ValueError("El bloque do no contiene statements de la forma `x <- e`.")

    return statements


def extract_return_expression(do_lines: Iterable[str]) -> str | None:
    """Extrae la expresión de la primera línea `return e` del bloque do."""

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


def build_adjacency_and_reasons(
    statements: List[Statement],
) -> Tuple[OrderedDictType[str, List[str]], Dict[Tuple[str, str], List[str]]]:
    """Construye la lista de adyacencia y las razones de cada arista."""

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

    return adjacency, edge_reasons


def analyze_file(hs_filename: str) -> AnalysisResult:
    """Analiza el archivo Haskell y retorna el grafo con metadatos de reescritura."""

    path = Path(hs_filename)
    if not path.is_file():
        raise FileNotFoundError(f"No existe el archivo: {hs_filename}")

    original_text = path.read_text(encoding="utf-8")
    had_final_newline = original_text.endswith("\n")
    lines = original_text.splitlines()

    do_entries = extract_first_do_block_entries(lines)
    statements = parse_do_statements_from_entries(do_entries)
    return_expr = extract_return_expression(entry.no_comment for entry in do_entries)
    adjacency, edge_reasons = build_adjacency_and_reasons(statements)

    return AnalysisResult(
        adjacency=adjacency,
        statements=statements,
        edge_reasons=edge_reasons,
        return_expr=return_expr,
        original_lines=lines,
        original_text=original_text,
        had_final_newline=had_final_newline,
    )


def analyze_precedence_graph(
    hs_filename: str,
) -> Tuple[OrderedDictType[str, List[str]], List[Statement], Dict[Tuple[str, str], List[str]]]:
    """Construye el grafo junto con metadatos útiles para imprimir/debuggear.

    Se mantiene esta función con la misma firma de versiones anteriores para no
    romper usos existentes.
    """

    result = analyze_file(hs_filename)
    return result.adjacency, result.statements, result.edge_reasons


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
    precedence_graph: OrderedDictType[str, List[str]]
) -> List[List[str]]:
    """Enumera todos los ordenamientos topológicos del grafo de precedencia.

    Cada ordenamiento topológico representa una permutación válida de statements:
    ninguna arista dirigida si -> sj queda invertida.
    """

    nodes = list(precedence_graph.keys())
    indegree: Dict[str, int] = {node: 0 for node in nodes}

    for src, targets in precedence_graph.items():
        for dst in targets:
            if dst not in indegree:
                raise ValueError(f"El grafo contiene un vértice destino desconocido: {dst}")
            indegree[dst] += 1

    emitted: Set[str] = set()
    current_order: List[str] = []
    all_orders: List[List[str]] = []

    def backtrack() -> None:
        if len(current_order) == len(nodes):
            all_orders.append(current_order.copy())
            return

        available = [node for node in nodes if node not in emitted and indegree[node] == 0]

        if not available:
            raise ValueError(
                "El grafo no posee ordenamiento topológico. "
                "Probablemente contiene un ciclo."
            )

        for node in available:
            emitted.add(node)
            current_order.append(node)

            for dst in precedence_graph[node]:
                indegree[dst] -= 1

            backtrack()

            for dst in precedence_graph[node]:
                indegree[dst] += 1

            current_order.pop()
            emitted.remove(node)

    backtrack()
    return all_orders


def order_permutations_with_original_first(
    permutations: List[List[str]], original_order: List[str]
) -> List[List[str]]:
    """Asegura que la permutación 0 sea el orden original del programa."""

    return [original_order] + [perm for perm in permutations if perm != original_order]


def render_permutation_as_do_block(
    permutation: List[str], statements_by_label: Dict[str, Statement], return_expr: str | None
) -> str:
    """Renderiza una permutación como bloque `do` crudo para consola."""

    lines = ["do"]
    for label in permutation:
        lines.append(f"  {statements_by_label[label].source}")

    if return_expr is not None:
        lines.append(f"  return {return_expr}")

    return "\n".join(lines)


def rewrite_program_with_permutation(result: AnalysisResult, permutation: List[str]) -> str:
    """Retorna el programa Haskell con los statements del do reordenados."""

    statements_by_label = {stmt.label: stmt for stmt in result.statements}
    original_slots = sorted(result.statements, key=lambda stmt: stmt.index)
    rewritten_lines = result.original_lines.copy()

    if len(permutation) != len(original_slots):
        raise ValueError("La permutación no contiene la misma cantidad de statements.")

    for target_slot, source_label in zip(original_slots, permutation):
        if target_slot.line_index is None:
            raise ValueError("No se puede reescribir: falta información de línea del statement.")

        source_stmt = statements_by_label[source_label]
        original_target_line = rewritten_lines[target_slot.line_index]
        rewritten_lines[target_slot.line_index] = (
            leading_whitespace(original_target_line) + source_stmt.source
        )

    generated = "\n".join(rewritten_lines)
    if result.had_final_newline:
        generated += "\n"
    return generated


def generate_permuted_programs(hs_filename: str, output_dir: str) -> List[Tuple[int, List[str], Path]]:
    """Genera un archivo .hs por cada permutación válida.

    El archivo `*-per-0.hs` corresponde siempre al programa original sin modificar.
    """

    result = analyze_file(hs_filename)
    all_permutations = get_all_valid_permutations(result.adjacency)
    original_order = list(result.adjacency.keys())
    ordered_permutations = order_permutations_with_original_first(all_permutations, original_order)

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    input_path = Path(hs_filename)
    base_name = input_path.stem
    generated_files: List[Tuple[int, List[str], Path]] = []

    for index, permutation in enumerate(ordered_permutations):
        target_file = output_path / f"{base_name}-{index}.hs"

        if index == 0:
            # Requisito explícito: n = 0 es el programa original sin modificar.
            target_file.write_text(result.original_text, encoding="utf-8")
        else:
            target_file.write_text(
                rewrite_program_with_permutation(result, permutation),
                encoding="utf-8",
            )

        generated_files.append((index, permutation, target_file))

    return generated_files


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


def print_permutations(
    permutations: List[List[str]],
    statements: List[Statement],
    return_expr: str | None,
) -> None:
    """Imprime las permutaciones en notación s_n y como bloque do crudo."""

    statements_by_label = {stmt.label: stmt for stmt in statements}

    print("\nPermutaciones válidas en notación s_n:")
    for index, permutation in enumerate(permutations):
        print(f"  per-{index}: " + " ; ".join(permutation))

    print("\nPermutaciones válidas como código Haskell crudo:")
    for index, permutation in enumerate(permutations):
        print(f"\n-- per-{index}")
        print(render_permutation_as_do_block(permutation, statements_by_label, return_expr))


def print_generated_files(generated_files: List[Tuple[int, List[str], Path]]) -> None:
    """Imprime resumen de archivos generados."""

    print("\nArchivos .hs generados:")
    for index, _permutation, path in generated_files:
        print(f"  per-{index}: {path}")


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Construye el grafo de precedencia RAW/WAR/WAW de un bloque do simple, "
            "enumera sus permutaciones válidas y genera un .hs por permutación."
        )
    )
    parser.add_argument("hs_file", help="Archivo .hs de entrada")
    parser.add_argument("output_dir", help="Directorio donde se guardarán los .hs generados")
    parser.add_argument(
        "--show-reasons",
        action="store_true",
        help="Muestra RAW/WAR/WAW junto a cada arista.",
    )

    args = parser.parse_args(argv)

    try:
        result = analyze_file(args.hs_file)
        all_permutations = get_all_valid_permutations(result.adjacency)
        original_order = list(result.adjacency.keys())
        ordered_permutations = order_permutations_with_original_first(
            all_permutations,
            original_order,
        )

        print_graph(result.adjacency, result.statements, result.edge_reasons, args.show_reasons)
        print_permutations(ordered_permutations, result.statements, result.return_expr)

        generated_files = generate_permuted_programs(args.hs_file, args.output_dir)
        print_generated_files(generated_files)

        return 0
    except Exception as exc:  # noqa: BLE001 - error legible para CLI experimental
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
