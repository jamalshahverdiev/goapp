{{- define "go_app_env" }}
- name: REDIS_ADDR
  value: {{ .Values.go_app.redis_adr }}
{{- end }}

{{- define "redis_env" }}
- name: REDIS_PORT
  value: {{ quote .Values.redis.redis_port }}
{{- end }}