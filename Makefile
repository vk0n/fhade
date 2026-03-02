SHELL := /bin/bash

CLUSTER_NAME ?= fleetdm-local
KIND_CONFIG ?= kind-config.yaml
NAMESPACE ?= fleetdm
RELEASE_NAME ?= fleetdm
CHART_PATH ?= charts/fleetdm
HELM ?= helm
KIND ?= kind
KUBECTL ?= kubectl

.PHONY: cluster install uninstall lint template

cluster:
	@if ! $(KIND) get clusters | grep -qx "$(CLUSTER_NAME)"; then \
		echo "Creating kind cluster $(CLUSTER_NAME)"; \
		$(KIND) create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG); \
	else \
		echo "kind cluster $(CLUSTER_NAME) already exists"; \
	fi

install:
	@$(KUBECTL) get ns $(NAMESPACE) >/dev/null 2>&1 || $(KUBECTL) create namespace $(NAMESPACE)
	$(HELM) upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--wait \
		--timeout 10m

uninstall:
	-$(HELM) uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	-$(KUBECTL) delete namespace $(NAMESPACE) --ignore-not-found=true
	@if $(KIND) get clusters | grep -qx "$(CLUSTER_NAME)"; then \
		$(KIND) delete cluster --name $(CLUSTER_NAME); \
	else \
		echo "kind cluster $(CLUSTER_NAME) not found"; \
	fi

lint:
	$(HELM) lint $(CHART_PATH)

template:
	$(HELM) template $(RELEASE_NAME) $(CHART_PATH)
