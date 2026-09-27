{{/*
Chart name.
*/}}
{{- define "user-mgmt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name — release + chart name.
*/}}
{{- define "user-mgmt.fullname" -}}
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
Chart identifier (used in labels).
*/}}
{{- define "user-mgmt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Base selector labels shared by all components.
*/}}
{{- define "user-mgmt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "user-mgmt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "user-mgmt.labels" -}}
helm.sh/chart: {{ include "user-mgmt.chart" . }}
{{ include "user-mgmt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Per-component names.
*/}}
{{- define "user-mgmt.backend.name" -}}
{{- printf "%s-backend" (include "user-mgmt.fullname" .) }}
{{- end }}

{{- define "user-mgmt.frontend.name" -}}
{{- printf "%s-frontend" (include "user-mgmt.fullname" .) }}
{{- end }}

{{/*
Secret name that holds the Managed PostgreSQL credentials (Aufgabe 4).
*/}}
{{- define "user-mgmt.backend.dbSecretName" -}}
{{- printf "%s-db" (include "user-mgmt.backend.name" .) }}
{{- end }}

{{/*
Per-component selector labels (extend base with component tag).
*/}}
{{- define "user-mgmt.backend.selectorLabels" -}}
{{ include "user-mgmt.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{- define "user-mgmt.frontend.selectorLabels" -}}
{{ include "user-mgmt.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Per-component full labels.
*/}}
{{- define "user-mgmt.backend.labels" -}}
{{ include "user-mgmt.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{- define "user-mgmt.frontend.labels" -}}
{{ include "user-mgmt.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
JDBC URL for the DigitalOcean Managed PostgreSQL cluster (Aufgabe 4).
sslmode=require is mandatory on DO managed databases.
*/}}
{{- define "user-mgmt.backend.jdbcUrl" -}}
{{- $db := .Values.backend.database -}}
{{- printf "jdbc:postgresql://%s:%d/%s?sslmode=%s" $db.host (int $db.port) $db.name $db.sslMode }}
{{- end }}
