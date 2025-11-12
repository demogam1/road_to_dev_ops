# ========= Config =========
PKG ?= npm                       # npm (défaut) | pnpm | yarn
RUN  = $(PKG) run
BUILD_DIR ?= build               # SvelteKit: "build", Vite: "dist"
# ==========================

.PHONY: help install dev build preview lint fmt test check clean clean-all

help: ## Affiche cette aide
	@printf "Cibles disponibles :\n"; \
	awk -F':.*##' '/^[a-zA-Z0-9_.-]+:.*##/ { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Installe les dépendances
	@$(PKG) ci || $(PKG) install

docker-dev: ## Lance le serveur de dev dans docker
	docker run --rm -p 5173:5173 -v "./:/app" -v /app/node_modules -e CHOKIDAR_USEPOLLING=1 -it --entrypoint sh f9a85fc420f2 -c "npm run dev"

build: ## Build de production
	@$(RUN) build

preview: ## Prévisualise le build (SvelteKit/Vite)
	@$(RUN) preview

lint: ## Lint du code
	@$(RUN) lint || true

fmt: ## Formatage du code
	@$(RUN) format || $(RUN) fmt || true

test: ## Lance les tests
	@$(RUN) test || true

check: ## Type-check (TS/SvelteKit)
	@$(RUN) check || $(RUN) typecheck || true

clean: ## Nettoie les artefacts de build et caches
	@rm -rf $(BUILD_DIR) dist .svelte-kit node_modules/.cache

clean-all: ## Nettoie TOUT (incl. node_modules)
	@rm -rf $(BUILD_DIR) dist .svelte-kit node_modules
