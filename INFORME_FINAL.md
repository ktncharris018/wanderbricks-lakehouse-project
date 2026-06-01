# 📋 INFORME FINAL DEL PROYECTO

## Wanderbricks Lakehouse — Pipeline de Business Intelligence End-to-End

---

### Información general

| Campo | Detalle |
|---|---|
| **Proyecto** | Wanderbricks Lakehouse Project |
| **Asignatura** | Bases de Datos Avanzada |
| **Periodo** | 2026-I |
| **Universidad** | Universidad Popular del Cesar |
| **Facultad** | Ingenierías |
| **Docente** | Ing. Amilkar Sierra Romano |
| **Fecha de entrega** | Junio 2026 |
| **Repositorio** | [github.com/ktncharris018/wanderbricks-lakehouse-project](https://github.com/ktncharris018/wanderbricks-lakehouse-project) |

### Integrantes del equipo

| Nombre | Rol |
|---|---|
| **Oswaldo Rojano Mora** | Arquitecto de Datos · Data Modeler · BI Developer |
| **Juan Fernando Florez** | Data Engineer · Especialista en Ingesta y Streaming |
| **Kristian Charris** | Analytics Engineer · Especialista en dbt y Calidad de Datos |

---

## Tabla de Contenidos

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Introducción](#2-introducción)
3. [Objetivos](#3-objetivos)
4. [Marco teórico](#4-marco-teórico)
5. [Arquitectura del proyecto](#5-arquitectura-del-proyecto)
6. [Implementación por capa](#6-implementación-por-capa)
7. [Streaming e ingesta en tiempo real](#7-streaming-e-ingesta-en-tiempo-real)
8. [Transformación con dbt](#8-transformación-con-dbt)
9. [Modelado dimensional — Star Schema](#9-modelado-dimensional--star-schema)
10. [Dashboards en Power BI](#10-dashboards-en-power-bi)
11. [Machine Learning — Forecasting predictivo](#11-machine-learning--forecasting-predictivo)
12. [Orquestación con Databricks Workflows](#12-orquestación-con-databricks-workflows)
13. [Calidad de datos y observabilidad](#13-calidad-de-datos-y-observabilidad)
14. [Decisiones de diseño defendibles](#14-decisiones-de-diseño-defendibles)
15. [Metodología de trabajo en equipo](#15-metodología-de-trabajo-en-equipo)
16. [Resultados obtenidos](#16-resultados-obtenidos)
17. [Conclusiones](#17-conclusiones)
18. [Recomendaciones para producción](#18-recomendaciones-para-producción)
19. [Referencias](#19-referencias)

---

## 1. Resumen ejecutivo

El presente informe documenta el desarrollo del **Proyecto Final de Bases de Datos Avanzada (2026-I)**, consistente en el diseño e implementación de una **arquitectura Lakehouse moderna** sobre la plataforma **Databricks**, aplicando el patrón **Medallion** (Bronze → Silver → Gold) al dataset público `samples.wanderbricks` —una plataforma global de reservas de alojamiento turístico análoga a Airbnb / Booking.

El proyecto integra ocho tecnologías de nivel productivo: **Apache Spark**, **Delta Lake**, **Apache Spark Structured Streaming**, **dbt Core + dbt-databricks**, **Unity Catalog**, **Power BI**, **Prophet (Meta)** y **Databricks Workflows**. La implementación cubre el ciclo completo del dato: ingesta event-driven, transformaciones declarativas con tests automatizados, modelado dimensional Star Schema, visualización ejecutiva mediante tres dashboards interactivos, y forecasting predictivo del revenue futuro mediante Machine Learning.

Como evidencia de cumplimiento de la guía oficial (sección 3.3 del PDF del docente), se implementaron **30+ tests de calidad de datos** en dbt distribuidos entre los cuatro tipos requeridos (`not_null`, `unique`, `accepted_values`, `relationships`), generando **linaje automático** mediante `dbt docs generate` y vinculando los modelos a los dashboards mediante `dbt Exposures`.

El equipo trabajó bajo metodología **Feature Branch Workflow** con Pull Requests, manteniendo más de 20 ramas mergeadas a `main` durante el desarrollo.

---

## 2. Introducción

### 2.1 Contexto

Los proyectos modernos de Business Intelligence enfrentan tres desafíos principales: (1) procesar volúmenes crecientes de datos heterogéneos, (2) garantizar la confiabilidad y trazabilidad del dato a lo largo de las transformaciones, y (3) entregar insights accionables a tomadores de decisión en tiempo real. La **arquitectura Lakehouse** propuesta por Databricks en 2020 combina las virtudes de los Data Warehouses tradicionales (transaccionalidad, gobernanza, performance SQL) con las del Data Lake (escalabilidad, flexibilidad, costo eficiente), mediante el formato **Delta Lake** y el patrón de organización **Medallion**.

### 2.2 Justificación

La elección de este stack tecnológico no es arbitraria: Databricks, dbt y Power BI son el **estándar de la industria** actual en empresas de tecnología, finanzas, retail y salud. Dominar este ecosistema posiciona a los integrantes del equipo para roles como **Data Engineer**, **Analytics Engineer** o **BI Developer** con un perfil competitivo en el mercado laboral.

### 2.3 Alcance

El proyecto cubre las cinco fases del ciclo de vida del dato:

1. **Ingesta** — batch inicial + simulación event-driven sobre 6 entidades de negocio.
2. **Limpieza y transformación** — 11 modelos dbt distribuidos en Silver y Gold.
3. **Modelado dimensional** — Star Schema con 1 fact table y 4 dimensiones.
4. **Visualización** — 3 dashboards conectados vía DirectQuery a Databricks SQL Warehouse.
5. **Analítica predictiva** — modelo Prophet entrenado sobre la fact table prediciendo revenue futuro.

---

## 3. Objetivos

### 3.1 Objetivo general

Diseñar, implementar y desplegar una **arquitectura Lakehouse productiva** sobre Databricks que procese datos batch y streaming del dataset Wanderbricks, transformándolos mediante el patrón Medallion en un Star Schema dimensional consumible por dashboards ejecutivos en Power BI, complementado con un componente de Machine Learning para predicción de revenue.

### 3.2 Objetivos específicos

- Implementar la capa **Bronze** como repositorio inmutable de datos crudos.
- Implementar la capa **Silver** mediante **dbt Core** con tests automatizados de calidad (`not_null`, `unique`, `accepted_values`, `relationships`).
- Diseñar e implementar un **Star Schema** en la capa Gold con una tabla de hechos (`gold_fact_reservas`) y cuatro dimensiones (`gold_dim_users`, `gold_dim_properties`, `gold_dim_destinations`, `gold_dim_time`).
- Configurar **Spark Structured Streaming** para simular eventos de reservas en tiempo real.
- Conectar **Power BI** al SQL Warehouse de Databricks mediante DirectQuery, construyendo tres dashboards interactivos.
- Implementar un componente de **Machine Learning** mediante el algoritmo **Prophet** de Meta para predecir el revenue de los próximos 6 meses.
- Orquestar el pipeline completo mediante **Databricks Workflows**.
- Aplicar la metodología **Feature Branch Workflow** con GitHub y Databricks Repos.
- Documentar todas las decisiones técnicas mediante `dbt docs`, archivos `schema.yml`, diagramas Mermaid y este informe.

---

## 4. Marco teórico

### 4.1 Arquitectura Lakehouse

El concepto de **Lakehouse**, formalizado por Armbrust et al. (Databricks, 2020), combina:

- **Storage open** (formato Parquet) con bajo costo del Data Lake.
- **Transaccionalidad ACID** sobre archivos columnares mediante **Delta Lake**.
- **Schema enforcement** y **time travel** sobre el storage.
- **Performance SQL** comparable a Data Warehouses tradicionales mediante optimizaciones como Z-Ordering.

### 4.2 Arquitectura Medallion

El patrón Medallion organiza los datos en tres capas progresivas:

| Capa | Propósito | Características |
|---|---|---|
| **🟫 Bronze** | Ingesta cruda | Inmutable · Fuente de verdad histórica · Tipos originales |
| **⬜ Silver** | Limpieza y normalización | Deduplicado · Tipificado · Validado |
| **🟡 Gold** | Modelo analítico | Star Schema · Pre-agregaciones · Listo para BI |

### 4.3 dbt (data build tool)

**dbt** es un framework open-source que permite a analistas e ingenieros transformar datos en el warehouse mediante **SQL declarativo**, con:

- Versionado en Git
- Tests automatizados (`not_null`, `unique`, `accepted_values`, `relationships`)
- Documentación inline en `schema.yml`
- Linaje de datos automático con `dbt docs generate`
- Exposures que vinculan modelos a dashboards consumidores

### 4.4 Star Schema (Kimball)

El modelo dimensional **Star Schema**, formalizado por Ralph Kimball en *The Data Warehouse Toolkit*, organiza datos analíticos en:

- **Fact tables**: contienen métricas numéricas del negocio
- **Dimension tables**: contienen atributos descriptivos
- Relaciones simples (un solo nivel de profundidad)

Ventajas: rendimiento óptimo para consultas analíticas, menor cantidad de JOINs, comprensión intuitiva por usuarios de BI.

### 4.5 Prophet (Meta)

**Prophet** es un algoritmo de forecasting de series temporales desarrollado por Meta (Facebook) en 2017. Modela la serie como suma de tres componentes:

```
y(t) = g(t) + s(t) + h(t) + ε(t)
```

Donde: `g(t)` es la tendencia, `s(t)` la estacionalidad, `h(t)` el efecto de feriados, y `ε(t)` el error aleatorio. Es robusto a datos faltantes, outliers, y maneja estacionalidad anual automáticamente.

---

## 5. Arquitectura del proyecto

### 5.1 Diagrama de arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FUENTES DE DATOS                            │
│  samples.wanderbricks (carga batch inicial)                          │
│  + simulador event-driven de eventos sintéticos                      │
└────────────────────────┬─────────────────────────────────────────────┘
                         │
                         ▼  notebook 02 + notebook 06
        ┌──────────────────────────────────────────────┐
        │           BRONZE LAYER (Delta Lake)          │
        │  bronze_bookings · bronze_users · payments   │
        │  bronze_properties · destinations · reviews  │
        │  → 6 tablas inmutables                        │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼  dbt run --select silver (notebook 08)
        ┌──────────────────────────────────────────────┐
        │           SILVER LAYER (Delta Lake)          │
        │  silver_* con:                                │
        │    · Deduplicación por PK                     │
        │    · Casteo a tipos correctos                 │
        │    · TRIM de strings                          │
        │    · Reglas de negocio                        │
        │  + 30 tests dbt validados automáticamente     │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼  dbt run --select gold (notebook 08)
        ┌──────────────────────────────────────────────┐
        │           GOLD LAYER — Star Schema           │
        │  Fact: gold_fact_reservas                     │
        │  Dims: gold_dim_users, properties,            │
        │        destinations, time                      │
        │  + 8 vistas analíticas para BI                │
        │  + tabla de forecast (Machine Learning)       │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼
        ┌──────────────────────────────────────────────┐
        │       DATABRICKS SQL WAREHOUSE               │
        │       (motor de consulta serverless)         │
        └────────────────────┬─────────────────────────┘
                             │ DirectQuery
                             ▼
        ┌──────────────────────────────────────────────┐
        │              POWER BI DESKTOP                │
        │  Dashboard 1 — Executive Overview            │
        │  Dashboard 2 — Customer Analytics            │
        │  Dashboard 3 — Pipeline & Data Quality       │
        └──────────────────────────────────────────────┘
```

### 5.2 Componentes técnicos

| Capa | Tecnología | Justificación |
|---|---|---|
| Almacenamiento | **Delta Lake** | ACID + Time Travel + Schema enforcement sobre Parquet |
| Procesamiento | **Apache Spark + PySpark** | Motor distribuido estándar de la industria |
| Streaming | **Spark Structured Streaming** | Misma API que batch, micro-batching tolerante a fallos |
| Transformación | **dbt Core + dbt-databricks** | SQL declarativo con tests, docs y linaje automático |
| Gobernanza | **Unity Catalog (Volumes)** | Storage gobernado con permisos a nivel de objeto |
| BI | **Power BI Desktop + DirectQuery** | Conector nativo, datos siempre frescos |
| ML | **Prophet** | Forecasting robusto open-source de Meta |
| Orquestación | **Databricks Workflows** | DAG nativo, sin Airflow externo |
| Versionado | **GitHub + Databricks Repos** | Feature branches + PRs colaborativo |

---

## 6. Implementación por capa

### 6.1 Capa Bronze (notebook `02_bronze_layer.ipynb`)

La capa Bronze almacena copia 1:1 del dataset `samples.wanderbricks` distribuido en 6 tablas Delta:

```sql
CREATE TABLE bronze.bronze_bookings AS
SELECT * FROM samples.wanderbricks.bookings;
-- (similar para users, properties, destinations, payments, reviews)
```

**Características**:
- Inmutable: una vez escrita, no se modifica.
- Tipos originales preservados.
- Sirve como fuente de verdad histórica.
- Permite reprocesar Silver/Gold sin volver a leer la fuente original.

**Tablas resultantes** (6):
- `bronze.bronze_bookings`
- `bronze.bronze_users`
- `bronze.bronze_properties`
- `bronze.bronze_destinations`
- `bronze.bronze_payments`
- `bronze.bronze_reviews`

### 6.2 Capa Silver (modelos dbt en `dbt/models/silver/`)

La capa Silver es implementada mediante **dbt Core** con conector `dbt-databricks`, cumpliendo explícitamente la sección 3.3 de la guía oficial.

**Transformaciones aplicadas a cada entidad**:

| Regla | Implementación SQL |
|---|---|
| Deduplicación | `ROW_NUMBER() OVER (PARTITION BY pk ORDER BY updated_at DESC)` |
| Casteo de tipos | `CAST(... AS DATE / TIMESTAMP / DECIMAL / BIGINT / BOOLEAN)` |
| Estandarización de strings | `TRIM(...)` en columnas textuales |
| Validez de fechas | `WHERE check_out > check_in` |
| Validez de montos | `WHERE total_amount > 0` |
| Validez de ratings | `WHERE rating BETWEEN 0 AND 5 AND is_deleted = false` |
| Filtro de PK nula | `WHERE pk IS NOT NULL` |

**Modelos producidos** (6):

```
dbt/models/silver/
├── silver_users.sql
├── silver_destinations.sql
├── silver_properties.sql
├── silver_bookings.sql       (incluye total_nights derivado)
├── silver_payments.sql
└── silver_reviews.sql
```

### 6.3 Capa Gold (modelos dbt en `dbt/models/gold/`)

La capa Gold implementa el **Star Schema** con:

**Tabla de hechos**: `gold_fact_reservas`
- Granularidad: una fila por reserva (`booking_id`)
- Métricas: `total_amount`, `total_nights`, `cantidad_reservas`, `payment_amount`
- FKs: `user_id`, `property_id`, `destination_id`, `tiempo_id`

**Dimensiones** (4):
- `gold_dim_users`
- `gold_dim_properties`
- `gold_dim_destinations`
- `gold_dim_time` (generada dinámicamente con `SEQUENCE`)

**Vistas analíticas** sobre Gold (8):
- `vw_executive_kpis` — KPIs financieros con GMV vs Revenue
- `vw_operational_detail` — detalle a nivel reserva
- `vw_customer_analytics` — segmentación RFM y LTV
- `vw_property_performance` — clasificación ABC tipo Pareto
- `vw_cohort_analysis` — análisis de cohortes
- `vw_data_quality` — métricas de retención por entidad
- `vw_data_quality_detail` — anomalías financieras
- `gold_revenue_forecast` — predicciones del modelo Prophet

---

## 7. Streaming e ingesta en tiempo real

### 7.1 Arquitectura del notebook `06_streaming_pipeline.ipynb`

El notebook simula la llegada de eventos en tiempo real insertando registros sintéticos directamente en las 6 tablas Bronze, respetando el **orden topológico de claves foráneas**:

```
1. destinations  (sin FK)
2. users         (sin FK)
3. properties    (FK → destinations)
4. bookings      (FK → users, properties)
5. payments      (FK → bookings)
6. reviews       (FK → bookings, users, properties)
```

### 7.2 Volumen simulado

| Entidad | Eventos generados |
|---|---|
| destinations | 5 |
| users | 30 |
| properties | 10 |
| bookings | 50 |
| payments | 40 |
| reviews | 20 |
| **Total** | **155 eventos** |

### 7.3 Justificación del patrón "una tabla por entidad"

Inicialmente se implementó un patrón con **tablas intermedias** (`bronze_events_topic`, `bronze_bookings_stream`, vista `bronze_bookings_all`). Posteriormente se refactorizó a **inserción directa en `bronze.bronze_<entidad>`** porque:

1. Elimina el anti-patrón de mantener múltiples tablas para la misma entidad.
2. Las plataformas modernas (Snowflake, Iceberg) promueven el principio "**una entidad = una tabla**".
3. Silver/Gold no necesitan distinguir el origen del registro.
4. Power BI consume una única tabla sin necesidad de vistas que unifiquen fuentes.

### 7.4 Compatibilidad con Databricks Serverless

Para garantizar compatibilidad con el cluster Serverless de Databricks Free Edition (que tiene restringido el acceso a la API RDD), se implementó el helper `align_to_target()`:

```python
def align_to_target(df, target_table):
    target_schema = spark.table(target_table).schema
    return df.select([
        col(field.name).cast(field.dataType).alias(field.name)
        for field in target_schema.fields
    ])
```

Esta función lee el schema real de la tabla destino y aplica `CAST` por columna, evitando el error `DELTA_FAILED_TO_MERGE_FIELDS` sin recurrir a la API RDD.

---

## 8. Transformación con dbt

### 8.1 Configuración del proyecto dbt

```
dbt/
├── dbt_project.yml           # nombre, perfiles, materialización
├── profiles.example.yml      # plantilla de credenciales
├── .gitignore                # excluye profiles.yml real
├── README.md                 # manual de uso
└── models/
    ├── sources.yml           # define Bronze como source
    ├── silver/               # 6 modelos + schema.yml
    └── gold/                 # 5 modelos + schema.yml + exposures.yml
```

### 8.2 Tests de calidad implementados

Total: **30+ tests** distribuidos entre los 4 tipos exigidos por el PDF.

**Ejemplo extraído de `dbt/models/silver/schema.yml`**:

```yaml
- name: silver_bookings
  description: "Reservas limpias con total_nights derivado."
  columns:
    - name: booking_id
      tests:
        - not_null
        - unique
    - name: user_id
      tests:
        - not_null
        - relationships:
            to: ref('silver_users')
            field: user_id
    - name: status
      tests:
        - accepted_values:
            values: ['confirmed', 'pending', 'cancelled']
```

### 8.3 Exposures — vinculación con dashboards

El archivo `dbt/models/gold/exposures.yml` declara explícitamente qué modelos consumen cada uno de los 3 dashboards Power BI:

```yaml
exposures:
  - name: dashboard_executive_overview
    type: dashboard
    depends_on:
      - ref('gold_fact_reservas')
      - ref('gold_dim_destinations')
      - ref('gold_dim_time')
```

Esto permite que `dbt docs generate` muestre el linaje completo desde Bronze hasta los 3 dashboards consumidores.

### 8.4 Ejecución desde Databricks

El notebook `08_run_dbt.ipynb` permite ejecutar dbt **directamente desde un notebook de Databricks**, sin requerir instalación local. El notebook:

1. Instala `dbt-core` y `dbt-databricks` con `%pip install`.
2. Genera dinámicamente el `profiles.yml` con credenciales del workspace.
3. Ejecuta `dbt debug`, `dbt run --select silver`, `dbt run --select gold`, `dbt test`, `dbt docs generate`.
4. Reporta el conteo final de tablas creadas.

---

## 9. Modelado dimensional — Star Schema

### 9.1 Diseño

El Star Schema implementado responde las siguientes preguntas analíticas:

1. Ingresos por país, región y propiedad
2. Reservas por mes, trimestre y año
3. Ocupación (`total_nights`) por propiedad y destino
4. Comportamiento de usuarios (tipo, país, business vs individual)
5. Desempeño de propiedades (top alojamientos)
6. Análisis geográfico (distribución de ingresos)

### 9.2 Diagrama

```
                            ┌──────────────────┐
                            │   gold_dim_time  │
                            │   tiempo_id (PK) │
                            └────────┬─────────┘
                                     │
                                     │
┌──────────────────┐   ┌─────────────▼──────────────┐   ┌─────────────────────┐
│ gold_dim_users   │◄──┤   gold_fact_reservas       ├──►│ gold_dim_properties │
│ user_key (PK)    │   │   booking_id (PK)          │   │ property_key (PK)   │
└──────────────────┘   │   user_id (FK)              │   └─────────────────────┘
                       │   property_id (FK)          │
                       │   destination_id (FK)       │
                       │   tiempo_id (FK)            │
                       │                              │
                       │   Métricas:                  │
                       │   - total_amount             │
                       │   - total_nights             │
                       │   - cantidad_reservas        │
                       │   - payment_amount           │
                       └─────────────┬────────────────┘
                                     │
                          ┌──────────▼─────────────┐
                          │ gold_dim_destinations  │
                          │ destination_key (PK)   │
                          └────────────────────────┘
```

### 9.3 Decisiones de diseño

- **Grano elegido**: una fila por reserva (`booking_id`). Es el evento atómico de negocio.
- **`destination_id` en la fact**: viene resuelto vía JOIN con `silver_properties` ya que `bookings` no lo contiene directamente.
- **Pre-agregación de pagos**: se calcula `SUM(amount) GROUP BY booking_id` antes del JOIN para evitar duplicar filas de la fact cuando una reserva tiene múltiples pagos.
- **`gold_dim_time` dinámica**: se construye con `SEQUENCE(MIN(check_in), MAX(check_out), INTERVAL 1 DAY)` para adaptar el calendario al rango real de los datos.
- **Omisión de `description` en `gold_dim_destinations`**: el campo trae texto markdown extenso (~5 KB por fila) que no aporta al análisis dimensional.

---

## 10. Dashboards en Power BI

Los tres dashboards se conectan al SQL Warehouse de Databricks vía **DirectQuery**, garantizando datos siempre frescos.

### 10.1 Dashboard 1 — Executive Overview

**Audiencia**: alta gerencia.
**Pregunta clave**: *"¿Cómo va el negocio en una sola pantalla?"*

**KPIs implementados** (8):
1. Valor Reservado (GMV) — métrica de tamaño del negocio
2. Ingreso Real (Revenue Neto) — solo confirmadas
3. Ingreso Pendiente — atrapado en pipeline operativo
4. Ingreso Perdido — costo de oportunidad por cancelaciones
5. Ticket Confirmado promedio
6. Reservas totales
7. Estancia promedio (noches)
8. Propiedades activas

**Visualizaciones**:
- Gráfico de área con tendencia mensual de ingresos
- Mapa mundial con burbujas de tamaño proporcional al ingreso por país
- Top 5 destinos con más ingresos (barras horizontales)
- Donut de estados de reserva (confirmadas / pendientes / canceladas)

### 10.2 Dashboard 2 — Customer Analytics

**Audiencia**: equipo de marketing y growth.
**Pregunta clave**: *"¿Quiénes son nuestros clientes y cómo se comportan?"*

**KPIs implementados** (8):
1. Usuarios totales
2. LTV promedio
3. Champions (segmento RFM)
4. At Risk (segmento RFM)
5. Destinos promedio por usuario
6. Reservas promedio por usuario
7. Usuarios business
8. Días desde última reserva

**Visualizaciones**:
- Treemap de segmentación RFM (6 segmentos coloreados)
- Top 5 usuarios por LTV
- Análisis de comportamiento adicional

### 10.3 Dashboard 3 — Pipeline & Data Quality

**Audiencia**: equipo de datos y management técnico.
**Pregunta clave**: *"¿Son confiables nuestros datos? ¿Qué tan saludable es el pipeline?"*

**KPIs implementados** (8):
1. Salud general del pipeline (% retención promedio)
2. Registros Bronze totales
3. Registros Silver totales
4. Frescura de datos
5. Peor retención (alerta)
6. % Sin pago
7. Cobertura temporal (días)
8. Registros filtrados (limpieza de dbt)

**Visualizaciones**:
- Barras horizontales con color semáforo (retención por entidad)
- Donut de estados de reserva (perspectiva de calidad)
- 3 tarjetas de anomalías (sin pago, monto alto, estancia larga)
- Gauge de salud general del pipeline

---

## 11. Machine Learning — Forecasting predictivo

### 11.1 Implementación

El notebook `10_ai_prediction.ipynb` implementa un modelo **Prophet** que predice el revenue de los próximos 6 meses.

**Pipeline ML completo en ~25 líneas de código**:

```python
from prophet import Prophet
import pandas as pd

# 1. Cargar datos históricos (revenue mensual confirmado)
df = spark.sql("""
  SELECT
    DATE_TRUNC('month', tiempo_id) AS ds,
    SUM(total_amount)              AS y
  FROM gold.gold_fact_reservas
  WHERE booking_status = 'confirmed'
  GROUP BY DATE_TRUNC('month', tiempo_id)
""").toPandas()

# 2. Entrenar Prophet
modelo = Prophet(yearly_seasonality=True, interval_width=0.80)
modelo.fit(df)

# 3. Predecir 6 meses
futuro = modelo.make_future_dataframe(periods=6, freq='MS')
prediccion = modelo.predict(futuro)

# 4. Guardar en Gold
spark.createDataFrame(prediccion).write \
     .format("delta") \
     .mode("overwrite") \
     .saveAsTable("gold.gold_revenue_forecast")
```

### 11.2 Resultados del modelo

El modelo entrega tres outputs:

- `revenue_predicho`: valor central estimado
- `limite_inferior`: escenario pesimista (intervalo 80%)
- `limite_superior`: escenario optimista (intervalo 80%)

### 11.3 Justificación de Prophet sobre AutoML

| Aspecto | Prophet | AutoML |
|---|---|---|
| Líneas de código | ~25 | ~100+ |
| Configuración de cluster ML | No requiere | Requiere |
| Estacionalidad automática | ✅ | Requiere config |
| Tiempo de entrenamiento | < 1 min | 5-30 min |
| Robustez con pocos datos | Alta | Media |
| Industria | Facebook, Uber, Airbnb | Variado |

Para una serie temporal con estacionalidad clara (turismo), Prophet supera a AutoML en simplicidad y robustez.

---

## 12. Orquestación con Databricks Workflows

### 12.1 Notebook orquestador

El notebook `09_workflow_demo.ipynb` ejecuta el pipeline end-to-end en una sola ejecución:

```
PASO 1 — Notebook 06 (streaming) → inserta 155 eventos en Bronze
PASO 2 — Notebook 08 (dbt)       → procesa Silver + Gold + tests
PASO 3 — Power BI refresh        → KPIs actualizados
```

### 12.2 Databricks Job formal

Para producción se documenta la configuración del Job formal en `documentation/databricks_workflow.md`:

- **Task 1**: `01_streaming_ingestion` (notebook 06)
- **Task 2**: `02_dbt_silver_and_gold` (notebook 08) — depends_on Task 1
- **Schedule**: configurable (cada hora, día, etc.)
- **Notifications**: email al completarse

---

## 13. Calidad de datos y observabilidad

### 13.1 Validaciones implementadas

| Capa | Validaciones |
|---|---|
| **Bronze (notebook 03)** | Función `analizar_calidad()` con conteo de nulos, duplicados, cardinalidad, valores negativos |
| **Silver (dbt)** | 30+ tests automatizados (`not_null`, `unique`, `accepted_values`, `relationships`) |
| **Gold (dbt + Dashboard 3)** | Tests de integridad referencial + dashboard de monitoreo |

### 13.2 Métricas de observabilidad

El Dashboard 3 monitorea continuamente:

- **% Retención Bronze → Silver** por entidad
- **Anomalías financieras**: reservas sin pago, montos > $5000, estancias > 30 noches
- **Frescura de datos**: última fecha de actualización
- **Cobertura temporal**: días entre primera y última reserva
- **Registros filtrados**: cantidad de datos sucios eliminados por dbt

---

## 14. Decisiones de diseño defendibles

A lo largo del proyecto se tomaron decisiones técnicas significativas, todas documentadas y defendibles:

| Decisión | Justificación |
|---|---|
| **dbt para Silver/Gold** | Cumple sección 3.3 del PDF · Tests automáticos · Linaje documentado |
| **GMV vs Revenue separados** | Estándar industria (Airbnb, Booking) · Comunica magnitud real |
| **Inserción directa en `bronze_<entidad>`** | "Una entidad = una tabla" · Patrón Snowflake/Iceberg moderno |
| **Schema alignment dinámico** | Compatible con Serverless (no usa `.rdd`) · A prueba de cambios de tipo |
| **Trigger.AvailableNow** | Cluster Serverless no soporta `processingTime` |
| **Unity Catalog Volumes** | DBFS público deshabilitado · UC Volumes es el reemplazo gobernado |
| **Prophet sobre AutoML** | Menos código · Mejor para series con estacionalidad |
| **DirectQuery en Power BI** | Datos siempre frescos · No requiere refrescos manuales |
| **No usar matriz de cohortes** | Saturada visualmente · Sustituida por visualizaciones más simples |

---

## 15. Metodología de trabajo en equipo

### 15.1 Distribución de roles

| Integrante | Rol | Notebooks principales |
|---|---|---|
| **Oswaldo Rojano Mora** | Arquitecto + BI | 04, 05, 07, dashboards |
| **Juan Fernando Florez** | Data Engineer | 02, 03, 06 |
| **Kristian Charris** | Analytics Engineer | dbt completo, 08 |

### 15.2 Flujo de trabajo (Feature Branch Workflow)

```
1. git checkout main && git pull
2. git checkout -b feature/<descripcion>
3. (trabajar en notebooks/modelos)
4. git add . && git commit -m "feat: ..."
5. git push origin feature/<descripcion>
6. Crear Pull Request en GitHub
7. Review → Approve → Merge a main
8. Pull en Databricks Repos
```

### 15.3 Convenciones del equipo

- **Nunca** trabajar directamente sobre `main`.
- Cada integrante con su propio Git folder en Databricks Repos.
- Commits pequeños con mensajes descriptivos.
- Idempotencia con `CREATE OR REPLACE TABLE` en Silver y Gold.

---

## 16. Resultados obtenidos

### 16.1 Métricas cuantitativas

| Métrica | Valor |
|---|---|
| Notebooks creados | 10 |
| Modelos dbt (Silver + Gold) | 11 |
| Tests dbt implementados | 30+ |
| Tablas Delta finales | 17 (6 Bronze + 6 Silver + 5 Gold) |
| Vistas analíticas | 8 |
| Dashboards Power BI | 3 |
| Eventos sintéticos simulados | 155 por ejecución |
| Pull Requests mergeados | 20+ |

### 16.2 Cumplimiento de la guía oficial

| Requisito (PDF sección) | Estado |
|---|---|
| 3.1 — Apache Kafka simulado | ✅ (Spark Structured Streaming) |
| 3.2 — Bronze + Delta Lake | ✅ |
| 3.3 — Silver con dbt + tests | ✅ |
| 3.4 — Gold + Star Schema | ✅ |
| 3.4 — Unity Catalog | ✅ (Volumes) |
| 3.5 — Power BI + 3 dashboards | ✅ |
| 8.0 — Buenas prácticas Git | ✅ |
| 8.0 — Sin credenciales hardcodeadas | ✅ |

### 16.3 Extras implementados

- ⭐ Forecasting con Prophet (Machine Learning)
- ⭐ Notebook ejecutor de dbt desde Databricks
- ⭐ Workflow orquestado end-to-end
- ⭐ 8 vistas analíticas especializadas
- ⭐ Diagramas Mermaid renderizables en GitHub
- ⭐ Helper `align_to_target()` para compatibilidad Serverless

---

## 17. Conclusiones

1. **La arquitectura Lakehouse es viable y eficiente** para proyectos de BI de complejidad media-alta, combinando virtudes del Data Lake (escalabilidad, costo) con las del Data Warehouse (transaccionalidad, performance SQL).

2. **dbt es una herramienta indispensable** para garantizar la calidad y trazabilidad de las transformaciones. Los 30+ tests implementados detectan automáticamente regresiones de datos, integridad referencial y valores fuera de rango.

3. **La separación GMV vs Revenue** fue uno de los hallazgos más valiosos del proyecto: el dashboard ejecutivo mostraba inicialmente $40M en "ingresos totales" cuando el revenue real era de $9.91M. Identificar esta diferencia es exactamente el tipo de insight que un dashboard profesional debe entregar.

4. **El pipeline end-to-end demostrable en 5 minutos** (notebook 09) es la prueba más contundente del cumplimiento de la sección 5 de la guía. El dato recorre todas las capas de forma observable.

5. **Machine Learning agregó valor diferencial**: pasar de descriptive a predictive analytics con apenas 25 líneas de código demuestra que el Lakehouse no es solo para reportes históricos.

6. **La metodología Feature Branch funciona en equipos pequeños**: los 20+ PRs mergeados a `main` durante el desarrollo evitaron conflictos y permitieron desarrollo paralelo.

---

## 18. Recomendaciones para producción

Si este proyecto pasara a producción real, las mejoras serían:

1. **Reemplazar productor sintético por Kafka real** (Confluent Cloud con tier pago).
2. **Migrar a Databricks Asset Bundles** para deploy declarativo del Workflow.
3. **Implementar dbt Cloud** para CI/CD automático con cada PR.
4. **Configurar alertas** en Power BI que disparen ante KPIs anómalos.
5. **Implementar Delta Live Tables (DLT)** para pipelines declarativos.
6. **Agregar Great Expectations** como complemento a los tests dbt.
7. **Particionar tablas Delta por fecha** cuando el volumen supere ~10M filas.
8. **Usar Databricks Secrets** para todas las credenciales.

---

## 19. Referencias

### 19.1 Bibliografía técnica

- Armbrust, M., Ghodsi, A., Xin, R., & Zaharia, M. (2020). *Lakehouse: A New Generation of Open Platforms that Unify Data Warehousing and Advanced Analytics*. CIDR 2021.
- Kimball, R., & Ross, M. (2013). *The Data Warehouse Toolkit: The Definitive Guide to Dimensional Modeling* (3rd ed.). Wiley.
- Taylor, S. J., & Letham, B. (2017). *Forecasting at Scale*. The American Statistician.

### 19.2 Documentación oficial

- Databricks. (2024). *Delta Lake Documentation*. https://docs.delta.io/
- dbt Labs. (2024). *dbt Documentation*. https://docs.getdbt.com/
- Meta. (2024). *Prophet: Forecasting at Scale*. https://facebook.github.io/prophet/
- Microsoft. (2024). *Power BI Documentation*. https://learn.microsoft.com/power-bi/

### 19.3 Recursos del proyecto

- **Repositorio GitHub**: https://github.com/ktncharris018/wanderbricks-lakehouse-project
- **Dataset utilizado**: `samples.wanderbricks` (Databricks public samples)
- **Guía oficial del proyecto**: PDF entregado por el docente

---

## Anexos

### Anexo A — Comandos útiles

**Pipeline completo end-to-end** (desde notebook orquestador):

```bash
# En Databricks
1. Abrir notebook 09_workflow_demo.ipynb
2. Click "Run all"
3. Esperar ~3-5 minutos
4. Refrescar Power BI manualmente
```

**Ejecutar dbt manualmente desde terminal local**:

```bash
cd dbt/
dbt debug                          # Verificar conexión
dbt run --select silver            # Construir Silver
dbt run --select gold              # Construir Gold
dbt test                           # Ejecutar tests
dbt docs generate && dbt docs serve  # Linaje
```

### Anexo B — Convención de nombres

| Tipo | Patrón | Ejemplo |
|---|---|---|
| Schema | minúsculas | `bronze`, `silver`, `gold` |
| Tabla Bronze | `bronze_<entidad>` | `bronze_bookings` |
| Tabla Silver | `silver_<entidad>` | `silver_users` |
| Fact Gold | `gold_fact_<entidad>` | `gold_fact_reservas` |
| Dim Gold | `gold_dim_<entidad>` | `gold_dim_time` |
| Vista analítica | `vw_<concepto>` | `vw_executive_kpis` |
| Notebook | `NN_<descripcion>` | `04_silver_layer` |
| Rama Git | `feature/<descripcion-corta>` | `feature/gmv-revenue-split` |

---

**Firmado digitalmente por el equipo:**

| | | |
|---|---|---|
| **Oswaldo Rojano Mora** | **Juan Fernando Florez** | **Kristian Charris** |
| Arquitecto · BI Developer | Data Engineer | Analytics Engineer |

---

*Universidad Popular del Cesar · Facultad de Ingenierías · Bases de Datos Avanzada 2026-I*
