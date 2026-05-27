# Documento de Arquitectura — Wanderbricks Lakehouse

> Proyecto final de Bases de Datos Avanzada (2026-I)
> Universidad Popular del Cesar — Ing. Amilkar Sierra Romano

## 1. Visión general

El proyecto implementa un **pipeline de Business Intelligence en tiempo real** sobre la plataforma **Databricks**, siguiendo la **arquitectura Medallion** (Bronze → Silver → Gold) y aplicado al dataset público `samples.wanderbricks` (plataforma global de reservas de alojamiento, análoga a Airbnb / Booking).

El objetivo es construir, desde la ingesta de datos crudos hasta los dashboards ejecutivos, una solución analítica completa que responda preguntas de negocio sobre ingresos, ocupación, desempeño de propiedades y comportamiento de usuarios.

## 2. Diagrama de arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FUENTES DE DATOS                                  │
│  samples.wanderbricks (batch)     │     Apache Kafka (streaming)    │
└────────────────┬────────────────────────────────┬───────────────────┘
                 │                                │
                 ▼                                ▼
        ┌──────────────────────────────────────────────┐
        │           BRONZE LAYER (Delta Lake)          │
        │  bronze_bookings, bronze_users,              │
        │  bronze_payments, bronze_properties,         │
        │  bronze_reviews, bronze_destinations         │
        │  → Datos crudos, sin transformación          │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼
        ┌──────────────────────────────────────────────┐
        │      DATA QUALITY (PySpark)                  │
        │  Validación de nulos, duplicados,            │
        │  cardinalidad, valores negativos             │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼
        ┌──────────────────────────────────────────────┐
        │           SILVER LAYER (Delta Lake)          │
        │  silver_*: deduplicado, tipado, limpio       │
        │  Reglas de negocio aplicadas                 │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼
        ┌──────────────────────────────────────────────┐
        │           GOLD LAYER — Star Schema           │
        │  gold_fact_reservas                          │
        │  gold_dim_users, gold_dim_properties,        │
        │  gold_dim_destinations, gold_dim_time        │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼
        ┌──────────────────────────────────────────────┐
        │      DATABRICKS SQL WAREHOUSE                │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼
        ┌──────────────────────────────────────────────┐
        │      POWER BI / TABLEAU                      │
        │  Dashboard ejecutivo, operacional, calidad   │
        └──────────────────────────────────────────────┘
```

## 3. Capas de la arquitectura

### 3.1 Bronze — Ingesta cruda

| Aspecto | Decisión |
|---|---|
| **Formato** | Delta Lake (tablas `bronze.bronze_*`) |
| **Origen batch** | `samples.wanderbricks` (catálogo Databricks) |
| **Origen streaming** | Apache Kafka simulado vía Confluent Cloud |
| **Transformación** | Ninguna — copia 1:1 |
| **Inmutabilidad** | Las tablas Bronze son la fuente de verdad histórica |

**Justificación**: separar la ingesta de la transformación permite reprocesar Silver/Gold sin volver a leer las fuentes originales.

### 3.2 Silver — Limpieza y normalización

| Regla | Implementación |
|---|---|
| Deduplicación | `ROW_NUMBER() OVER (PARTITION BY pk ORDER BY updated_at DESC)` |
| Casteo de tipos | `CAST(... AS DATE / TIMESTAMP / DECIMAL / BIGINT / BOOLEAN)` |
| Estandarización de strings | `TRIM(...)` en todas las columnas de texto |
| Validez de fechas | `check_out > check_in` |
| Validez de montos | `total_amount > 0`, `amount > 0` |
| Validez de ratings | `rating BETWEEN 0 AND 5`, `is_deleted = false` |
| Filtro de PK nula | `WHERE pk IS NOT NULL` |

**Tablas producidas**: `silver_users`, `silver_destinations`, `silver_properties`, `silver_bookings` (con `total_nights` derivado), `silver_payments`, `silver_reviews`.

### 3.3 Gold — Modelo dimensional

Se implementa un **Star Schema** clásico (ver [diagrams/star_schema.md](../diagrams/star_schema.md)) con una tabla de hechos y cuatro dimensiones:

- **Fact**: `gold_fact_reservas` — grano: una fila por reserva.
- **Dims**: `gold_dim_users`, `gold_dim_properties`, `gold_dim_destinations`, `gold_dim_time`.

La dimensión de tiempo se genera dinámicamente con `SEQUENCE(MIN(check_in), MAX(check_out), INTERVAL 1 DAY)` para que el calendario se adapte al rango real de los datos.

## 4. Justificación tecnológica

| Tecnología | ¿Por qué se eligió? |
|---|---|
| **Databricks** | Plataforma unificada de procesamiento (Spark) + almacenamiento (Delta) + analítica (SQL Warehouse). Elimina la necesidad de mover datos entre sistemas. |
| **Delta Lake** | Combina la eficiencia de Parquet con transaccionalidad ACID, time travel y `MERGE` — todo lo que necesita un Lakehouse moderno. |
| **Apache Spark / PySpark** | Único motor que escala desde batch a streaming sin cambios de paradigma. |
| **Spark Structured Streaming** | Permite consumir Kafka en tiempo real con la misma API de DataFrames usada en batch. |
| **Apache Kafka (Confluent Cloud)** | Estándar de la industria para event streaming. El tier gratuito de Confluent Cloud cubre las necesidades del proyecto sin infraestructura local. |
| **SQL Warehouse** | Punto de conexión nativo para Power BI / Tableau sin tener que mantener un clúster Spark levantado. |
| **Power BI Desktop** | Conector nativo a Databricks, gratuito, ampliamente usado en la industria. |
| **GitHub + Databricks Repos** | Metodología feature-branch profesional. Cada integrante trabaja en su propia rama y propio Git folder para evitar conflictos. |

## 5. Modelado de datos

- **Modelo conceptual**: [diagrams/conceptual_model.md](../diagrams/conceptual_model.md)
- **Star Schema (Gold)**: [diagrams/star_schema.md](../diagrams/star_schema.md)

## 6. Calidad de datos

El notebook `03_data_quality_analysis.ipynb` implementa la función `analizar_calidad(tabla, columna_id)` en PySpark, que sobre cada tabla Bronze ejecuta:

- Conteo total de registros
- Validación de valores nulos (absolutos y porcentaje)
- Detección de strings vacíos
- Detección de duplicados por PK
- Estadísticas descriptivas de columnas numéricas
- Detección de valores negativos
- Cardinalidad y columnas constantes

Los hallazgos sirven como insumo para las reglas de limpieza aplicadas en Silver.

## 7. Gobernanza y convenciones

| Aspecto | Convención |
|---|---|
| Nombres de schemas | `bronze`, `silver`, `gold` |
| Nombres de tablas Bronze | `bronze_<entidad>` |
| Nombres de tablas Silver | `silver_<entidad>` |
| Nombres de tablas Gold | `gold_fact_<entidad>`, `gold_dim_<entidad>` |
| Notebooks | Numerados por fase (01–07) |
| Ramas Git | `feature/<descripción-corta>` |
| Commits | Mensajes en inglés, descriptivos, en commits pequeños |
| Idempotencia | `CREATE OR REPLACE TABLE` en Silver y Gold |

## 8. Metodología de trabajo

Se aplica **Feature Branch Workflow** con división de responsabilidades por notebook:

| Integrante | Notebooks |
|---|---|
| Arquitectura + Silver + Gold | `04_silver_layer`, `05_gold_layer` + documentación de arquitectura |
| Kafka + Streaming | `06_streaming_pipeline` |
| Power BI + documentación | `07_powerbi` + diagramas |

Cada integrante trabaja en su propia rama (`feature/silver-gold`, `feature/kafka-streaming`, `feature/powerbi`) y mergea a `main` vía Pull Request.

## 9. Cómo ejecutar el pipeline

Desde Databricks Repos, ejecutar los notebooks en este orden:

1. `01_exploracion_dataset` — exploración inicial del dataset.
2. `02_bronze_layer` — creación de schemas y carga de tablas Bronze.
3. `03_data_quality_analysis` — análisis de calidad sobre Bronze.
4. `04_silver_layer` — construcción de tablas Silver limpias.
5. `05_gold_layer` — construcción del Star Schema en Gold.
6. `06_streaming_pipeline` — ingesta streaming desde Kafka (opcional para demo).
7. `07_powerbi` — instrucciones de conexión y dashboards.

Los notebooks 04 y 05 son idempotentes (`CREATE OR REPLACE TABLE`), pueden re-ejecutarse sin efectos colaterales.
