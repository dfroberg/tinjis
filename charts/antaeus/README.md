# antaeus

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

Antaeus helm chart is the solution for the Pleo SRE challenge and
contains a microservice with an payment provider.

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
| common | object | `{}` |  |
| antaeus.namespace | string | `"payments"` |  |
| antaeus.image.repository | string | `"dfroberg/pleo-antaeus"` |  |
| antaeus.image.tag | string | `"latest"` |  |
| antaeus.image.pullPolicy | string | `"Always"` |  |
| antaeus.env.TZ | string | `"Europe/Stockholm"` |  |
| antaeus.ingress.enabled | bool | `true` |  |
| antaeus.ingress.annotations | object | `{}` |  |
| antaeus.ingress.labels | object | `{}` |  |
| antaeus.ingress.ingressClassName | string | `"traefik"` |  |
| antaeus.ingress.host | string | `"antaeus.local"` |  |
| antaeus.testservice.enabled | bool | `true` |  |
| antaeus.resources.limits.memory | string | `"4096Mi"` |  |
| antaeus.resources.requests.cpu | string | `"1024m"` |  |
| antaeus.resources.requests.memory | string | `"4096Mi"` |  |
| payment.image.repository | string | `"dfroberg/pleo-payment"` |  |
| payment.image.tag | string | `"latest"` |  |
| payment.image.pullPolicy | string | `"Always"` |  |
| payment.env.TZ | string | `"Europe/Stockholm"` |  |
| payment.networkPolicy.enabled | bool | `true` |  |
| payment.resources.limits.memory | string | `"64Mi"` |  |
| payment.resources.limits.cpu | string | `"250m"` |  |

