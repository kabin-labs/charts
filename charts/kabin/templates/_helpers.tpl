{{/*
Expand the name of the chart.
*/}}
{{- define "service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "service.labels" -}}
helm.sh/chart: {{ include "service.chart" . }}
{{ include "service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- $defaultServiceAccountName := print .Release.Namespace "-default" -}}
{{- default $defaultServiceAccountName .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create env variables.
First add env vars about context (pod name, service and namespace).
Variable SERVICE_NAME has env-name suffix (e.g. '-dev, '-qa', etc) removed.
Finally create list of ordered and formatted env vars from values files.
*/}}
{{- define "service.envVars" }}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: SERVICE_NAME
  value: {{ regexReplaceAll .Values.env.serviceNameReplaceRegex .Release.Name "" }}
- name: SERVICE_NAMESPACE
  value: {{ .Release.Namespace }}
{{- range $order := .Values.env.orderedGroupsMax | add 1 | int | until -}}
{{- range $key, $val := $.Values.env.vars -}}
{{- if eq $order ($val.order | default 0 | int) }}
- name: {{ $key | quote }}
{{- if $val.value }} 
  value: {{ $val.value | quote }} 
{{- end }}
{{- if $val.valueFrom }}
  valueFrom:
{{- $val.valueFrom | toYaml | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
