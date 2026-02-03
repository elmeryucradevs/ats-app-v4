# Guía: Construcción de APK para Android

## 📦 Información del APK

- **Nombre:** atesur_app_v4
- **Versión:** 1.0.0+1
- **Package ID:** com.atesur.atesur_app_v4
- **Min SDK:** 21 (Android 5.0+)
- **Target SDK:** 34 (Android 14)

## 🔨 Proceso de Build

### Comando Ejecutado
```powershell
flutter build apk --release
```

### ¿Qué hace este comando?
1. **Limpia compilaciones previas**
2. **Resuelve dependencias** Flutter pub get
3. **Compila código Dart** a código nativo
4. **Genera código de Firebase** y Google Services
5. **Compila código Kotlin/Java** nativo
6. **Empaqueta APK** con todas las dependencias
7. **Firma el APK** con debug keys (para pruebas)

### ⏱️ Tiempo Estimado
- **Primera compilación:** 5-10 minutos
- **Compilaciones subsecuentes:** 1-3 minutos

## 📍 Ubicación del APK

Una vez completado, el APK estará en:
```
c:\Users\eyucr\Desktop\flutter\atesur_app_v4\build\app\outputs\flutter-apk\app-release.apk
```

## 📱 Instalación en Android

### Método 1: Transferencia USB
1. Conecta tu dispositivo Android a la PC
2. Habilita **Modo Desarrollador** en Android:
   - Ve a Configuración → Acerca del teléfono
   - Toca 7 veces en "Número de compilación"
3. Habilita **Instalación desde fuentes desconocidas**
4. Copia el APK al dispositivo
5. Abre el APK en el teléfono para instalarlo

### Método 2: Transferencia por Email/Drive
1. Sube el APK a Google Drive o envíalo por email
2. Abre el enlace en tu dispositivo Android
3. Descarga el APK
4. Instala desde archivos descargados

### Método 3: ADB (Avanzado)
```powershell
# Verificar dispositivo conectado
adb devices

# Instalar APK
adb install c:\Users\eyucr\Desktop\flutter\atesur_app_v4\build\app\outputs\flutter-apk\app-release.apk
```

## ⚠️ Notas Importantes

### Firma Debug vs Release
- **Actualmente usa firma DEBUG** (para pruebas rápidas)
- **Para Play Store necesitas firma RELEASE:**
  1. Generar keystore
  2. Configurar en `android/app/build.gradle.kts`
  3. Rebuild con firma de producción

### Permisos Requeridos
La app solicitará estos permisos al instalar:
- ✅ **Internet** - Para cargar streaming y datos
- ✅ **Wake Lock** - Mantener pantalla encendida durante video
- ✅ **Notifications** - Notificaciones push (FCM)
- ✅ **Network State** - Detectar conectividad

### Compatibilidad
- Android 5.0 (Lollipop) o superior
- Arquitecturas: ARM, ARM64, x86, x86_64

## 🔧 Troubleshooting

### "Error al compilar"
```powershell
flutter clean
flutter pub get
flutter build apk --release
```

### "App fuente desconocida bloqueada"
- Ve a Configuración → Seguridad
- Habilita "Instalar apps de fuentes desconocidas"

### "Parse Error"
- Verifica que tu Android sea 5.0+
- Descarga nuevamente el APK (puede estar corrupto)

## 📊 Tamaño del APK

**Estimado:** ~50-100 MB
- Código Flutter
- Firebase SDK
- Video Player
- Librerías nativas

## 🚀 Build Optimizado (Opcional)

Para reducir tamaño, construir APKs específicos por arquitectura:

```powershell
# Solo ARM64 (la mayoría de dispositivos modernos)
flutter build apk --release --target-platform android-arm64

# Split APKs (uno por arquitectura)
flutter build apk --release --split-per-abi
```

Esto generará múltiples APKs más pequeños en:
```
build\app\outputs\flutter-apk\
  - app-armeabi-v7a-release.apk (~30MB)
  - app-arm64-v8a-release.apk (~35MB)
  - app-x86_64-release.apk (~40MB)
```

## ✅ Verificación Post-Instalación

1. **Abre la app** en el dispositivo
2. Verifica los logs en consola (si está conectada)
3. **Prueba funcionalidades:**
   - Reproducción de video streaming
   - Navegación entre secciones
   - Notificaciones push (requiere registro FCM)
   - Programación de TV
   - Acceso a noticias

## 📝 Checklist de Testing

- [ ] App se instala
 correctamente
- [ ] Video streaming reproduce bien
- [ ] Navegación funciona sin crashes
- [ ] Permisos se solicitan adecuadamente
- [ ] Notificaciones se reciben (si hay tokens FCM)
- [ ] Modo oscuro/claro funciona
- [ ] Red social links abren navegador
- [ ] Programación muestra datos
