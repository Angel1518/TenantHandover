# TenantHandover

> **«Lo que había, cómo estaba y qué cambió»**

![Android](https://img.shields.io/badge/Android-Offline--First-0F766E)
![MVP](https://img.shields.io/badge/IA-Sin%20IA%20en%20MVP-informational)
![Zero Telemetry](https://img.shields.io/badge/Telemetr%C3%ADa-0%25-success)

**TenantHandover** es una herramienta **100 % determinista y offline** (sin IA en el flujo principal) para documentar el estado de una vivienda al entrar y al salir de un alquiler, detectar automáticamente qué elementos cambiaron y generar actas verificables.

---

## Características principales

- **Expedientes de entrega y devolución**: registra por estancias el estado de entrada (`Correcto`, `Desgaste normal`, `Incidencia`) y el estado de salida.
- **Comparación automática**: resalta al instante los puntos de inspección donde el estado cambió entre entrada y salida.
- **Exportación verificable**: genera acta en **PDF** y paquete **ZIP** con `report.json` y manifiesto criptográfico `manifest.sha256`.
- **Sin IA en el MVP**: funcionamiento directo y predecible sin dependencias externas.

---

## Privacidad

- Sin registro, sin nube, sin rastreadores y sin envío de datos personales.

---

## Instalación y compilación local

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

---

## Documentación adicional

- [DEPENDENCIES.md](DEPENDENCIES.md) · [CONTRIBUTING.md](CONTRIBUTING.md)
