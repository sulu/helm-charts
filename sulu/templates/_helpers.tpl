{{/* vim: set filetype=mustache: */}}
{{/* Expand the name of the chart. */}}
{{/* Fallback to hard coded name if the container spec is used there is no ".Chart" variable. */}}
{{- define "sulu.name" -}}
    {{- if .Values.nameOverride -}}
        {{- .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
         {{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
{{- end -}}

{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
    If release name contains chart name it will be used as a full name.
*/}}
{{- define "sulu.fullname" -}}
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

{{- define "sulu.taskrunner.fullname" -}}
    {{- printf "%s-%s" .Release.Name "taskrunner" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "sulu.chart" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sulu.mysql.fullname" -}}
    {{- printf "%s-%s" .Release.Name "mysql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sulu.mysql.url" -}}
    {{- printf "mysql://%s:%s@%s:3306/%s" (.Values.mysql.mysqlUser) (.Values.mysql.mysqlPassword) (printf "%s-%s" .Release.Name "mysql" | trunc 63 | trimSuffix "-") (.Values.mysql.mysqlDatabase) -}}
{{- end -}}

{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sulu.redis.fullname" -}}
    {{- printf "%s-%s" .Release.Name "redis-master" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sulu.redis.dsn" -}}
    {{- printf "redis://%s@%s:6379" .Values.redis.password (include "sulu.redis.fullname" .) -}}
{{- end -}}

{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sulu.varnish.fullname" -}}
    {{- printf "%s-%s" .Release.Name "varnish" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sulu.mediaproxy.fullname" -}}
    {{- printf "%s-%s" .Release.Name "mediaproxy" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Following template creates the pull secrets for images.
*/}}
{{- define "sulu.image_pull_secrets" }}
    {{- printf "{\"auths\":{\"%s\":{\"Username\":\"%s\",\"Password\":\"%s\",\"Email\":\"%s\"}}}" .Values.app.image.pullSecrets.registry .Values.app.image.pullSecrets.username .Values.app.image.pullSecrets.password .Values.app.image.pullSecrets.email | b64enc }}
{{- end }}
{{- define "sulu.image_pull_secrets.name" -}}
    {{- printf "%s-%s" .Release.Name "image-pull-secrets" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
