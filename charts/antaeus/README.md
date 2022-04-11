# antaeus

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

Antaeus helm chart is an SRE challenge microservice.

## Get Repo Info

```
# Install this Chart.
helm repo add antaeus https://dfroberg.github.io/tinjs/charts/antaeus
helm repo update
```

## Installing the Chart


```
# Create namespace for antaeus
kubectl create ns payments
# Install helm chart with proper values.yaml config
helm install antaeus dfroberg/antaeus -f antaeus-values.yaml -n payments
```

## Uninstalling the Chart

```
helm delete antaeus -n payments
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| antaeus.image.repository | string | `"dfroberg/pleo-antaeus"` | docker image repository name |
| antaeus.image.pullPolicy | string | `"IfNotPresent"` | pullPolicy |
| antaeus.image.tag | string | `""` | docker image tag |
| payment.image.repository | string | `"dfroberg/pleo-payment"` | docker image repository name |
| payment.image.pullPolicy | string | `"IfNotPresent"` | pullPolicy |
| payment.image.tag | string | `""` | docker image tag |

