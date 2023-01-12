.PHONY: default help prepare build lint test package watch deploy clean start

SRC_DIR := $(shell pwd)
STAMPS_DIR := $(SRC_DIR)/.stamps

CODE_DIR := $(SRC_DIR)/code

APP_NAME := $(shell cd $(CODE_DIR) && ./gradlew appName -q)

SANDBOX_DIR := ~/.enonic/sandboxes/$(APP_NAME)
SANDBOX_VERSION := $(shell cd $(CODE_DIR) && ./gradlew enonicVersion -q)

GIT_HOOKS_DIR := $(SRC_DIR)/scripts/hooks
GIT_HOOKS_SOURCES := $(shell find $(GIT_HOOKS_DIR))

DIST_DIR := $(CODE_DIR)/build/libs


default: package ## Default target when running make without specifying a target, runs package

help: ## Print this text
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

prepare: $(STAMPS_DIR)/prepare.stamp ## Install external tools and validate environment
$(STAMPS_DIR)/prepare.stamp: Makefile .git/hooks | $(STAMPS_DIR)
	## Check that git, gradle, java, node, enonic cli, etc --> sdkman
	## Install git hooks
	$(call check_external,git)
	$(call check_external,gradle)
	$(call check_external,java)
	$(call check_external,node)
	$(call check_external,enonic)
	@touch $@

install_new_dependencies:
	@cd $(CODE_DIR) && ./gradlew npm_install

build: $(STAMPS_DIR)/prepare.stamp ## Optional build step, needed by compiled or transpiled languages
	# RUNNING Build
	@cd $(CODE_DIR) && ./gradlew npmBuild

package: $(STAMPS_DIR)/prepare.stamp ## Create a deployment package
	# RUNNING Packaging
	@cd $(CODE_DIR) && ./gradlew packageApplication

deploy: $(STAMPS_DIR)/prepare.stamp ## Deploy deployment package to a runtime environment
	# RUNNING Deploy
	@cd $(CODE_DIR) && enonic project deploy $(APP_NAME)

server: $(SANDBOX_DIR) ## Set up development server. Create new sandbox if necessary
$(SANDBOX_DIR):
	# RUNNING Creating server
	@echo "Sandbox does not exist, creating sandbox $(APP_NAME)."
	@enonic sandbox create $(APP_NAME) -v $(SANDBOX_VERSION) -f
	@cd $(CODE_DIR) && enonic project sandbox $(APP_NAME)

start: $(SANDBOX_DIR) ## Start the server
	# RUNNING Starting sandbox
	@enonic sandbox start $(APP_NAME) --dev

clean: ## Delete generated files
	# RUNNING Cleaning up
	@cd $(CODE_DIR) && ./gradlew clean
	-rm -rf $(STAMPS_DIR)
	-rm -rf $(CODE_DIR)/node_modules
	-rm -rf $(CODE_DIR)/build/private-libs

$(STAMPS_DIR):
	@mkdir -p $@

$(DIST_DIR):
	@mkdir -p $@

git-hooks: .git/hooks ## Installs the git-hooks
.git/hooks: $(GIT_HOOKS_SOURCES)
	rsync -avu --delete "$(GIT_HOOKS_DIR)/" "$@"
	chmod +x $@/*
	@touch $@

define check_external
	@if ! command -v $(1) >/dev/null 2>&1; then \
		echo "You have to install $(1)"; \
		exit 1; \
	fi
endef
