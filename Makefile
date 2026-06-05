SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

ARG_TARGETS := \
	cabal-project \
	cabal-renamer-logs \
	raw-logs \
	renamer-logs \
	all-orders-logs \
	run-permutations

ifneq ($(filter $(ARG_TARGETS),$(firstword $(MAKECMDGOALS))),)
EXTRA_GOALS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ifneq ($(strip $(EXTRA_GOALS)),)
$(eval .PHONY: $(EXTRA_GOALS))
$(eval $(EXTRA_GOALS):;@:)
endif
endif

PHONY_TARGETS := \
	help \
	verify-toolchain \
	add-submodule \
	init-submodule-recursive \
	verify-submodule \
	setup-ghc-build \
	patches \
	build \
	test \
	reproduce \
	start-docker \
	shell \
	shell-clear \
	restart-ghc \
	cabal-project \
	cabal-renamer-logs \
	raw-logs \
	renamer-logs \
	all-orders-logs \
	ghc-quick

.PHONY: $(PHONY_TARGETS)

help: ## Muestra esta ayuda y los comandos disponibles
	@echo "Uso: make <comando>"
	@echo ""
	@echo "Comandos disponibles:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

verify-toolchain: ## Verifica que la toolchain del contenedor este disponible
	bash .devcontainer/verify_dev_toolchain.sh

add-submodule: ## Agrega o reutiliza vendor/ghc y lo fija al commit objetivo
	bash scripts/setup-ghc/add_ghc_submodule.sh

init-submodule-recursive: ## Inicializa submodulos anidados de GHC (para ./boot)
	INIT_GHC_NESTED_SUBMODULES=1 bash scripts/setup-ghc/init_submodules.sh

verify-submodule: ## Verifica que vendor/ghc este en el commit esperado
	bash scripts/setup-ghc/verify_ghc_commit.sh

setup-ghc-build: add-submodule init-submodule-recursive verify-submodule ## Prepara vendor/ghc para compilar GHC (incluye anidados)

patches: ## Aplica parches desde patches/*.patch
	bash scripts/apply_patches.sh

build: ## Ejecuta el proceso de build
	cd /workspaces/tt-repo/vendor/ghc && \
	./boot && \
	./configure && \
	./hadrian/build -j --flavour=quick stage2:exe:ghc-bin 

test: ## Ejecuta pruebas y validaciones
	bash scripts/test.sh

reproduce: verify-toolchain setup-ghc-build patches build test ## Ejecuta el flujo reproducible completo

start-docker: ## Inicia el contenedor de desarrollo
	docker start ghc-dev-container

shell: ## Abre la shell del dev continer
	@if [ "$$(docker inspect -f '{{.State.Running}}' ghc-dev-container 2>/dev/null)" != "true" ]; then \
		$(MAKE) --no-print-directory start-docker; \
	fi
	docker exec -it ghc-dev-container bash;

shell-clear: ## Abre la shell del dev container y la limpia
	@if [ "$$(docker inspect -f '{{.State.Running}}' ghc-dev-container 2>/dev/null)" != "true" ]; then \
		$(MAKE) --no-print-directory start-docker; \
	fi
	docker exec -it ghc-dev-container bash -lc "clear; exec bash"
	
restart-ghc: ## Reinicia el submodulo de GHC al commit objetivo
	@git -C vendor/ghc reset --hard
	@git -C vendor/ghc clean -ffd
	@git -C vendor/ghc switch --detach 0b36e96cb93db71f201aaa055c4a90b75a8110ef

cabal-project: ## Crea proyecto cabal: make cabal-project <package-name>
	@pkg="$(word 2,$(MAKECMDGOALS))"; \
	if [ -z "$$pkg" ]; then \
		echo "Uso: make cabal-project <package-name>"; \
		exit 1; \
	fi; \
	mkdir -p "experiments/$$pkg" && \
	cd "experiments/$$pkg" && \
	cabal init -n --exe --package-name "$$pkg" --language GHC2024 \
	  --minimal --no-comments --license NONE --main-is main.hs --application-dir . && \
	rm -f CHANGELOG.md && \
	printf "import: /workspaces/tt-repo/config/cabal.project\npackages: .\n" > cabal.project

cabal-renamer-logs: ## Crea logs con el arbol de Statements: make cabal-renamer-logs <project-dir> <output-log-file>
	@cabal_dir="$(word 2,$(MAKECMDGOALS))"; \
	log_file="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$cabal_dir" ] || [ -z "$$log_file" ]; then \
		echo "Uso: make cabal-rename-logs <directorio-cabal> <archivo-log>"; \
		exit 1; \
	fi; \
	cd "$$cabal_dir" && \
	mkdir -p "$$(dirname "$$log_file")" && \
	grep -Pzo '(?s)=\s*do\b.*?\n\s*return\b[^\n]*' main.hs \
	  | tr '\0' '\n' \
	  | tee "$$log_file" && \
	printf '\n' >> "$$log_file" && \
	cabal clean && \
	cabal build 2>&1 \
	  | awk '/^rearrangeForADo final tree:/ {capture=1} capture {print} capture && /^[[:space:]]*cost[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*$$/ {capture=0}' \
	  | tee -a "$$log_file"

raw-logs: ## Crea logs con la salida completa de GHC: make raw-logs <input-file> <output-log-file>
	@input_file="$(word 2,$(MAKECMDGOALS))"; \
	log_file="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$input_file" ] || [ -z "$$log_file" ]; then \
		echo "Uso: make raw-logs <archivo-hs> <archivo-log>"; \
		exit 1; \
	fi; \
	mkdir -p "$$(dirname "$$log_file")" && \
	./vendor/ghc/_build/stage1/bin/ghc -ddump-rn-trace -XApplicativeDo -freorder-commutative-monads-ado -fno-code "$$input_file" | tee "$$log_file"

renamer-logs: ## Crea logs con el arbol de Statements: make renamer-logs <input-file> <output-log-file>
	@input_file="$(word 2,$(MAKECMDGOALS))"; \
	log_file="$(word 3,$(MAKECMDGOALS))"; \
	mode_flag="$(word 4,$(MAKECMDGOALS))"; \
	if [ -z "$$input_file" ] || [ -z "$$log_file" ]; then \
		echo "Uso: make ghc-rename-logs <archivo-hs> <archivo-log> [-concat]"; \
		exit 1; \
	fi; \
	if [ -n "$$mode_flag" ] && [ "$$mode_flag" != "-concat" ]; then \
		echo "Flag opcional no valida: $$mode_flag"; \
		echo "Uso: make ghc-rename-logs <archivo-hs> <archivo-log> [-concat]"; \
		exit 1; \
	fi; \
	if [ "$$mode_flag" = "-concat" ]; then \
		first_tee_opt="-a"; \
		printf '\n' | tee -a "$$log_file"; \
	else \
		first_tee_opt=""; \
	fi; \
	mkdir -p "$$(dirname "$$log_file")" && \
	grep -Pzo '(?s)=\s*do\b.*?\n\s*return\b[^\n]*' "$$input_file" \
	  | tr '\0' '\n' \
	  | tee $$first_tee_opt "$$log_file" && \
	printf '\n' | tee -a "$$log_file" && \
	./vendor/ghc/_build/stage1/bin/ghc -ddump-rn-trace -XApplicativeDo -fno-code "$$input_file" \
	  | awk '/^rearrangeForADo final tree:/ {capture=1} capture {print} capture && /^[[:space:]]*cost[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*$$/ {capture=0}' \
	  | tee -a "$$log_file"

all-orders-logs: ## Crea logs con todas las permutaciones de Statements: make renamer-logs <program-dir> <output-log-file>
	@target_dir="$(word 2,$(MAKECMDGOALS))"; \
	log_file="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$target_dir" ] || [ -z "$$log_file" ]; then \
		echo "Uso: make all-monad-reorder <program-dir> <log_file>"; \
		exit 1; \
	fi; \
	repo_root="$$(pwd)"; \
	if [[ "$$target_dir" = /* ]]; then \
		target_dir_abs="$$target_dir"; \
	else \
		target_dir_abs="$$repo_root/$$target_dir"; \
	fi; \
	if [[ "$$log_file" = /* ]]; then \
		log_file_abs="$$log_file"; \
	else \
		log_file_abs="$$repo_root/$$log_file"; \
	fi; \
	mkdir -p "$$target_dir_abs/permutations"; \
	cd "$$repo_root/experiments" && \
	python3 build_precedence_graph_files.py "$$target_dir_abs/main.hs" "$$target_dir_abs/permutations/" && \
	printf '\n== Todas las permutaciones validas del programa ==\n' | tee "$$log_file_abs" && \
	cd "$$repo_root" && \
	shopt -s nullglob; \
	files=($$target_dir_abs/permutations/*.hs); \
	if [ $${#files[@]} -eq 0 ]; then \
		echo "No se generaron permutaciones en $$target_dir_abs/permutations"; \
		exit 1; \
	fi; \
	for i in "$${!files[@]}"; do \
		f="$${files[$$i]}"; \
		$(MAKE) --no-print-directory -- renamer-logs "$$f" "$$log_file_abs" -concat; \
		printf -- '\n----------------------------------------------------------------------------------------\n' | tee -a "$$log_file_abs"; \
	done

run-permutations: ## Compila y ejecuta todas las permutaciones: make run-permutations-bin <input-dir> <output-dir>
	@input_dir="$(word 2,$(MAKECMDGOALS))"; \
	output_dir="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$input_dir" ] || [ -z "$$output_dir" ]; then \
		echo "Uso: make run-permutations-bin <input-dir> <output-dir>"; \
		exit 1; \
	fi; \
	if [[ "$$input_dir" = /* ]]; then \
		input_dir_abs="$$input_dir"; \
	else \
		input_dir_abs="$$(pwd)/$$input_dir"; \
	fi; \
	if [[ "$$output_dir" = /* ]]; then \
		output_dir_abs="$$output_dir"; \
	else \
		output_dir_abs="$$(pwd)/$$output_dir"; \
	fi; \
	mkdir -p "$$output_dir_abs"; \
	permutations=("$$input_dir_abs"/*.hs); \
	for f in "$${permutations[@]}"; do \
		base="$$(basename "$$f" .hs)"; \
		out_bin="$$output_dir_abs/$$base"; \
		echo "[COMPILAR] $$f -> $$out_bin"; \
		./vendor/ghc/_build/stage1/bin/ghc -O0 -fforce-recomp "$$f" -o "$$out_bin"; \
	done; \
	echo "== Ejecutando binarios =="; \
	permutations_bins=("$$output_dir_abs"/*); \
	for b in "$${permutations_bins[@]}"; do \
		if [ -x "$$b" ] && [ -f "$$b" ]; then \
			echo "[EJECUTAR] $$b"; \
			"$$b"; \
		fi; \
	done

ghc-quick: ## Compilar y buildear GHC modificado
	cd /workspaces/tt-repo/vendor/ghc && \
	./hadrian/build -j --flavour=quick stage2:exe:ghc-bin 
