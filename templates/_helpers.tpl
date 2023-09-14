{{/*
Expand the name of the chart.
*/}}
{{- define "debezium-connect.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand bootstrapServers url
*/}}
{{- define "debezium-connect.bootstrapServers" -}}
{{ join "," .Values.connect.bootstrapServers | quote }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "debezium-connect.fullname" -}}
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
{{- define "debezium-connect.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "debezium-connect.labels" -}}
helm.sh/chart: {{ include "debezium-connect.chart" . }}
{{ include "debezium-connect.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $val := .Values.connect.labels }}
{{ $key }}: {{ $val | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "debezium-connect.selectorLabels" -}}
app.kubernetes.io/name: {{ include "debezium-connect.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "debezium-connect.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "debezium-connect.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create connector config
*/}}
{{- define "debezium-connect.connectorConfig" -}}
{{- $config := dict }}
{{- $secretName := "debezium-connector-db-credential" }}
{{- if .Values.resourcePrefix }}
{{- $secretName = printf "%s-debezium-connector-db-credential" .Values.resourcePrefix }}
{{- end }}
{{- $userSecret := printf "${secrets:%s/%s:username}" .Release.Namespace $secretName }}
{{- $pwdSecret := printf "${secrets:%s/%s:password}" .Release.Namespace $secretName }}
{{- if contains "MongoDbConnector" .Values.connector.class }}
{{- $config := set $config "mongodb.user" $userSecret }}
{{- $config := set $config "mongodb.password" $pwdSecret }}
{{- $config := set $config "mongodb.name" .Values.connect.configPrefix }}
{{- else }}
{{- $config := set $config "database.user" $userSecret }}
{{- $config := set $config "database.password" $pwdSecret }}
{{- if contains "OracleConnector" .Values.connector.class }}
{{- $config := set $config "schema.history.internal.kafka.bootstrap.servers" (join "," .Values.connect.bootstrapServers) }}
{{- $config := set $config "schema.history.internal.kafka.topic" (printf "%s.schema-changes" .Values.connect.configPrefix) }}
{{- if .Values.connect.authentication }}
{{- $jaasConfig := printf "org.apache.kafka.common.security.scram.ScramLoginModule required username='%s' password='${secrets:%s/%sdebezium-connect-credential:password}';" .Values.connect.authentication.username .Release.Namespace (include "debezium-connect.resourcePrefix" .) }}
{{- $config := set $config "schema.history.internal.producer.security.protocol" "SASL_SSL" }}
{{- $config := set $config "schema.history.internal.producer.ssl.truststore.type" "PEM" }}
{{- $config := set $config "schema.history.internal.producer.ssl.truststore.location" "/opt/kafka/connect-certs/debezium-connect-tls-certs/ca.crt" }}
{{- $config := set $config "schema.history.internal.producer.sasl.mechanism" "SCRAM-SHA-512" }}
{{- $config := set $config "schema.history.internal.producer.sasl.jaas.config" $jaasConfig }}
{{- $config := set $config "schema.history.internal.consumer.security.protocol" "SASL_SSL" }}
{{- $config := set $config "schema.history.internal.consumer.ssl.truststore.type" "PEM" }}
{{- $config := set $config "schema.history.internal.consumer.ssl.truststore.location" "/opt/kafka/connect-certs/debezium-connect-tls-certs/ca.crt" }}
{{- $config := set $config "schema.history.internal.consumer.sasl.mechanism" "SCRAM-SHA-512" }}
{{- $config := set $config "schema.history.internal.consumer.sasl.jaas.config" $jaasConfig }}
{{- end }}
{{- end }}
{{- end }}
{{- $config := set $config "topic.prefix" .Values.connect.configPrefix }}
{{- (mergeOverwrite $config .Values.connector.config) | toYaml  -}}
{{- end }}


{{/*
Resource prefix
*/}}
{{- define "debezium-connect.resourcePrefix" -}}
{{- if .Values.resourcePrefix -}}
{{ .Values.resourcePrefix }}-
{{- end -}}
{{- end -}}