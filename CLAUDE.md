# Proyecto: JM Imports - Sistema de Gestión Personal de Taller

Esta aplicación en Flutter es un sistema de uso personal para gestionar inventario, reparaciones, clientes y finanzas de un taller de reparación de celulares y venta de repuestos.

## Reglas de Arquitectura

- **Framework:** Flutter (Frontend) y Firebase/Node.js (Backend).
- **Gestión de estado:** Usa Riverpod.
- **Diseño:** Sigue Material Design 3. Interfaz optimizada para velocidad de registro en el mostrador.

## Módulos Principales y Requisitos

1. **Inventario de Repuestos:**
   - Campos: Marca, Modelo, Calidad (ej. Original, OLED, TFT), Stock, Precio Costo.

2. **Gestión de Clientes:**
   - Campos: Nombre, Teléfono.

3. **Registro de Reparaciones (Core):**
   - Campos de Ingreso: Cliente (vinculado), Equipo (Marca/Modelo), IMEI (opcional), Problema reportado, **Condición física de ingreso** (ej. rayones, golpes, falta de bandeja SIM).
   - Campos Técnicos: **Notas internas** (para diagramas, soluciones usadas como Unlocktool, o enlaces a software), Costo de la reparación.
   - **Gestión de Estados (Kanban visual):** Recibido, En revisión, Esperando repuesto, Reparado, Entregado. (Debe ser fácil cambiar el estado visualmente).

4. **Buscador Global:**
   - Barra de búsqueda unificada para encontrar rápidamente clientes, equipos en el taller o repuestos en inventario.

5. **Módulo de Ventas:**
   - Registro de venta de repuestos o accesorios directamente desde el inventario.

6. **Dashboard Financiero:**
   - Pantalla principal con cálculo automático de márgenes.
   - Métricas: Ingresos totales, Ganancia Neta (Costo de reparación cobrado al cliente menos el Precio Costo del repuesto utilizado), Reparaciones completadas.

7. **Colores de la aplicación:**
   - const Color backgroundDark = Color(0xFF081526);
   - const Color primaryBlue = Color(0xFF417CF2);
   - const Color accentLightBlue = Color(0xFF448FF2);
   - const Color surfaceBlue = Color(0xFF164773);
   - const Color textLightGray = Color(0xFFCCD3D9);
