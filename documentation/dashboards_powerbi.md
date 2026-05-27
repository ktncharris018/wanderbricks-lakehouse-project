# Guía de Dashboards Power BI — Wanderbricks

> Manual paso a paso para construir los 4 dashboards del proyecto en
> Power BI Desktop, conectado al SQL Warehouse de Databricks.

## Paleta de colores (cópiala tal cual en cada visual)

| Rol | Hex | Uso |
|---|---|---|
| **Primario** | `#1E3A8A` | Títulos, barras principales, KPIs neutros |
| **Secundario** | `#0EA5E9` | Líneas, datos secundarios |
| **Acento** | `#F59E0B` | Highlights, comparativos positivos |
| **Éxito** | `#10B981` | Confirmadas, retención alta |
| **Alerta** | `#EF4444` | Canceladas, anomalías |
| **Neutro oscuro** | `#1F2937` | Fondo de cards, texto principal |
| **Neutro claro** | `#F3F4F6` | Fondo de página |

Para aplicar: en cada visual, panel **Format** → **Data colors** → pegar el hex.

## Tipografía y formato general

- **Tema**: Vista → Theme → **Default Modern**
- **Fuente**: Segoe UI (default)
- **Tamaño de título de cada visual**: 14pt, negrita
- **Tamaño de KPIs grandes**: 32pt, negrita
- **Separador de miles**: punto (formato europeo)
- **Decimales en moneda**: 0 (los redondeos ya vienen hechos en las vistas)
- **Símbolo monetario**: `$` (USD)

## Estructura general de páginas

Crea **4 páginas** en el reporte. Cada página = un dashboard:

1. `01 - Executive Overview`
2. `02 - Operational Deep Dive`
3. `03 - Customer & Revenue`
4. `04 - Data Quality`

En cada página agrega arriba un **rectángulo** con fondo `#1E3A8A`, alto 60px, con el nombre del dashboard en blanco 18pt — para que se sienta una suite coherente.

---

# Dashboard 1 — Executive Overview

**Fuente de datos**: `gold.vw_executive_kpis` + `gold.gold_dim_destinations`

**Audiencia**: alta gerencia. Lo que quieren ver: ¿cómo va el negocio en una sola pantalla?

## Mockup

```
┌─────────────────────────────────────────────────────────────────────┐
│  EXECUTIVE OVERVIEW                                                  │
├──────────┬──────────┬──────────┬──────────┬──────────┬──────────────┤
│ INGRESOS │ RESERVAS │ TICKET   │ NOCHES   │ USUARIOS │ PROPIEDADES  │
│  $X.XM   │   X.XK   │  $XXX    │   X.X    │   X.XK   │    X.XK      │
│  ▲ +X%   │  ▲ +X%   │  ▲ +X%   │          │          │              │
├──────────┴──────────┴──────────┼──────────┴──────────┴──────────────┤
│                                │                                     │
│   📈 INGRESOS POR MES          │   🗺️  INGRESOS POR PAÍS            │
│   (gráfico de línea + área)    │   (mapa coroplético mundial)        │
│                                │                                     │
├────────────────────────────────┼─────────────────────────────────────┤
│                                │                                     │
│   📊 TOP 10 DESTINOS           │   🍩 MIX DE ESTADOS DE RESERVA      │
│   (barras horizontales)        │   (donut: confirmed/pending/cancel) │
│                                │                                     │
├────────────────────────────────┴─────────────────────────────────────┤
│   SLICERS:  [ Año ▾ ] [ Trimestre ▾ ] [ País ▾ ]                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Visuales — uno por uno

### 1. KPI Cards (la fila superior — 6 tarjetas)

Para cada tarjeta: inserta **Card** → arrastra el campo → en Format desactiva la categoría y dale tamaño 32pt.

| Tarjeta | Vista | Campo | Format |
|---|---|---|---|
| Ingresos | `vw_executive_kpis` | `SUM(ingresos_totales_r)` | Moneda, 1 decimal abreviado (`$1.2M`) |
| Reservas | `vw_executive_kpis` | `SUM(total_reservas)` | Número entero, abreviado |
| Ticket promedio | `vw_executive_kpis` | `AVERAGE(ticket_promedio_r)` | Moneda, sin decimales |
| Noches promedio | `vw_executive_kpis` | `AVERAGE(noches_promedio_r)` | 1 decimal |
| Usuarios | `vw_executive_kpis` | `SUM(usuarios_unicos)` | Entero abreviado |
| Propiedades | `vw_executive_kpis` | `SUM(propiedades_reservadas)` | Entero abreviado |

### 2. Línea — Ingresos por mes

- Tipo: **Line and stacked column chart** (mejor que solo línea)
- **Eje X**: `year` & `month_name` (concatenados con `&` en una medida o usados como jerarquía)
- **Eje Y (líneas)**: `ingresos_totales_r`
- **Eje Y (columnas)**: `total_reservas`
- **Color de línea**: `#F59E0B` (acento)
- **Color de columnas**: `#1E3A8A` (primario, opacidad 50%)
- Activa **Data labels** solo en la línea, formato `$0.0K`

### 3. Mapa — Ingresos por país

- Tipo: **Filled map** (mapa coroplético, no el de burbujas)
- **Location**: `pais_destino`
- **Tooltips**: agregar `ingresos_totales_r`, `total_reservas`, `usuarios_unicos`
- **Color saturation**: `ingresos_totales_r`
- **Color**: gradient de `#F3F4F6` (claro) a `#1E3A8A` (oscuro)

### 4. Barras horizontales — Top 10 destinos

- Tipo: **Clustered bar chart**
- **Y axis**: `destino`
- **X axis**: `ingresos_totales_r`
- **Visual-level filter**: Top N → 10 by `ingresos_totales_r`
- **Color**: degradado de `#1E3A8A` → `#0EA5E9` según valor (Format → Data colors → Conditional formatting → gradient)
- **Data labels**: ON, formato abreviado

### 5. Donut — Estados de reserva

- Tipo: **Donut chart**
- **Legend**: medida calculada (ver abajo) o usa una vista auxiliar
- **Values**: count
- **Colores** específicos:
  - confirmed → `#10B981`
  - pending → `#F59E0B`
  - cancelled → `#EF4444`

> *Tip*: para alimentar este donut, crea en Power BI una medida rápida:
> ```
> Total Confirmadas = SUM(vw_executive_kpis[reservas_confirmadas])
> Total Canceladas  = SUM(vw_executive_kpis[reservas_canceladas])
> ```
> Y construye un donut con esas 2 medidas + `Total - confirmadas - canceladas` como pendientes.

### 6. Slicers (filtros)

3 slicers en la parte inferior, estilo **Dropdown** o **Tile**:
- `year`
- `quarter`
- `pais_destino`

---

# Dashboard 2 — Operational Deep Dive

**Fuente**: `gold.vw_operational_detail` + `gold.vw_property_performance`

**Audiencia**: gerentes operativos. Necesitan filtrar, exportar y entender el detalle.

## Mockup

```
┌─────────────────────────────────────────────────────────────────────┐
│  OPERATIONAL DEEP DIVE                                               │
├──────────────────────┬──────────────────────┬───────────────────────┤
│  RESERVAS HOY        │  TASA OCUPACIÓN      │  CANCELACIÓN %        │
│   XXX                │   XX%                │   XX%                  │
├──────────────────────┴──────────────────────┴───────────────────────┤
│                                                                      │
│   MATRIZ DRILL-DOWN: País → Destino → Propiedad → Reserva           │
│   (Expandible, con ingresos y reservas por nivel)                    │
│                                                                      │
├──────────────────────────────────┬───────────────────────────────────┤
│                                  │                                    │
│   📊 RESERVAS POR TIPO PROPIEDAD │   🎯 PARETO ABC PROPIEDADES        │
│   (barras apiladas por estado)   │   (barras + línea acumulada)       │
│                                  │                                    │
├──────────────────────────────────┴───────────────────────────────────┤
│                                                                      │
│   📋 TABLA DETALLE (todas las reservas, con búsqueda y export)       │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Año] [Mes] [País] [Tipo Propiedad] [Estado] [Weekend?]     │
└──────────────────────────────────────────────────────────────────────┘
```

## Visuales — uno por uno

### 1. KPI Cards superiores

| Tarjeta | Cálculo |
|---|---|
| Reservas hoy | `CALCULATE(COUNTROWS(vw_operational_detail), vw_operational_detail[check_in] = TODAY())` |
| Tasa ocupación | `SUM(total_nights) / (DISTINCTCOUNT(property_id) * DATEDIFF(...))` — simplifica si no tienes capacidad histórica |
| Cancelación % | `DIVIDE(CALCULATE(COUNTROWS(vw_operational_detail), [booking_status]="cancelled"), COUNTROWS(vw_operational_detail))` |

### 2. Matriz drill-down

- Tipo: **Matrix**
- **Rows**: `pais_destino` → `destino` → `propiedad` (jerarquía)
- **Columns**: `booking_status`
- **Values**: `SUM(total_amount)`
- Activar **expand to next level** en cada fila
- Format: **Conditional formatting** → Data bars en la columna de totales (color `#0EA5E9`)

### 3. Barras apiladas — Reservas por tipo de propiedad

- Tipo: **Stacked bar chart**
- **Y axis**: `property_type`
- **X axis**: count
- **Legend**: `booking_status` (con los colores del semáforo confirmed/pending/cancelled)

### 4. Pareto ABC de propiedades

- Tipo: **Line and clustered column chart**
- Fuente: `vw_property_performance`
- **X axis**: `title` (top 30 propiedades)
- **Column Y**: `pct_ingresos`
- **Line Y**: `pct_acumulado`
- **Visual filter**: Top N → 30 by `ingresos`
- **Línea horizontal de referencia**: 80% (Analytics pane → Constant line)
- Esto es la **Pareto chart** clásica: barras descendentes + línea acumulada

### 5. Tabla detalle

- Tipo: **Table** (no Matrix)
- Columnas: `booking_id`, `usuario`, `propiedad`, `destino`, `check_in`, `check_out`, `total_nights`, `total_amount`, `pct_pagado`, `booking_status`, `tipo_viaje`, `bucket_estancia`
- Format: **Conditional formatting** en `pct_pagado` con data bars verde→rojo
- En el header del visual, activa **Search** (modo lectura)

### 6. Slicers

6 slicers horizontales abajo:
- `year`, `month_name`, `pais_destino`, `property_type`, `booking_status`, `is_weekend`

---

# Dashboard 3 — Customer & Revenue Analytics

**Fuente**: `gold.vw_customer_analytics` + `gold.vw_cohort_analysis`

**Audiencia**: marketing y growth. Quieren entender quién compra, cuándo, y cuánto vale.

## Mockup

```
┌─────────────────────────────────────────────────────────────────────┐
│  CUSTOMER & REVENUE ANALYTICS                                        │
├────────────────┬────────────────┬────────────────┬──────────────────┤
│ USUARIOS TOTAL │ LTV PROMEDIO   │ CHAMPIONS      │ AT RISK          │
│    X.XK        │   $XXX         │     XXX        │     XXX          │
├────────────────┴────────────────┴────────────────┴──────────────────┤
│                                                                      │
│   🎯 SEGMENTACIÓN RFM (treemap por segmento, tamaño = LTV total)    │
│                                                                      │
├──────────────────────────────────┬───────────────────────────────────┤
│                                  │                                    │
│   📊 LTV POR PAÍS DE USUARIO     │   📈 BUSINESS vs INDIVIDUAL        │
│   (barras horizontales)          │   (barras agrupadas: count + LTV)  │
│                                  │                                    │
├──────────────────────────────────┴───────────────────────────────────┤
│                                                                      │
│   🔥 COHORT ANALYSIS                                                  │
│   (mapa de calor: cohorte_registro x mes_actividad)                  │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Segmento RFM] [País Usuario] [Tipo Usuario]                │
└──────────────────────────────────────────────────────────────────────┘
```

## Visuales — uno por uno

### 1. KPI Cards superiores

| Tarjeta | Cálculo |
|---|---|
| Usuarios totales | `DISTINCTCOUNT(vw_customer_analytics[user_id])` |
| LTV promedio | `AVERAGE(vw_customer_analytics[ltv_total_r])` |
| Champions | `CALCULATE(DISTINCTCOUNT(user_id), [segmento_rfm]="Champions")` |
| At Risk | `CALCULATE(DISTINCTCOUNT(user_id), [segmento_rfm]="At Risk (high value)")` |

### 2. Treemap — Segmentación RFM

- Tipo: **Treemap**
- **Group**: `segmento_rfm`
- **Values**: `SUM(ltv_total_r)`
- **Tooltips**: agregar `COUNT(user_id)`, `AVERAGE(ticket_promedio_r)`
- **Colors** por segmento:
  - Champions → `#10B981`
  - Big Spenders → `#1E3A8A`
  - Loyal → `#0EA5E9`
  - At Risk → `#F59E0B`
  - Hibernating → `#6B7280`
  - Regular → `#9CA3AF`

### 3. Barras horizontales — LTV por país de usuario

- Tipo: **Clustered bar chart**
- **Y axis**: `pais_usuario`
- **X axis**: `SUM(ltv_total_r)`
- **Top N filter**: 15
- **Data colors**: gradiente conditional formatting

### 4. Barras agrupadas — Business vs Individual

- Tipo: **Clustered column chart**
- **X axis**: `user_type`
- **Y axis 1**: `DISTINCTCOUNT(user_id)`
- **Y axis 2** (segundo eje, "secondary"): `AVERAGE(ltv_total_r)`
- **Legend** opcional: `is_business`

### 5. Mapa de calor — Cohort analysis

- Tipo: **Matrix** con conditional formatting agresivo (no hay heatmap nativo)
- Fuente: `vw_cohort_analysis`
- **Rows**: `cohorte_registro`
- **Columns**: `mes_actividad`
- **Values**: `SUM(usuarios_activos)`
- **Format** → **Conditional formatting** → Background color → gradient blanco → `#1E3A8A`
- Tamaño de fuente en celdas: 9pt (para que quepan muchas)

### 6. Slicers

- `segmento_rfm`
- `pais_usuario`
- `user_type`

---

# Dashboard 4 — Data Quality & Pipeline Health

**Fuente**: `gold.vw_data_quality` + `gold.vw_data_quality_detail`

**Audiencia**: el equipo de datos (y el docente). Demuestra que el pipeline es observable.

## Mockup

```
┌─────────────────────────────────────────────────────────────────────┐
│  DATA QUALITY & PIPELINE HEALTH                                      │
├──────────────────┬──────────────────┬─────────────────────────────-─┤
│ TOTAL RESERVAS   │ % SIN PAGO       │ % CANCELACIÓN                  │
│  X.XK            │  XX%             │  XX%                           │
├──────────────────┴──────────────────┴────────────────────────────────┤
│                                                                      │
│   📊 RETENCIÓN BRONZE → SILVER (barras horizontales por entidad)     │
│   bookings    ████████████████  98.5%                                │
│   users       ███████████████   95.2%                                │
│   ...                                                                │
│                                                                      │
├──────────────────────────────────┬───────────────────────────────────┤
│                                  │                                    │
│   📋 TABLA DE COMPLETITUD        │   ⚠️  ANOMALÍAS DETECTADAS         │
│   (bronze vs silver counts)      │   - Reservas sin pago: XXX         │
│                                  │   - Estancia >30 noches: XXX       │
│                                  │   - Monto >$5000: XXX              │
├──────────────────────────────────┴───────────────────────────────────┤
│                                                                      │
│   📅 RANGO TEMPORAL DE DATOS                                          │
│   Desde: YYYY-MM-DD   Hasta: YYYY-MM-DD   Rango: XXX días            │
└──────────────────────────────────────────────────────────────────────┘
```

## Visuales — uno por uno

### 1. KPI Cards superiores

| Tarjeta | Vista | Campo |
|---|---|---|
| Total reservas | `vw_data_quality_detail` | `total_reservas` |
| % sin pago | `vw_data_quality_detail` | `pct_sin_pago` (formato %) |
| % cancelación | `vw_data_quality_detail` | `pct_cancelacion` (formato %) |

### 2. Barras horizontales — Retención por entidad

- Tipo: **Clustered bar chart**
- **Y axis**: `entidad`
- **X axis**: `pct_retenido`
- **Color condicional**: gradiente rojo (0%) → amarillo (90%) → verde (100%)
  - Format → Data colors → Conditional formatting → Rules:
    - 0-80 → `#EF4444`
    - 80-95 → `#F59E0B`
    - 95-100 → `#10B981`
- **Data labels**: ON con sufijo `%`

### 3. Tabla de completitud

- Tipo: **Table**
- Columnas: `entidad`, `registros_bronze`, `registros_silver`, `pct_retenido`
- Format: Data bars en `pct_retenido`

### 4. Tarjetas de anomalías (3 cards laterales)

| Card | Campo |
|---|---|
| Reservas sin pago | `reservas_sin_pago` |
| Estancia larga (>30 noches) | `reservas_estancia_larga` |
| Monto alto (>$5000) | `reservas_alto_monto` |

Cada una con color de fondo `#F59E0B` claro y texto en `#1F2937`.

### 5. Banner inferior — Rango temporal

- Tipo: **Multi-row card**
- Campos: `fecha_minima`, `fecha_maxima`, `rango_dias`

---

# Tips finales para la presentación oral

1. **Inicia mostrando el Dashboard 1** (Executive). Es lo que un decisor vería primero.
2. **Cuenta una historia con los datos**: "Las reservas crecen X% MoM, pero hay X país con tasa de cancelación anómala". El docente valora narrativa, no solo gráficos.
3. **Demuestra el drill-down en vivo** en el Dashboard 2: clic en un país → expande a destino → expande a propiedad. Eso impresiona.
4. **Termina con el Dashboard 4** (Data Quality): demuestra que sabes operar el pipeline, no solo construirlo. Esto te diferencia.
5. Si te preguntan "¿por qué este KPI?" responde siempre con la **decisión de negocio que habilita**, no con la fórmula.
6. **Practica abrir/cerrar Power BI Desktop** antes — no quieres perder 5 minutos abriéndolo durante la sustentación.

# Checklist antes de la entrega

- [ ] Los 4 dashboards tienen título con el mismo estilo (rectángulo azul arriba)
- [ ] La paleta de colores se aplicó consistentemente
- [ ] Todos los slicers funcionan (clic en uno y los visuales se actualizan)
- [ ] El drill-down de la matriz expandible funciona
- [ ] El mapa coroplético muestra colores (si está plano, faltan permisos de Bing Maps)
- [ ] El archivo `.pbix` se guarda con nombre `Wanderbricks_Dashboards.pbix`
- [ ] Sube el `.pbix` al repo en `/dashboards/Wanderbricks_Dashboards.pbix` (opcional pero suma)
