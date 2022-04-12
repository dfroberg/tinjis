# antaeus

![Version: 0.1.7](https://img.shields.io/badge/Version-0.1.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

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
helm upgrade antaeus antaeus \
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
| antaeus | object | `{"env":[{"name":"TZ","value":"Europe/Stockholm"}],"image":{"pullPolicy":"Always","repository":"dfroberg/pleo-antaeus","tag":"latest"},"ingress":{"annotations":{},"domain":{"base":"antaeus.local","prefix":"","suffix":""},"enabled":true,"ingressClassName":"traefik","labels":{}},"resources":{"limits":{"memory":"4096Mi"},"requests":{"cpu":"1024m","memory":"4096Mi"}},"testService":{"enabled":true}}` | Values for antaeus service |
| antaeus.env | list | `[{"name":"TZ","value":"Europe/Stockholm"}]` | Environment vars to set |
| antaeus.testService.enabled | bool | `true` | Enable if you wish to deploy a NodePort test service |
| antaeus.resources | object | `{"limits":{"memory":"4096Mi"},"requests":{"cpu":"1024m","memory":"4096Mi"}}` | Resource limits |
| payment | object | `{"env":[{"name":"TZ","value":"Europe/Stockholm"}],"image":{"pullPolicy":"Always","repository":"dfroberg/pleo-payment","tag":"latest"},"networkPolicy":{"enabled":true},"resources":{"limits":{"cpu":"250m","memory":"64Mi"}}}` | Values for payment service |
| payment.env | list | `[{"name":"TZ","value":"Europe/Stockholm"}]` | Environment vars to set |
| payment.networkPolicy.enabled | bool | `true` | Allow communication to this service ONLY from antaeus |
| payment.resources | object | `{"limits":{"cpu":"250m","memory":"64Mi"}}` | Resource limits |

