# antaeus

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

Antaeus helm chart is the solution for the Pleo SRE challenge and
contains a microservice with an payment provider.

How to get it;
~~~
helm repo add antaeus https://dfroberg.github.io/tinjis/
helm repo update
~~~
Take a look;
~~~
helm search repo antaeus
~~~
How to install it;
~~~
helm install
~~~

**Homepage:** <https://github.com/dfroberg/tinjis>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| dfroberg | <danny@froberg.org> |  |

## Source Code

* <https://github.com/dfroberg/tinjis/charts/antaeus>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| common.paymentsApiToken | string | `"TestToken"` |  |
| antaeus.namespace | string | `"payments"` | The namespace to deploy all charts into |
| antaeus.image.repository | string | `"dfroberg/pleo-antaeus"` |  |
| antaeus.image.tag | string | `"latest"` |  |
| antaeus.image.pullPolicy | string | `"Always"` |  |
| antaeus.env | object | `{"TZ":"Europe/Stockholm"}` | Environment vars to set |
| antaeus.ingress.enabled | bool | `true` |  |
| antaeus.ingress.annotations | object | `{}` |  |
| antaeus.ingress.labels | object | `{}` |  |
| antaeus.ingress.ingressClassName | string | `"traefik"` |  |
| antaeus.ingress.domain.base | string | `"antaeus.local"` |  |
| antaeus.ingress.domain.prefix | string | `""` |  |
| antaeus.ingress.domain.suffix | string | `""` |  |
| antaeus.testservice | object | `{"enabled":true}` | Enable if you wish to deploy a NodePort test service |
| antaeus.resources | object | `{"limits":{"memory":"4096Mi"},"requests":{"cpu":"1024m","memory":"4096Mi"}}` | Resource limits |
| payment.image.repository | string | `"dfroberg/pleo-payment"` |  |
| payment.image.tag | string | `"latest"` |  |
| payment.image.pullPolicy | string | `"Always"` |  |
| payment.env | object | `{"TZ":"Europe/Stockholm"}` | Environment vars to set |
| payment.networkPolicy | object | `{"enabled":true}` | Allow communication to this service ONLY from antaeus |
| payment.resources | object | `{"limits":{"cpu":"250m","memory":"64Mi"}}` | Resource limits |

