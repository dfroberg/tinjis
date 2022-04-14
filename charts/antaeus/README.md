# antaeus

![Version: 0.1.17](https://img.shields.io/badge/Version-0.1.17-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

Antaeus helm chart is the solution for the Pleo SRE challenge and
contains a microservice with an payment provider.
---
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
helm upgrade antaeus antaeus/antaeus \
      --install \
      --namespace payments \
      --create-namespace \
      --wait \
      --set antaeus.image.tag=latest \
      --set antaeus.ingress.enabled=true \
      --set antaeus.ingress.domain.prefix="" \
      --set antaeus.ingress.domain.base=antaeus.local \
      --set antaeus.testService.enabled=true \
      --set payment.networkPolicy.enabled=true
~~~
How to test it;
~~~
helm test antaeus --namespace payments
~~~

**Homepage:** <https://github.com/dfroberg/tinjis>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| dfroberg | <danny@froberg.org> |  |

## Source Code

* <https://github.com/dfroberg/tinjis/tree/master/antaeus>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| common | object | `{"paymentsApiToken":"TestToken"}` | Common values for all services |
| common.paymentsApiToken | string | `"TestToken"` | This is optional, will be pupulated by a random string if not defined or already present in a secret. |
| antaeus | object | `{"env":[{"name":"TZ","value":"Europe/Stockholm"}],"image":{"pullPolicy":"Always","repository":"dfroberg/pleo-antaeus","tag":"latest"},"ingress":{"annotations":{},"domain":{"base":"antaeus.local","prefix":"","suffix":""},"enabled":true,"ingressClassName":"traefik","labels":{}},"resources":{"limits":{"memory":"4096Mi"},"requests":{"memory":"4096Mi"}},"service":{"port":8000},"testService":{"enabled":true,"port":8000}}` | Values for antaeus service |
| antaeus.env | list | `[{"name":"TZ","value":"Europe/Stockholm"}]` | Environment vars to set |
| antaeus.ingress.enabled | bool | `true` | Enable ingress |
| antaeus.ingress.annotations | object | `{}` | Ingress annotations |
| antaeus.ingress.labels | object | `{}` | Ingress labels |
| antaeus.ingress.ingressClassName | string | `"traefik"` | IngressClassname |
| antaeus.ingress.domain | object | `{"base":"antaeus.local","prefix":"","suffix":""}` | Build host string |
| antaeus.service.port | int | `8000` | Port number (Defaults to 8000) |
| antaeus.testService.enabled | bool | `true` | Enable if you wish to deploy a NodePort test service |
| antaeus.testService.port | int | `8000` | Port number (Defaults to 8000) |
| antaeus.resources | object | `{"limits":{"memory":"4096Mi"},"requests":{"memory":"4096Mi"}}` | Resource limits |
| payment | object | `{"env":[{"name":"TZ","value":"Europe/Stockholm"}],"image":{"pullPolicy":"Always","repository":"dfroberg/pleo-payment","tag":"latest"},"networkPolicy":{"enabled":true},"resources":{"limits":{"memory":"64Mi"},"requests":{"memory":"64Mi"}},"service":{"port":9000}}` | Values for payment service |
| payment.env | list | `[{"name":"TZ","value":"Europe/Stockholm"}]` | Environment vars to set |
| payment.service.port | int | `9000` | Port number (Defaults to 9000) |
| payment.networkPolicy.enabled | bool | `true` | Allow communication to this service ONLY from antaeus |
| payment.resources | object | `{"limits":{"memory":"64Mi"},"requests":{"memory":"64Mi"}}` | Resource limits |

