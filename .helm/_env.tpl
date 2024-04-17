{{- define "go_app_env" }}
- name: REDIS_ADDR
  value: {{ pluck .Values.global.env .Values.go_app.redis_adr | first }}
{{- end }}

{{- define "redis_env" }}
- name: REDIS_PORT
  value: {{ pluck .Values.global.env .Values.redis.redis_port | first }}
{{- end }}