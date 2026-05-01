# 🏋️ GYMADS — Sistema Inteligente de Gestión para Gimnasios

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![GetX](https://img.shields.io/badge/GetX-6C63FF?style=for-the-badge&logo=flutter&logoColor=white)](https://github.com/jonataslaw/getx)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)](https://www.espressif.com/)

**App completa para gimnasios con control de acceso por llaveros NFC/RFID, gestión de membresías, punto de venta y más.**

[Demo](#-capturas-de-pantalla) · [Características](#-características) · [Instalación](#-instalación) · [Hardware](#-hardware-esp32)

</div>

---

## 💡 ¿Qué es GYMADS?

GYMADS es un **sistema integral de gestión para gimnasios** que combina una app móvil Flutter con hardware IoT (ESP32 + lector RFID) para ofrecer un control de acceso moderno, rápido y sin complicaciones.

Los clientes entran al gimnasio simplemente acercando su **llavero NFC/RFID** o mostrando su **código QR** personal. El sistema valida automáticamente su membresía, registra la entrada y reproduce un sonido de bienvenida. Todo en segundos, sin filas, sin listas en papel.

> 🎯 **Objetivo:** Automatizar la administración del gimnasio, desde el control de acceso hasta las ventas y el inventario.

---

## ✨ Características

### 🏷️ Control de Acceso Dual
- **RFID/NFC:** Lectura de llaveros/tarjetas mediante ESP32 conectado por WiFi.
- **Código QR:** Escaneo con cámara del celular para clientes sin llavero.
- **Anti-rebote:** Sistema inteligente que evita lecturas duplicadas del mismo llavero.
- **Sonidos personalizados:** Audio de "bienvenida" para accesos válidos y "denegado" para membresías vencidas.

### 👥 Gestión de Clientes
- Registro completo con foto de perfil, teléfono y tipo de membresía.
- **Tipos de membresía:** Normal, Estudiante, Profesor, Anual.
- Cálculo automático de **días restantes** y alertas de renovación (5 días antes).
- Códigos QR únicos por cliente para acceso alternativo.
- Sistema de caché de imágenes para rendimiento óptimo.

### 💳 Membresías y Pagos
- Renovación de membresías con cálculo automático de precios.
- **Tarifa de registro** ($250 MXN) para nuevos clientes o reingresos después de 3 meses.
- Historial completo de pagos y fechas de vencimiento.
- Precios dinámicos configurables desde la base de datos.

### 🛒 Punto de Venta (POS)
- Venta de productos del gimnasio (suplementos, bebidas, etc.).
- Control de inventario con stock en tiempo real.
- Estadísticas de ventas diarias, semanales y mensuales.

### 🎁 Promociones
- Creación de promociones personalizadas por cliente.
- Descuentos automáticos en la renovación de membresías.
- Seguimiento de promociones activas y fechas de expiración.

### 📊 Registro de Ingresos
- Control detallado de todos los ingresos del gimnasio.
- Filtrado por fecha, tipo de ingreso y cliente.
- Exportación de reportes para contabilidad.

### 📦 Inventario
- Gestión de productos con stock, precios y descripciones.
- Alertas de productos con bajo stock.
- Historial de ventas por producto.

### 📋 Logs de Acceso
- Historial completo de entradas al gimnasio.
- Filtrado por fecha, cliente y método de acceso (RFID/QR).
- Estadísticas de asistencia.

### ⚙️ Configuración y Branding
- **Personalización del gimnasio:** Nombre, color principal y fuente personalizados.
- **Multi-tenant:** Soporte para múltiples gimnasios/tenants.
- Configuración de WiFi del ESP32 (IP estática o DHCP).
- Activación/desactivación del lector RFID según necesidad.

---

## 🔌 Hardware ESP32

El sistema se conecta a un **ESP32** programado con Arduino que actúa como lector RFID standalone:

| Componente | Descripción |
|------------|-------------|
| **ESP32** | Microcontrolador WiFi que hostea un servidor HTTP local |
| **RC522 / PN532** | Módulo lector RFID/NFC para llaveros y tarjetas |
| **WiFi** | Conexión a la red local del gimnasio (soporta IP estática) |
| **Buzzer/Audio** | Retroalimentación sonora para accesos válidos/inválidos |

### Flujo de comunicación
```text
App Flutter  ──WiFi/HTTP──>  ESP32  ──SPI──>  Lector RFID
     │                            │
     └──────── UID leído <────────┘
     │
     └──> Consulta en Supabase ──> Validación de membresía
     │
     └──> Registro de acceso + Sonido de bienvenida
```

### Archivos del firmware
- `arduino/esp32_rfid_wifi_setup/esp32_rfid_wifi_setup.ino` — Firmware principal del ESP32
- `arduino/esp32_rfid_wifi_setup_fixed/esp32_rfid_wifi_setup_fixed.ino` — Versión estable con mejoras

---

## 🏗️ Arquitectura

```text
lib/
├── app/
│   ├── data/
│   │   ├── models/              # UserModel, ProductModel, SaleModel, AccessLogModel, etc.
│   │   ├── providers/           # Supabase API, Storage, Ingresos
│   │   ├── repositories/        # UserRepository, ProductRepository, SaleRepository
│   │   └── services/            # RFID Reader, Audio, Camera, Image Cache, Access Log
│   ├── modules/
│   │   ├── home/                # Dashboard principal
│   │   ├── clientes/            # Gestión de clientes y QR
│   │   ├── membresias/          # Tipos y renovación de membresías
│   │   ├── rfid_checkin/        # Acceso por llavero RFID
│   │   ├── checador/            # Acceso por escaneo QR/cámara
│   │   ├── point_of_sale/       # Punto de venta
│   │   ├── inventario/          # Control de stock
│   │   ├── ingresos/            # Registro financiero
│   │   ├── promociones/         # Promociones y descuentos
│   │   ├── access_logs/         # Historial de entradas
│   │   ├── configuracion/       # Ajustes del sistema
│   │   └── shared/              # Widgets compartidos (cámara, animaciones, audio)
│   ├── routes/                  # Navegación con GetX
│   └── global_widgets/          # Componentes reutilizables
├── core/                        # Temas, colores, utilidades responsive
└── main.dart
```

### Tech Stack
- **Flutter 3.2+** — UI multiplataforma (iOS, Android)
- **GetX** — State management, routing y dependency injection
- **Supabase** — Base de datos PostgreSQL en la nube, auth y storage
- **ESP32 + Arduino** — Hardware de lectura RFID
- **HTTP/WiFi** — Comunicación App ↔ ESP32
- **Camera + mobile_scanner** — Escaneo de QR y captura de fotos
- **just_audio** — Sonidos de retroalimentación
- **shared_preferences** — Configuración local

---

## 🚀 Instalación

### 1. Requisitos previos
- Flutter SDK `>=3.2.2`
- Dart `>=3.0.0`
- Cuenta en [Supabase](https://supabase.com)
- ESP32 con módulo RFID RC522/PN532

### 2. Configurar Supabase
1. Crear un proyecto en Supabase.
2. Ejecutar los scripts SQL en `supabase/` para crear tablas:
   ```bash
   # Tablas principales: users, access_logs, products, sales, ingresos, promotions, etc.
   ```
3. Configurar Storage bucket para fotos de clientes.
4. Copiar las credenciales de Supabase en un archivo `.env`:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-anon-key
   ```

### 3. Instalar la app
```bash
# Clonar el repositorio
git clone https://github.com/ebravo-dev/gymads.git
cd gymads

# Instalar dependencias
flutter pub get

# Ejecutar
flutter run
```

### 4. Configurar el ESP32
1. Abrir `arduino/esp32_rfid_wifi_setup/esp32_rfid_wifi_setup.ino` en Arduino IDE.
2. Configurar las credenciales WiFi del gimnasio.
3. Subir el firmware al ESP32.
4. Conectar el módulo RFID al ESP32 (pines SPI).
5. La app detectará automáticamente el ESP32 en la red local.

---

## 📱 Capturas de Pantalla

> 🚧 *Próximamente...*

---

## 🛣️ Roadmap

- [x] Control de acceso RFID + QR
- [x] Gestión de clientes y membresías
- [x] Punto de venta e inventario
- [x] Registro de ingresos y promociones
- [x] Branding personalizable por gimnasio
- [ ] App para clientes (consultar días restantes, historial)
- [ ] Notificaciones push para renovaciones
- [ ] Reportes avanzados con gráficos
- [ ] Soporte para múltiples sucursales

---

## 📄 Licencia

Este proyecto es de uso comercial y educativo.  
Desarrollado por [Eder J. G. Bravo](https://github.com/ebravo-dev).

---

> *"Hecho con 💪 para los gimnasios que quieren tecnología de verdad."*
