#!/bin/bash
helm fetch istio/base    --destination src/helm/charts/istio-base/charts/
helm fetch istio/istiod  --destination src/helm/charts/istio-discovery/charts/
helm fetch istio/gateway --destination src/helm/charts/istio-gateway/charts/
