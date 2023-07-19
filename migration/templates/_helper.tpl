## Unique value use for ease housekeeping
{{- define "migration.housekeeping" -}}
  {{- if not (index .Release "tmp_vars") -}}
    {{- $_ := set .Release "tmp_vars" dict -}}
  {{- end -}}

  {{- if not (index .Release.tmp_vars "housekeeping") -}}
    {{- $_ := set .Release.tmp_vars "housekeeping" (randAlphaNum 20) -}}
  {{- end -}}
  
  {{- index .Release.tmp_vars "housekeeping" -}}
{{- end -}}