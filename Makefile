SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: help verify-toolchain add-submodule init-submodule init-submodule-recursive verify-submodule setup-ghc-submodule setup-ghc-build patches build test reproduce

help: ## Muestra esta ayuda y los comandos disponibles
	@echo "Uso: make <comando>"
	@echo ""
	@echo "Comandos disponibles:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

verify-toolchain: ## Verifica que la toolchain del contenedor este disponible
	bash .devcontainer/verify_dev_toolchain.sh

add-submodule: ## Agrega o reutiliza vendor/ghc y lo fija al commit objetivo
	bash scripts/setup-ghc/add_ghc_submodule.sh

init-submodule: ## Inicializa y actualiza submodulos de primer nivel
	bash scripts/setup-ghc/init_submodules.sh

init-submodule-recursive: ## Inicializa submodulos anidados de GHC (para ./boot)
	INIT_GHC_NESTED_SUBMODULES=1 bash scripts/setup-ghc/init_submodules.sh

verify-submodule: ## Verifica que vendor/ghc este en el commit esperado
	bash scripts/setup-ghc/verify_ghc_commit.sh

setup-ghc-build: add-submodule init-submodule-recursive verify-submodule ## Prepara vendor/ghc para compilar GHC (incluye anidados)

patches: ## Aplica parches desde patches/*.patch
	bash scripts/apply_patches.sh

build: ## Ejecuta el proceso de build
	bash scripts/build.sh

test: ## Ejecuta pruebas y validaciones
	bash scripts/test.sh

reproduce: verify-toolchain setup-ghc-submodule patches build test ## Ejecuta el flujo reproducible completo

shell: ## Abre la shell del dev continer
	docker exec -it ghc-dev-container bash