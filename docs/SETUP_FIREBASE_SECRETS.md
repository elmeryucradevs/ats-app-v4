k# Setup Firebase Credentials in Supabase

Este script te ayuda a configurar los secrets de Firebase en Supabase.

## Paso 1: Extraer valores del Service Account JSON

Del archivo `atesur-app-v4-firebase-adminsdk-fbsvc-adc7215fc9.json`, extrae:

### FIREBASE_PROJECT_ID
```
atesur-app-v4
```

### FIREBASE_CLIENT_EMAIL
```
firebase-adminsdk-fbsvc@atesur-app-v4.iam.gserviceaccount.com
```

### FIREBASE_PRIVATE_KEY
```
-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQClkEcM3lnBljpm
TYpjroDaM3Q+syx5gLAopW/fP39V0JvXzPL9+iNIJ3pjypn5xieCJJFFWwULKjbF
FiiUSnN2An4/17i5OfzQkX4qddfrSwOQfyBRiZv2hL/ptSvDA6gImYAcNiic5Et9
4PmQ+k9RMW+VE9GdIEfYmQ08dFEDH58YefsY9Wj3f3hIWpKdNn109PKnYsbTw6/x
z7TTUt7t1mQkkgCdmzT/M91iEdX7KVnhCnvdW+BEpZMI+4Hzo5DTN2R9aVZK/5Bc
JoQbk2wVLmdNAJE6LYlkyemhB1Qv/MD6pBURa1jjNXhqDTqe4GWdbRffg8yHRkin
E86fpUojAgMBAAECggEAKWYr1gRtdjI99SHThnx2nNk76oe8Cb/LjMZddHn4ubkZ
lvsZEbfwBZVVjcl1+hZ5/5lsN+b8GmAaZOrXB8mcGHikIAutladx16dh4HUqIhxW
TlXze2AI/zoPkP1r7W4nIMtdVPCX9C9DzzynuwBUQA24BJN5mSweuwL+Y80ECt8A
36K3rv69oNDS1swwAmyPMqvT8Y0SJCL0dQBxp2dn1a1SjabLtH3PzI56cIHGVJep
Cb19HbnoeEU6yTVncqB2Ayw6Tut3gNLgQNPLP7WDOd/pKdl8Kx1r5pq/dcF3iwy7
BfWecJ2tFPat/JiwEOrvNaIE8gSLINogIIZN9yyBZQKBgQDPRKDg62EycnEfPUIO
3+yk+CAkPyQGxuWf0Hz5hE2iiOseM0uc5hux+Xu9lMBK/M1O1/npTSV/VKUxNkFY
HfNbKlAQWUuSObwizEdzWNGun4UGiJvh+vzSjYJniNcBkU/P5f5EKmcbiyoxx8F0
n1Opwj/iCMR+khl8jOrKjcZDdwKBgQDMfXl2IbMqVX8kQX9u4fuQR9uZk55SDg2d
J8jGOwgXSJ4xPILg+3+52T9yatwSEYEIfZoXnhOGD0HgBBK0Xf0e5Z0MR3S7npAv
Dnnz/FGL2tNMUnhSGeJlD6XUrahw2vSM314pOT9HUvCCS+3MfMXiOM8sqxm8bY0y
6e/tOzThtQKBgQC9sYW71DDkxrCZcqseifo/EYf5JICIY0iM93cptdiHxN/KiA/P
zRnTzQ1e+OD0wGH2otvqldyXqJR3cbxkNSUgbp1QGSl87rIs9uD9xHBDbWOGE0j3
jYoN+c07jJWara9qCoinQleTcc5wOO3pGlirqUhmSrfrTzNcNmw8bXzjCQKBgQCH
2fgefgb8Ye5klMrnTGSHFuYSYlq04rcyp+Kfp0oZxdmqlivQ8eSKAIVBKzLnIg/a
Jy9+7zrDPlGiVLJkd2iY5Sxvou0vVAkv6eslJ4S5Z/gmZUegK6gXQc0GvRQBXcVH
7YEt2+VpKfW0amMiDeadAubIIyem4hUDNR17OnFIXQKBgQDCNhk/IahTqTAqEqcS
vtAs6yB1r0FK3OcWRkJzW80p2lysObQ4WFPTCORn/WGVywbSNxgJTmajKZgMVZo+
SKfY3YpGGQWUvHZcoyUqx4lXIEU5CVBxqlSEFPOoxeV5xdv2P5SrDZD3fOkTignl
pY8XsaapwZgDnOlac4YeC0SM+A==
-----END PRIVATE KEY-----
```

> **IMPORTANTE**: Copia la private key EXACTAMENTE como está arriba, incluyendo los `\n` al final de cada línea.

## Paso 2: Configurar en Supabase Dashboard

1. Ve a: https://app.supabase.com/
2. Selecciona tu proyecto ATESUR
3. Ve a **Settings** → **Secrets**
4. Agrega cada uno de los 3 secrets con los valores de arriba

## Paso 3: Deploy Edge Function

```bash
cd c:\Users\eyucr\Desktop\flutter\atesur_app_v4
supabase functions deploy send-notification
```

## Verificación

Prueba enviando una notificación:

```bash
curl -X POST \
  'https://[your-project-ref].supabase.co/functions/v1/send-notification' \
  -H 'Authorization: Bearer [your-anon-key]' \
  -H 'Content-Type: application/json' \
  -d '{"title":"Prueba","body":"Funciona!"}'
```

Si todo está bien, deberías recibir:
```json
{
  "success": true,
  "sentTo": 1,
  "total": 1,
  "failed": 0
}
```
