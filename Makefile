.PHONY: all
all: projects/mirrors projects/repo-dockerfiles projects/forks ## Run all the generation scripts.

.PHONY: projects/mirrors
projects/mirrors: generate-mirrors.sh ## Generate DSLs for git mirrors.
	@echo "+ $@"
	./$< | column -t

.PHONY: projects/repo-dockerfiles
projects/repo-dockerfiles: generate-repo-dockerfiles.sh ## Generate DSLs for repos with Dockerfiles.
	@echo "+ $@"
	./$< | column -t

.PHONY: projects/forks
projects/forks: generate-update-forks.sh ## Generate DSLs to update git forks.
	@echo "+ $@"
	./$< | column -t

check_defined = \
				$(strip $(foreach 1,$1, \
				$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
				  $(if $(value $1),, \
				  $(error Undefined $1$(if $2, ($2))$(if $(value @), \
				  required by target `$@')))

.PHONY: deploy-key
deploy-key: ## Create a deploy key for a given repo (ex. REPO=jessfraz/jenkins-dsl).
	@:$(call check_defined, REPO, name of the repository)
	@$(CURDIR)/create-deploy-key.sh "$(REPO)"

.PHONY: webhook-jenkins-create
webhook-jenkins-create: ## Create the jenkins webhook for a given repo (ex. REPO=jessfraz/jenkins-dsl).
	@:$(call check_defined, REPO, name of the repository)
	@$(CURDIR)/create-jenkins-webhook.sh "$(REPO)"

GITHUB_API_URI:=https://api.github.com
GITHUB_API_VERSION:=v3
GITHUB_API_HEADER:=Accept: application/vnd.github.$(GITHUB_API_VERSION)+json
GITHUB_AUTH_HEADER:=Authorization: token ${GITHUB_TOKEN}

.PHONY: webhook-jenkins-get
webhook-jenkins-get: ## Get the jenkins webhook for a given repo (ex. REPO=jessfraz/jenkins-dsl).
	@:$(call check_defined, REPO, name of the repository)
	@curl -sSL \
		-H "$(GITHUB_AUTH_HEADER)" \
		-H "$(GITHUB_API_HEADER)" \
		"$(GITHUB_API_URI)/repos/$(REPO)/hooks" | jq '.[] | select(.name=="web")'

.PHONY: webhook-travis-get
webhook-travis-get: ## Get a travis webhook for a given repo (ex. REPO=jessfraz/jenkins-dsl).
	@:$(call check_defined, REPO, name of the repository)
	@curl -sSL \
		-H "$(GITHUB_AUTH_HEADER)" \
		-H "$(GITHUB_API_HEADER)" \
		"$(GITHUB_API_URI)/repos/$(REPO)/hooks" | jq '.[] | select(.name=="travis")'

.PHONY: test
test: shellcheck ## Runs all the tests on the files in the repository.

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: shellcheck
shellcheck: ## Runs the shellcheck tests on the scripts.
	docker run --rm -i $(DOCKER_FLAGS) \
		--name df-shellcheck \
		-v $(CURDIR):/usr/src:ro \
		--workdir /usr/src \
		r.j3ss.co/shellcheck ./test.sh

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
