SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

ARG_TARGETS := \
	cabal-project \
	cabal-prob-project \
	cabal-renamer-logs \
	raw-logs \
	renamer-logs \
	test-ghc \
	test-cabal \
	semantic-validation-reorder \
	semantic-validation-reorder-ghc \
	semantic-validation-reorder-cabal

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
	test-ghc \
	test-cabal \
	reproduce \
	start-docker \
	shell \
	shell-clear \
	restart-ghc \
	cabal-project \
	cabal-prob-project \
	cabal-renamer-logs \
	raw-logs \
	renamer-logs \
	semantic-validation-reorder \
	semantic-validation-reorder-ghc \
	semantic-validation-reorder-cabal \
	ghc-quick

.PHONY: $(PHONY_TARGETS)

help: ## Muestra esta ayuda y los comandos disponibles
	@echo "Uso: make <comando>"
	@echo ""
	@echo "Comandos disponibles:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start-docker: ## Inicia el contenedor de desarrollo
	docker start ghc-dev-container

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
	echo "Ejecutando pruebas y validaciones... (No implementado aún)"

test-ghc: ## Wrapper GHC directo: make test-ghc <experiments/.../main.hs>
	@input_file="$(word 2,$(MAKECMDGOALS))"; \
	extra_arg="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$input_file" ] || [ -n "$$extra_arg" ]; then \
		echo "Uso: make test-ghc <experiments/.../main.hs>"; \
		exit 1; \
	fi; \
	input_file="$${input_file%/}"; \
	if [[ "$$input_file" != experiments/* ]]; then \
		echo "test-ghc requiere una ruta repo-relativa bajo experiments/: $$input_file"; \
		exit 1; \
	fi; \
	if [[ "$$input_file" != */main.hs ]]; then \
		echo "test-ghc requiere un archivo main.hs: $$input_file"; \
		exit 1; \
	fi; \
	project_dir="$${input_file%/main.hs}"; \
	output_dir="tests/$${project_dir#experiments/}"; \
	$(MAKE) --no-print-directory semantic-validation-reorder-ghc "$$input_file" "$$output_dir"

test-cabal: ## Wrapper Cabal: make test-cabal <experiments/.../project-dir>
	@project_dir="$(word 2,$(MAKECMDGOALS))"; \
	extra_arg="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$project_dir" ] || [ -n "$$extra_arg" ]; then \
		echo "Uso: make test-cabal <experiments/.../project-dir>"; \
		exit 1; \
	fi; \
	project_dir="$${project_dir%/}"; \
	if [[ "$$project_dir" != experiments/* ]]; then \
		echo "test-cabal requiere una ruta repo-relativa bajo experiments/: $$project_dir"; \
		exit 1; \
	fi; \
	output_dir="tests/$${project_dir#experiments/}"; \
	$(MAKE) --no-print-directory semantic-validation-reorder-cabal "$$project_dir" "$$output_dir"

reproduce: verify-toolchain setup-ghc-build patches build test ## Ejecuta el flujo reproducible completo
	
restart-ghc: ## Reinicia el submodulo de GHC al commit objetivo
	@git -C vendor/ghc reset --hard
	@git -C vendor/ghc clean -ffd
	@git -C vendor/ghc switch --detach 0b36e96cb93db71f201aaa055c4a90b75a8110ef

ghc-quick: ## Compilar y buildear GHC modificado
	cd /workspaces/tt-repo/vendor/ghc && \
	./hadrian/build -j --flavour=quick stage2:exe:ghc-bin 

cabal-project: ## Crea proyecto cabal Maybe: make cabal-project <project-dir>
	@project_dir="$(word 2,$(MAKECMDGOALS))"; \
	if [ -z "$$project_dir" ]; then \
		echo "Uso: make cabal-project <project-dir>"; \
		exit 1; \
	fi; \
	bash scripts/cabal/create-project.sh "$$project_dir"

cabal-prob-project: ## Crea proyecto cabal probabilistico: make cabal-prob-project <project-dir>
	@project_dir="$(word 2,$(MAKECMDGOALS))"; \
	if [ -z "$$project_dir" ]; then \
		echo "Uso: make cabal-prob-project <project-dir>"; \
		exit 1; \
	fi; \
	bash scripts/cabal/create-prob-project.sh "$$project_dir"

cabal-renamer-logs: ## Crea logs con el arbol de Statements: make cabal-renamer-logs <project-dir> <output-log-file> [candidate-n]
	@cabal_dir="$(word 2,$(MAKECMDGOALS))"; \
	log_file="$(word 3,$(MAKECMDGOALS))"; \
	candidate_n="$(word 4,$(MAKECMDGOALS))"; \
	if [ -z "$$cabal_dir" ] || [ -z "$$log_file" ]; then \
		echo "Uso: make cabal-renamer-logs <directorio-cabal> <archivo-log> [candidate-n]"; \
		exit 1; \
	fi; \
	if [ -n "$$candidate_n" ] && [[ ! "$$candidate_n" =~ ^[0-9]+$$ ]]; then \
		echo "candidate-n debe ser un entero no negativo: $$candidate_n"; \
		echo "Uso: make cabal-renamer-logs <directorio-cabal> <archivo-log> [candidate-n]"; \
		exit 1; \
	fi; \
	candidate_ghc_options=""; \
	if [ -n "$$candidate_n" ]; then \
		candidate_ghc_options="--ghc-options=-fado-reorder-candidate-n=$$candidate_n"; \
	fi; \
	cd "$$cabal_dir" && \
	mkdir -p "$$(dirname "$$log_file")" && \
	grep -Pzo '(?s)=\s*(?:CD\.)?do\b.*?\n\s*(?:CD\.)?return\b[^\n]*' main.hs \
	  | tr '\0' '\n' \
	  | tee "$$log_file" && \
	printf '\n' >> "$$log_file" && \
	cabal clean && \
	cabal build $$candidate_ghc_options 2>&1 \
		  | awk '/^rearrangeForADo-commutative-do/ {capture=1} capture {print} capture && /^[[:space:]]*minimum-cost permutations[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*$$/ {capture=0}' \
	  | tee -a "$$log_file"

ghc-raw-logs: ## Crea logs con la salida completa de GHC: make ghc-raw-logs <input-file> <output-log-file> [candidate-n]
	@input_file="$(word 2,$(MAKECMDGOALS))"; \
	log_file="$(word 3,$(MAKECMDGOALS))"; \
	candidate_n="$(word 4,$(MAKECMDGOALS))"; \
	if [ -z "$$input_file" ] || [ -z "$$log_file" ]; then \
		echo "Uso: make ghc-raw-logs <archivo-hs> <archivo-log> [candidate-n]"; \
		exit 1; \
	fi; \
	if [ -n "$$candidate_n" ] && [[ ! "$$candidate_n" =~ ^[0-9]+$$ ]]; then \
		echo "candidate-n debe ser un entero no negativo: $$candidate_n"; \
		echo "Uso: make ghc-raw-logs <archivo-hs> <archivo-log> [candidate-n]"; \
		exit 1; \
	fi; \
	candidate_flag=""; \
	if [ -n "$$candidate_n" ]; then \
		candidate_flag="-fado-reorder-candidate-n=$$candidate_n"; \
	fi; \
	mkdir -p "$$(dirname "$$log_file")" && \
	./vendor/ghc/_build/stage1/bin/ghc $$candidate_flag -fforce-recomp -ddump-rn-trace -fno-code "$$input_file" | tee "$$log_file"

renamer-logs: ## Crea logs con el arbol de Statements: make renamer-logs <input-file> <output-log-file> [-concat] [candidate-n]
	@input_file="$(word 2,$(MAKECMDGOALS))"; \
	log_file="$(word 3,$(MAKECMDGOALS))"; \
	arg4="$(word 4,$(MAKECMDGOALS))"; \
	arg5="$(word 5,$(MAKECMDGOALS))"; \
	mode_flag=""; \
	candidate_n=""; \
	if [ -z "$$input_file" ] || [ -z "$$log_file" ]; then \
		echo "Uso: make renamer-logs <archivo-hs> <archivo-log> [-concat] [candidate-n]"; \
		exit 1; \
	fi; \
	for arg in "$$arg4" "$$arg5"; do \
		if [ -z "$$arg" ]; then \
			continue; \
		elif [ "$$arg" = "-concat" ]; then \
			if [ -n "$$mode_flag" ]; then \
				echo "Flag opcional duplicada: $$arg"; \
				echo "Uso: make renamer-logs <archivo-hs> <archivo-log> [-concat] [candidate-n]"; \
				exit 1; \
			fi; \
			mode_flag="-concat"; \
		elif [[ "$$arg" =~ ^[0-9]+$$ ]]; then \
			if [ -n "$$candidate_n" ]; then \
				echo "candidate-n duplicado: $$arg"; \
				echo "Uso: make renamer-logs <archivo-hs> <archivo-log> [-concat] [candidate-n]"; \
				exit 1; \
			fi; \
			candidate_n="$$arg"; \
		else \
			echo "Argumento opcional no valido: $$arg"; \
			echo "Uso: make renamer-logs <archivo-hs> <archivo-log> [-concat] [candidate-n]"; \
			exit 1; \
		fi; \
	done; \
	candidate_flag=""; \
	if [ -n "$$candidate_n" ]; then \
		candidate_flag="-fado-reorder-candidate-n=$$candidate_n"; \
	fi; \
	if [ "$$mode_flag" = "-concat" ]; then \
		first_tee_opt="-a"; \
		printf '\n' | tee -a "$$log_file"; \
	else \
		first_tee_opt=""; \
	fi; \
	mkdir -p "$$(dirname "$$log_file")" && \
	grep -Pzo '(?s)=\s*(?:CD\.)?do\b.*?\n\s*(?:CD\.)?return\b[^\n]*' "$$input_file" \
	  | tr '\0' '\n' \
	  | tee $$first_tee_opt "$$log_file" && \
	printf '\n' | tee -a "$$log_file" && \
	./vendor/ghc/_build/stage1/bin/ghc $$candidate_flag -ddump-rn-trace -XApplicativeDo -fno-code "$$input_file" \
		  | awk '/^rearrangeForADo-commutative-do/ {capture=1} capture {print} capture && /^[[:space:]]*minimum-cost permutations[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*$$/ {capture=0}' \
	  | tee -a "$$log_file"

semantic-validation-reorder: ## Valida semanticamente todas las permutaciones ADo: make semantic-validation-reorder <input-file> <output-dir>
	@input_file="$(word 2,$(MAKECMDGOALS))"; \
	output_dir="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$input_file" ] || [ -z "$$output_dir" ]; then \
		echo "Uso: make semantic-validation-reorder <input-file> <output-dir>"; \
		exit 1; \
	fi; \
	bash scripts/semantic_validation_reorder.sh "$$input_file" "$$output_dir"

semantic-validation-reorder-ghc: ## Valida semanticamente permutaciones ADo con GHC directo: make semantic-validation-reorder-ghc <input-file> <output-dir>
	@input_file="$(word 2,$(MAKECMDGOALS))"; \
	output_dir="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$input_file" ] || [ -z "$$output_dir" ]; then \
		echo "Uso: make semantic-validation-reorder-ghc <input-file> <output-dir>"; \
		exit 1; \
	fi; \
	bash scripts/semantic-validation/reorder-ghc.sh "$$input_file" "$$output_dir"

semantic-validation-reorder-cabal: ## Valida semanticamente permutaciones ADo con Cabal: make semantic-validation-reorder-cabal <project-dir> <output-dir>
	@project_dir="$(word 2,$(MAKECMDGOALS))"; \
	output_dir="$(word 3,$(MAKECMDGOALS))"; \
	if [ -z "$$project_dir" ] || [ -z "$$output_dir" ]; then \
		echo "Uso: make semantic-validation-reorder-cabal <project-dir> <output-dir>"; \
		exit 1; \
	fi; \
	bash scripts/semantic-validation/reorder-cabal.sh "$$project_dir" "$$output_dir"

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
