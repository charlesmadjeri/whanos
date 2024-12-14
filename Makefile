# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
WHITE  := \033[0;37m
RESET  := \033[0m

# Target help text
TARGET_MAX_CHAR_NUM=20

.PHONY: help run run-verbose run-very-verbose

## Show help
help:
	@printf '\n'
	@printf 'Usage:\n'
	@printf '  $(YELLOW)make$(RESET) $(GREEN)<target>$(RESET)\n'
	@printf '\n'
	@printf 'Targets:\n'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  $(YELLOW)%-$(TARGET_MAX_CHAR_NUM)s$(RESET) $(GREEN)%s$(RESET)\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@printf '\n'

## Run the local docker compose
run-local:
	docker compose up -d

## Build the local docker compose
run-local-build:
	docker compose build

## Stop the local docker compose
run-local-down:
	docker compose down

## Restart the local docker compose
run-local-restart:
	docker compose restart

## Reset the local docker compose
run-local-reset: run-local-down run-local-clean run-local-build run-local

## Clean the local docker compose
run-local-clean:
	docker compose down --volumes --remove-orphans

## Run the playbook to setup the server
run-ansible:
	ansible-playbook -i ansible/inventory.yml ansible/playbook.yml

## Run the playbook to setup the server in verbose mode
run-ansible-verbose:
	ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -vvv

## Run the playbook to setup the server in very verbose mode
run-ansible-very-verbose:
	ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -vvvvv
