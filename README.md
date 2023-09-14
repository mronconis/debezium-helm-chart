# Debezium helm chart

## Create kind cluster

```bash
kind create cluster --config demo/kind.yaml
```

### Install strimzi operator

```bash
kubectl --context kind-debezium-k8s-cluster create namespace kafka
```

```bash
kubectl --context kind-debezium-k8s-cluster create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
```

### Create kafka cluster

```bash
kubectl apply -f demo/kafka.yaml -n kafka
```

### Install mongodb operator

```bash
kubectl --context kind-debezium-k8s-cluster create namespace mongodb
```

```bash
helm repo add mongodb https://mongodb.github.io/helm-charts
```

```bash
helm install community-operator mongodb/community-operator --namespace mongodb --set operator.watchNamespace="mongodb"
```

### Create mongodb cluster

```bash
kubectl apply -f demo/mongodb.yaml
```

### Init mongodb database

Get connection string
```bash
kubectl get secret -n mongodb mongodb-admin-admin -o json | jq '.data.["connectionString.standardSrv"] | @base64d')
```

Login cli
```bash
kubectl exec -it mongodb-0 -n mongodb -c mongod -- bash -c "mongosh 'mongodb+srv://admin:admin123@mongodb-svc.mongodb.svc.cluster.local/admin?replicaSet=mongodb&ssl=false'"
```

Init db
```bash
# TODO
```

## Install debezium cdc

```bash
helm install -n kafka --values demo/values.yaml debezium-cdc .
```

## Uninstall debezium cdc

```bash
helm uninstall -n kafka debezium-cdc
```

## Cleanup

```bash
kind delete cluster --name debezium-k8s-cluster
```