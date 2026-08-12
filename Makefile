# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
WHITE  := \033[0;37m
RESET  := \033[0m

# Target help text
TARGET_MAX_CHAR_NUM=20

.PHONY: help run-local run-local-build run-local-down run-local-restart run-local-reset run-local-clean \
	run-ansible run-ansible-verbose run-ansible-very-verbose \
	ci-detection ci-k8s ci-base-images \
	terraform-init terraform-plan terraform-up terraform-down infra

ENV ?= dev
TF_DIR := terraform/envs/$(ENV)
# Shell-source .env (Make `include` treats # in values as comments).
DOTENV := ./scripts/with-dotenv

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
	$(DOTENV) env ANSIBLE_CONFIG=ansible/ansible.cfg \
	  ansible-playbook -i ansible/inventory.yml ansible/playbook.yml

## Run the playbook to setup the server in verbose mode
run-ansible-verbose:
	$(DOTENV) env ANSIBLE_CONFIG=ansible/ansible.cfg \
	  ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -vvv

## Run the playbook to setup the server in very verbose mode
run-ansible-very-verbose:
	$(DOTENV) env ANSIBLE_CONFIG=ansible/ansible.cfg \
	  ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -vvvvv

## CI checks that do not need cloud credentials
ci-detection:
	chmod +x scripts/ci/test-detection.sh jenkins/scripts/*.sh
	./scripts/ci/test-detection.sh

## CI: apply_k8s manifest generation with mocked kubectl
ci-k8s:
	chmod +x scripts/ci/test-apply-k8s.sh jenkins/scripts/apply_k8s.sh
	./scripts/ci/test-apply-k8s.sh

## CI: build all language base images locally
ci-base-images:
	@for lang in c java javascript python befunge; do \
		echo "==> building whanos-$$lang"; \
		docker build -t "whanos-$$lang" - < "images/$$lang/Dockerfile.base"; \
	done

## Terraform init for ENV=dev|prod
terraform-init:
	@$(DOTENV) bash -c 'test -n "$$DIGITALOCEAN_TOKEN" -o -n "$$DIGITALOCEAN_ACCESS_TOKEN" || \
	  (echo "Missing DIGITALOCEAN_TOKEN. Copy .env.example → .env and set the token."; exit 1)'
	$(DOTENV) bash -c 'cd "$(TF_DIR)" && terraform init'

## Terraform plan for ENV=dev|prod
terraform-plan: terraform-init
	$(DOTENV) bash -c 'cd "$(TF_DIR)" && terraform plan'

## Provision registry + DOKS + Jenkins VPS (ENV=dev|prod)
terraform-up: terraform-init
	$(DOTENV) bash -c 'cd "$(TF_DIR)" && terraform apply -auto-approve'
	@$(DOTENV) bash -c 'CLUSTER_ID=$$(cd "$(TF_DIR)" && terraform output -raw cluster_id); \
	  echo "Integrating DOCR with DOKS $$CLUSTER_ID..."; \
	  doctl registry kubernetes-integration create --cluster-uuid "$$CLUSTER_ID" || \
	  doctl registry kubernetes-integration create "$$CLUSTER_ID" || \
	  echo "WARN: run DOCR↔DOKS integration manually if the command failed"'
	@echo "Next: merge ansible/group_vars/tf.generated.yml into all.yml (IP/volumes), then make run-ansible"
	@$(DOTENV) bash -c 'cd "$(TF_DIR)" && terraform output next_steps'

## Destroy Terraform stack for ENV=dev|prod
terraform-down:
	@$(DOTENV) bash -c 'test -n "$$DIGITALOCEAN_TOKEN" -o -n "$$DIGITALOCEAN_ACCESS_TOKEN" || \
	  (echo "Missing DIGITALOCEAN_TOKEN. Copy .env.example → .env and set the token."; exit 1)'
	$(DOTENV) bash -c 'cd "$(TF_DIR)" && terraform destroy -auto-approve'

## Provision cloud infra then remind Ansible handoff
infra: terraform-up
	@echo "Infra up. Secrets stay in .env; merge tf.generated.yml into all.yml, then: make run-ansible"
