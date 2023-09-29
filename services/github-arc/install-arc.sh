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
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set