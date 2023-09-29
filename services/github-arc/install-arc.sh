#!/bin/bash
helm upgrade \
arc \
--install \
--namespace "gha-arc-controller" --create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

helm upgrade \
arc-runner-set \
--install \
--namespace "gha-arc-runner" \
--create-namespace \
--set githubConfigUrl="https://github.com/khumps-dev" \
--set githubConfigSecret=gha-arc-config \
--set minRunners=1 \
--set containerMode.type=kubernetes \
--set containerMode.kubernetesModeWorkVolumeClaim.accessModes[0]="ReadWriteOnce" \
--set containerMode.kubernetesModeWorkVolumeClaim.storageClassName=longhorn \
--set containerMode.kubernetesModeWorkVolumeClaim.resources.requests.storage=1Gi \
--set template.spec.securityContext.fsGroup=123 \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set