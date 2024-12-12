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

## Run the playbook to setup the server
run:
	ansible-playbook -i ansible/inventory.yml ansible/playbook.yml

## Run the playbook to setup the server in verbose mode
run-verbose:
	ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -vvv

## Run the playbook to setup the server in very verbose mode
run-very-verbose:
	ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -vvvvv
