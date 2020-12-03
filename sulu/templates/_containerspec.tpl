{{- if .Values.app.image.pullSecrets }}
imagePullSecrets:
  - name: {{ .Values.app.image.pullSecrets }}
{{- end }}
volumes:
{{- if .Values.app.phpConfig.enabled }}
  - name: php-config
    configMap:
      name: {{ .Release.Name }}-php-configmap
      items:
        - key: custom.ini
          path: custom.ini
{{- end }}
{{- if .Values.google.enabled }}
  - name: google-bucket-config
    configMap:
      name: {{ template "sulu.fullname" . }}-google-config
      items:
        - key: key.json
          path: key.json
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.app.image.repository }}:{{ .Values.app.image.tag }}"
    imagePullPolicy: {{ .Values.app.image.pullPolicy }}
    volumeMounts:
{{- if .Values.app.phpConfig.enabled }}
      - name: php-config
        mountPath: /usr/local/etc/php/conf.d
{{- end }}
{{- if .Values.google.enabled }}
      - name: google-bucket-config
        mountPath: /etc/google
{{- end }}
    env:
      - name: APP_ENV
        value: {{ .Values.app.app_env }}
      - name: APP_SECRET
        value: {{ .Values.app.secret }}
      - name: SULU_ADMIN_EMAIL
        value: {{ .Values.app.email }}
      - name: VARNISH_SERVER
        value: {{ template "sulu.varnish.fullname" . }}
      - name: REDIS_HOST
        value: {{ template "sulu.redis.fullname" . }}
      - name: REDIS_PASSWORD
        value: {{ .Values.redis.password | quote }}
{{- if .Values.mysql.enabled }}
      - name: DATABASE_URL
        value: {{ template "sulu.mysql.url" . }}
{{- end }}
{{- if .Values.google.enabled }}
      - name: GOOGLE_STORAGE_BUCKET_NAME
        value: {{ .Values.google.bucket }}
      - name: GOOGLE_STORAGE_KEY_FILE
        value: /etc/google/key.json
{{- end }}
{{- with .Values.app.env }}
{{ toYaml . | indent 6 }}
{{- end }}
