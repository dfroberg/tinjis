{{/*
Generate paymentsApiToken if not specified in values
*/}}
{{ define "common.payments-api-token" }}
{{- if .Values.common.paymentsApiToken }}
  {{- .Values.common.paymentsApiToken -}}
{{- else if (lookup "v1" "Secret" .Release.Namespace "common-payments-secret").data }}
  {{- $obj := (lookup "v1" "Secret" .Release.Namespace "common-payments-secret").data -}}
  {{- index $obj "PAYMENTS_API_TOKEN" | b64dec -}}
{{- else -}}
  {{- randAlphaNum 48 -}}
{{- end -}}
{{- end -}}
{{/*
Generate ingress hostname if not specified in values
*/}}
{{- define "ingress.hostName" -}}
{{- .Values.antaeus.ingress.domain.prefix }}{{ if ne .Values.antaeus.ingress.domain.prefix "" }}.{{ end }}{{- .Values.antaeus.ingress.domain.base }}{{- .Values.antaeus.ingress.domain.suffix }}
{{- end }}
