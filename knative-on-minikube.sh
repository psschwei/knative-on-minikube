#! /usr/bin/env bash

set -eo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-minikube}
K8S_VERSION=${K8S_VERSION:-1.20.0}
KNATIVE_VERSION=${KNATIVE_VERSION:-0.23.0}
VM_DRIVER=${VM_DRIVER:-kvm2}
MINIKUBE_MEM=${MINIKUBE_MEM:-4096}
MINIKUBE_CPU=${MINIKUBE_CPU:-2}


# Start MiniKube
echo -e "Starting minikube..."
STARTTIME=$(date +%s)
minikube start --profile="${CLUSTER_NAME}" --memory="${MINIKUBE_MEM}" --cpus="${MINIKUBE_CPU}" --kubernetes-version=v"${K8S_VERSION}" --vm-driver "${VM_DRIVER}"

# KNATIVE SERVING
echo -e "Installing Knative Serving..."
# Serving components
kubectl apply -f https://github.com/knative/serving/releases/download/v"${KNATIVE_VERSION}"/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/v"${KNATIVE_VERSION}"/serving-core.yaml

# Networking layer
kubectl apply -f https://github.com/knative/net-kourier/releases/download/v"${KNATIVE_VERSION}"/kourier.yaml
kubectl patch configmap/config-network -n knative-serving --type merge -p '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'

# Configure DNS
kubectl apply -f https://github.com/knative/serving/releases/download/v"${KNATIVE_VERSION}"/serving-default-domain.yaml
minikube tunnel >/dev/null 2>&1 &

# KNATIVE EVENTING
echo -e "Installing Knative Eventing..."
# Eventing components
kubectl apply -f https://github.com/knative/eventing/releases/download/v"${KNATIVE_VERSION}"/eventing-crds.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/v"${KNATIVE_VERSION}"/eventing-core.yaml

# Default channel layer
kubectl apply -f https://github.com/knative/eventing/releases/download/v"${KNATIVE_VERSION}"/in-memory-channel.yaml

# MT-channel-based broker
kubectl apply -f https://github.com/knative/eventing/releases/download/v"${KNATIVE_VERSION}"/mt-channel-broker.yaml

DURATION=$(($(date +%s) - $STARTTIME))
echo -e "Knative install took $(($DURATION / 60))m$(($DURATION % 60))s"
echo -e "Now have some fun with Serverless and Event Driven Apps!"
