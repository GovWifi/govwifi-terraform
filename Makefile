SHELL := /bin/bash
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
check-env:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))

govwifi-tools: #The name "tools" would be the obvious choice here, but this is a reserved word in Makefiles and will cause an error
	$(eval export DEPLOY_ENV=tools)
	$(eval export REPO=tools)
	$(eval export AWS_REGION=eu-west-2)
staging:
	$(eval export DEPLOY_ENV=staging)
	$(eval export REPO=staging)
alpaca:
	$(eval export DEPLOY_ENV=alpaca)
	$(eval export REPO=alpaca)
development:
	$(eval export DEPLOY_ENV=development)
	$(eval export REPO=development)
wifi-london:
	$(eval export DEPLOY_ENV=wifi-london)
	$(eval export REPO=latest)
	$(eval export AWS_REGION=eu-west-2)
wifi:
	$(eval export DEPLOY_ENV=wifi)
	$(eval export REPO=latest)
	$(eval export AWS_REGION=eu-west-1)

validate_task: check-env
	@for variable in ${modules}; do module_flags="$$module_flags -target=module.$$variable"; done; [ "$$module_flags" != "" ] && echo " Validate Warning: Modules have been set to '$$module_flags'"; scripts/run-terraform.sh validate ${terraform_flags} $$module_flags
validate: check-env unencrypt-secrets validate_task delete-secrets ## Run terraform validate after decrypting secrets. Must run in form make <env> validate
plan_task: check-env
	@for variable in ${modules}; do module_flags="$$module_flags -target=module.$$variable"; done; [ "$$module_flags" != "" ] && echo " Plan Warning: Modules have been set to '$$module_flags'"; scripts/run-terraform.sh plan ${terraform_flags} $$module_flags
plan: check-env unencrypt-secrets plan_task # delete-secrets ## Run terraform plan after decrypting secrets. Must run in form make <env> plan
apply_task: check-env
	@for variable in ${modules}; do module_flags="$$module_flags -target=module.$$variable"; done; [ "$$module_flags" != "" ] && echo " Apply Warning: Modules have been set to '$$module_flags'"; scripts/run-terraform.sh apply ${terraform_flags} $$module_flags
apply: check-env unencrypt-secrets apply_task delete-secrets ## Run terraform apply after decrypting secrets. Must run in form make <env> apply
.PHONY: terraform
terraform_task: check-env
terraform: check-env unencrypt-secrets
	# clean up after a job and remove the secrets, don't leave them behind
	scripts/run-terraform.sh ${terraform_cmd} || true ; $(MAKE) delete-secrets
terraform_target: check-env unencrypt-secrets
	scripts/run-terraform.sh ${terraform_cmd}; scripts/unencrypt-secrets.sh delete-secrets
destroy_task: check-env
	scripts/run-terraform.sh destroy
destroy: check-env unencrypt-secrets destroy_task delete-secrets ## Run terraform destroy after decrypting secrets. Must run in form make <env> apply
run-terraform-init: check-env
	scripts/run-terraform.sh init
init-backend: check-env unencrypt-secrets run-terraform-init delete-secrets ## Initalize the terraform backend. Use this when first working on the project to download the required state file. Must run in form make <env> init-backend
rencrypt-passwords: .private ## Rencrypt passwords after adding a new gpg id to the password store
	PASSWORD_STORE_DIR=$$(pwd)/.private/passwords pass init $$(cat .private/passwords/.gpg-id)
unencrypt-secrets: .private update-secrets
	scripts/unencrypt-secrets.sh unencrypt
delete-secrets: .private
	scripts/unencrypt-secrets.sh delete

lint: lint-terraform
format: format-terraform

.PHONY: lint-terraform
lint-terraform:
	terraform fmt -recursive -diff -check .
	find . -maxdepth 2 -name "*.tf" -printf "%h\n" | grep -v govwifi-account | uniq | xargs --verbose -i tflint {}
	find govwifi -maxdepth 2 -name "*.tf" -printf "%h\n" | uniq | xargs --verbose -i tflint {}

.PHONY: format-terraform
format-terraform:
	terraform fmt -recursive -diff .

.private:
	git clone git@github.com:GovWifi/govwifi-build.git .private

update-secrets: .private
	cd .private && git pull
