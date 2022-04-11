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
