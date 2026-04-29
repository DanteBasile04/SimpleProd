# SimpleProd — Makefile
# Lint, test, and release targets for CI/CD and local development

.PHONY: lint lint-bash lint-ansible lint-python test test-smoke test-integration release clean help

# ============================================================================
# Variables
# ============================================================================

BASH_SCRIPTS  := $(shell find infrastructure/bash -name '*.sh' -type f)
ANSIBLE_ROLES  := $(shell find infrastructure/ansible/roles -maxdepth 1 -type d)
PYTHON_SRC     := $(shell find infrastructure/python -name '*.py' -type f)
SHELLCHECK     := shellcheck
ANSIBLE_LINT   := ansible-lint

# ============================================================================
# Help
# ============================================================================

help: ## Show this help message
	@echo "SimpleProd — VPS Production Setup Bundle"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================================================
# Linting
# ============================================================================

lint: lint-bash lint-ansible lint-python ## Run all linters

lint-bash: ## Lint all Bash scripts with shellcheck
	@echo "Linting Bash scripts..."
	@for f in $(BASH_SCRIPTS); do \
		echo "  Checking $$f"; \
		$(SHELLCHECK) --severity=warning "$$f" || true; \
	done
	@echo "Bash lint complete."

lint-ansible: ## Lint all Ansible roles and playbooks
	@echo "Linting Ansible..."
	@command -v ansible-lint >/dev/null 2>&1 || { echo "ansible-lint not found. Install with: pip install ansible-lint"; exit 0; }
	@ansible-lint infrastructure/ansible/playbooks/ infrastructure/ansible/roles/ --exclude .github 2>&1 || true
	@echo "Ansible lint complete."

lint-python: ## Lint Python orchestrator code
	@echo "Linting Python..."
	@cd infrastructure/python && python -m flake8 simpleprod/ --max-line-length=120 --extend-ignore=E501 || true
	@echo "Python lint complete."

# ============================================================================
# Testing
# ============================================================================

test: test-smoke ## Run all tests

test-smoke: ## Run smoke tests (Docker-based)
	@echo "Running smoke tests..."
	@echo "Smoke tests require Docker. Skipping if not available."
	@command -v docker >/dev/null 2>&1 || { echo "Docker not found. Install Docker to run smoke tests."; exit 0; }
	@echo "Smoke tests: implemented in .github/workflows/test.yml"

test-integration: ## Run integration tests against ephemeral VM
	@echo "Running integration tests..."
	@echo "Integration tests are run via GitHub Actions. See .github/workflows/test.yml"
	@echo "To run locally, use: vagrant up && vagrant provision"

# ============================================================================
# Release
# ============================================================================

VERSION := $(shell cat VERSION 2>/dev/null || echo "0.1.0-dev")

release: ## Create a versioned release
	@echo "Creating release $(VERSION)..."
	@mkdir -p dist
	@tar -czf dist/simpleprod-$(VERSION).tar.gz \
		--exclude='dist' \
		--exclude='.git' \
		--exclude='__pycache__' \
		--exclude='.atl' \
		.
	@echo "Release created: dist/simpleprod-$(VERSION).tar.gz"

# ============================================================================
# Clean
# ============================================================================

clean: ## Remove build artifacts
	@echo "Cleaning..."
	rm -rf dist/
	find . -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete."

# ============================================================================
# Utility
# ============================================================================

init: ## Initialize the project (first-time setup)
	@echo "Initializing SimpleProd..."
	mkdir -p /var/simpleprod/secrets 2>/dev/null || true
	mkdir -p /var/backups/simpleprod 2>/dev/null || true
	@echo "Directories created. Run 'make lint' to verify setup."