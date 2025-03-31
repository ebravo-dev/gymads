## Copilot Instructions

Esta es una aplicación usando flutter para gestión del gym, su uso esta enfocado en el staff y admin del gym el cual permitira gestionar usuarios con sus respectivos checkin, se piensa usar firebase en forma de API desacoplada por si en dado caso se puede cambiar a otro tipo de endpoint en otra URL, de igual forma se planea usar base de datos no relacional para este caso, por lo que si no es firebase tal vez pueda ser supabase, turso, u algún otro.

Solo respondeme en español tanto agente, como chat, como edit, pero en código usa ingles, y español también para los textos de la aplicación

## 📜 Estándares de Código
1. **Nomenclatura:**
   - `lowerCamelCase` para variables y funciones
   - `UpperCamelCase` para nombres de clases y widgets
   - `snake_case` para nombres de archivos
   - `CONSTANT_CASE` para constantes

2. **Formato:**
   - Widgets componetizados
   - Comentarios en español pero código en ingles
   - La aplicación su lenguaje será en español

3. **GetX Patterns:**
   - Controladores por módulo funcional
   - Usa el pattern de kauemurakami: https://github.com/kauemurakami/getx_pattern
   - `Obx` para reactividad en widgets
   - Inyección de dependencias con `Bindings`
   - Buenas practicas de programación
   - Providers para consumir API de Firebase Firestore
   - Respeta el orden de carpetas que de provee y observa el getx pattern de kauemurakami

## 🏋️ Descripción de la Aplicación
Sistema integral para gestión de:
- Control de acceso mediante QR o número de usuario
- Perfiles de usuarios (Admin, Staff, Clientes)
- Gestión de membresías y pagos recurrentes
- Sistema de promociones y paquetes
- Reportes y estadísticas

## 💻 Especificaciones Técnicas
| Componente          | Tecnología                  |
|---------------------|-----------------------------|
| Frontend            | Flutter (Multiplataforma)   |
| State Management    | GetX                        |
| Autenticación       | Firebase Auth               |
| Base de Datos       | Cloud Firestore SOLO API    |
| QR.                 | mobile_scanner              |
| Pagos               | local(de manera fisica)     |

## 🚀 Principales Funcionalidades

### 🔐 Autenticación y Roles
- Login con Google, solo admin y staff
- Roles:
  - **Admin:** Gestión completa, reportes y configuraciones y las de staff también
  - **Staff:** Escanear QR para entradas, registro de clientes y pagos
  - **Cliente:** Perfil y estado de membresía, los clientes no inician sesión

### 🎟 Control de Acceso
- Escaneo de QR único por usuario o por número de usuario
- Validación de membresía
- Historial de accesos
- 1 mes = 30 días
- Si el usuario dejo de pagar hace 3 meses la membresía, deberá pagar por registro nuevo

### 💳 Gestión de Pagos
- Tipos de membresía:
  - Diario/Semanal/Mensual/Anual con la opción de que el admin pueda añadir o quitar tipos
  - Paquetes personalizados (Ej: 3 meses + 1 gratis)
- Sistema de promociones:
  - Descuentos
  - 3x2 en paquetes
  - Bonos de regalo
  - Opción de que el admin pueda añadir o quitar promociones
- Recordatorios automáticos de renovación "quedán n días", "hoy es tu último día", "vencido"

### 📊 Panel Administrativo
- Dashboard con métricas clave
- CRUD de usuarios y membresías
- Generación de reportes personalizados
- Configuración de promociones y precios
- Visualización de check-ins

##  Casos de Uso Principales
- usuario llega da su numero o da su imagen QR pasa su registro
- advertencia a partir de 5 días notificar renovación
- registrar pago de membresía
- recuento del día
- los pagos se hacen por terminal, transfernecia o efectivo
- al registrar el pago que venga acompañado del método de pago

### 1. Check-in de Usuario
```dart
1. Staff inicia sesión con rol correspondiente
2. Escanea QR o ingresa el número del usuario
3. Sistema verifica:
   - Membresía vigente
   - Pagos al día
4. Registra acceso y notifica al usuario
5. Muestra días que faltan para vencimiento
6. Muestra la foto del usuario con su información básica