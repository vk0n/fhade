{{- define "fleetdm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "fleetdm.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "fleetdm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "fleetdm.labels" -}}
helm.sh/chart: {{ include "fleetdm.chart" . }}
app.kubernetes.io/name: {{ include "fleetdm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "fleetdm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fleetdm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "fleetdm.mysqlServiceName" -}}
{{- printf "%s-mysql" (include "fleetdm.fullname" .) -}}
{{- end -}}

{{- define "fleetdm.redisServiceName" -}}
{{- printf "%s-redis" (include "fleetdm.fullname" .) -}}
{{- end -}}
