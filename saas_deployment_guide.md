# Guía de Despliegue SaaS: Creación y Vinculación de Canales (Mobile & Web)

Esta guía detalla los pasos exactos que debes seguir para crear y publicar una nueva aplicación móvil o sitio web para un canal específico, garantizando que el sistema recopile automáticamente su información y aplique sus límites de suscripción.

---

## 🧭 ¿Cómo funciona la arquitectura SaaS Multi-Canal?

Tu plataforma utiliza una arquitectura **SaaS Single-Tenant Database / Multi-Tenant Client**. Esto significa que:
* **Un Solo Backend**: Todos los canales, usuarios, películas y programas se almacenan en la **misma base de datos de Supabase**.
* **Aislamiento por Consulta**: Las aplicaciones cargan los datos y filtran en caliente usando el `channel_id` correspondiente.
* **Resolución Dinámica al Iniciar**:
  * **En Móvil**: Se lee el identificador del paquete (Package Name) del dispositivo.
  * **En Web**: Se lee el dominio (Origin) desde el navegador.

---

## 🌐 1. Creación y Despliegue de un Nuevo Sitio Web (Web App)

Cuando quieres dar de alta la versión web para un nuevo canal (ej. *Canal X*):

### Paso A: Compilar el Proyecto Web
1. Abre tu terminal en la raíz del proyecto `atesur_app_v4`.
2. Genera el build de producción para la web. Puedes usar el script de PowerShell integrado o el comando directo:
   ```bash
   flutter build web --release
   ```
   *(Este comando genera la carpeta estática optimizada en `build/web`).*

### Paso B: Alojar la Web en un Dominio o Subdominio
1. Sube el contenido de la carpeta `build/web` al hosting de tu preferencia (Firebase Hosting, Vercel, Netlify, etc.).
2. Configura tu dominio o subdominio personalizado para esa web específica. Por ejemplo:
   * `https://canalx.atesur.tv`
   * `https://atesur-canalx.web.app`

### Paso C: Vincular en el Panel de Administración (Super Admin)
1. Abre el **Editor de Canales de Escritorio** e inicia sesión con tu cuenta de **Super Admin**.
2. Dirígete a la pestaña **ADMINISTRACIÓN GLOBAL** -> **Canales y Vinculación**.
3. Presiona **Crear Canal** (o edita un canal existente).
4. En el campo **Web App URL**, escribe la URL exacta **sin barra diagonal al final `/`**:
   `https://canalx.atesur.tv`

> [!IMPORTANT]
> Cuando un usuario abra esa dirección, la web consultará a Supabase en microsegundos y cargará automáticamente la grilla y anuncios asignados al *Canal X*.

---

## 📱 2. Creación y Compilación de una Nueva App Móvil (Android)

Cuando quieres generar una aplicación Android dedicada para un nuevo canal (ej. *Canal X*):

### Paso A: Cambiar el Identificador de la App (Package Name)
Cada app en Android debe tener un identificador único en el mundo (`applicationId`).
1. Abre el archivo `android/app/build.gradle` en la ruta `android/app/build.gradle`.
2. Busca la línea `applicationId` dentro de `defaultConfig` y cámbiala por el nuevo nombre de paquete:
   ```groovy
   defaultConfig {
       // Cambia esto de "com.atesur.app" al nombre de tu nuevo canal
       applicationId "com.atesur.canalx" 
       ...
   }
   ```

### Paso B: Cambiar el Nombre Visual y Logotipo (Opcional)
Para personalizar la identidad del canal en el teléfono del usuario:
* **Nombre de la App**: Abre `android/app/src/main/AndroidManifest.xml` y cambia el valor de `android:label` a `"ATESUR Canal X"`.
* **Icono de la App**: Reemplaza las imágenes de iconos dentro de `android/app/src/main/res/mipmap-*` con el logotipo del nuevo canal.

### Paso C: Compilar la App de Producción
1. Abre la terminal en la raíz del proyecto `atesur_app_v4`.
2. Genera el paquete de distribución oficial:
   * **Para Tiendas (Google Play)**: `flutter build appbundle`
   * **Para Instalación Directa**: `flutter build apk --split-per-abi`

### Paso D: Vincular en el Panel de Administración (Super Admin)
1. Abre tu panel de **Super Admin** en el Editor de Escritorio.
2. Ve a la pestaña **Canales y Vinculación** y edita el canal (*Canal X*).
3. En el campo **Android Package Name**, escribe exactamente el mismo identificador que pusiste en el Gradle:
   `com.atesur.canalx`

> [!IMPORTANT]
> Cuando el usuario abra la app en su teléfono, esta leerá su propio paquete (`com.atesur.canalx`), buscará su coincidencia en Supabase y aislará la grilla, in-app messages y notificaciones para el *Canal X*.

---

## 👑 3. Operaciones de Administración Global (Super Admin Workflow)

Una vez que las aplicaciones móviles o web están vinculadas, puedes gestionar todo su comportamiento comercial directamente desde la interfaz del editor:

### 1. Gestión de Suscripciones y Planes
Desde la pestaña **Suscripciones Directas**, puedes modificar en caliente los planes de cualquier canal:
* Haz clic en **Sobrescribir Plan** en el canal que desees.
* **Planes Disponibles**:
  * `Free`: Biblioteca limitada a 15 películas, sin acceso a vMix Titler ni notificaciones.
  * `Pro`: Biblioteca ampliada, notificaciones push habilitadas y acceso completo a automatizaciones vMix locales.
  * `Lifetime`: Acceso permanente sin fecha de caducidad.
* **Duración**: Establece la duración en días (ej. 30 días para un ciclo mensual, o `-1` para vitalicio).
* **Estados**: Controla si está `active`, en periodo de prueba (`trialing`), suspendida por impago (`past_due`) o cancelada (`canceled`).

### 2. Generador de Seriales (Claves de Licencia)
Si realizas ventas directas fuera de la web o quieres ofrecer seriales corporativos:
1. Ve a la pestaña **Claves de Licencia**.
2. Presiona **Generar Licencias**.
3. Selecciona el tipo de plan (`Pro` o `Lifetime`), la cantidad de días de vigencia y la cantidad de seriales que deseas generar.
4. El sistema creará un lote de claves criptográficas seguras (ej: `ATS-PRO-F83C-49D2`).
5. Copia el serial y entrégaselo al dueño del canal. Al ingresarlo en su sección **Licencia y Planes**, su canal se actualizará al instante de manera local y en la nube.

---

## 🔒 4. Seguridad Anti-Piratería y Trials Automáticos

* **Trial Gratuito de 14 Días**: La base de datos tiene un trigger Postgres (`on_auth_user_created_super_admin`). Cuando un nuevo usuario se registra, el servidor le crea de forma automática su propio canal con un plan **Pro Trial de 14 días** activo inmediatamente, ofreciéndole una experiencia de onboarding directa sin necesidad de configurar seriales al inicio.
* **Protección Local de vMix**: Si la suscripción de un canal expira o se cancela en la nube, el hilo de comunicación de vMix en el editor del cliente detecta en vivo que el flag `showVmixTitler` es falso. **Inmediatamente detiene y desconecta el polling de sincronización**, asegurando que ninguna función premium pueda ejecutarse localmente si la suscripción no está activa en Supabase.
