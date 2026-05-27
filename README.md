# Wanderbricks Lakehouse Project

> Proyecto final de **Bases de Datos Avanzada (2026-I)**
> Universidad Popular del Cesar — Ing. Amilkar Sierra Romano

Pipeline de Business Intelligence end-to-end sobre **Databricks**, implementando la **arquitectura Medallion** (Bronze → Silver → Gold) sobre el dataset público `samples.wanderbricks` (plataforma de reservas de alojamiento turístico).

## Arquitectura

```
Kafka / Batch  →  Bronze  →  Silver  →  Gold (Star Schema)  →  Power BI
                  Delta      Delta      Delta + SQL Warehouse
```

Documentación detallada: [`documentation/arquitectura.md`](documentation/arquitectura.md)

## Estructura del repositorio

```
wanderbricks-lakehouse-project/
├── 01_exploracion_dataset.ipynb       Exploración inicial del dataset
├── 02_bronze_layer.ipynb              Ingesta cruda en Delta Lake
├── 03_data_quality_analysis.ipynb     Validaciones automatizadas sobre Bronze
├── 04_silver_layer.ipynb              Limpieza, casteo y deduplicación
├── 05_gold_layer.ipynb                Star Schema dimensional
├── 06_streaming_pipeline.ipynb        Ingesta streaming desde Kafka
├── 07_powerbi.ipynb                   Conexión y dashboards Power BI
│
├── diagrams/
│   ├── conceptual_model.md            Modelo conceptual (Mermaid)
│   └── star_schema.md                 Star Schema de la capa Gold (Mermaid)
│
├── documentation/
│   └── arquitectura.md                Documento de arquitectura completo
│
└── README.md
```

## Capas del Lakehouse

### Bronze — datos crudos

Copia 1:1 de las tablas de `samples.wanderbricks`, almacenada en Delta Lake bajo el schema `bronze`. Inmutable, sirve como fuente de verdad histórica.

**Tablas**: `bronze_bookings`, `bronze_users`, `bronze_payments`, `bronze_properties`, `bronze_reviews`, `bronze_destinations`.

### Silver — datos limpios

Transformaciones aplicadas:

- Deduplicación por PK (versión más reciente).
- Casteo a tipos correctos (`DATE`, `TIMESTAMP`, `DECIMAL`, `BIGINT`, `BOOLEAN`).
- `TRIM` de strings.
- Filtros de validez: `total_amount > 0`, `check_out > check_in`, `rating BETWEEN 0 AND 5`, etc.
- Columna derivada `total_nights` en `silver_bookings`.

**Tablas**: `silver_users`, `silver_destinations`, `silver_properties`, `silver_bookings`, `silver_payments`, `silver_reviews`.

### Gold — Star Schema

Modelo dimensional listo para Power BI. Una **tabla de hechos** (`gold_fact_reservas`) con grano de reserva, y **cuatro dimensiones** (`gold_dim_users`, `gold_dim_properties`, `gold_dim_destinations`, `gold_dim_time`).

Diagrama: [`diagrams/star_schema.md`](diagrams/star_schema.md)

## Cómo ejecutar el pipeline

### Prerrequisitos

- Workspace de **Databricks** (Free / Community / Workspace pago).
- Repo conectado a Databricks Repos.
- Para el notebook 06: cuenta en **Confluent Cloud** (tier gratuito).
- Para el notebook 07: **Power BI Desktop** instalado localmente.

### Orden de ejecución

Desde Databricks Repos, en cada notebook hacer **"Run all"** en este orden:

1. `01_exploracion_dataset`
2. `02_bronze_layer`
3. `03_data_quality_analysis`
4. `04_silver_layer`
5. `05_gold_layer`
6. `06_streaming_pipeline` *(opcional, requiere Kafka)*
7. `07_powerbi` *(instrucciones de conexión)*

Los notebooks 04 y 05 usan `CREATE OR REPLACE TABLE` → son **idempotentes** y se pueden re-ejecutar sin error.

## Metodología de trabajo

Feature Branch Workflow con responsabilidades divididas:

| Rol | Notebooks | Rama |
|---|---|---|
| Arquitectura + Silver + Gold | 04, 05 | `feature/silver-gold` |
| Streaming + Kafka | 06 | `feature/kafka-streaming` |
| Power BI + Documentación | 07 | `feature/powerbi` |

Reglas:

- **Nunca** trabajar directamente sobre `main`.
- Cada integrante tiene su propio Git folder en Databricks Repos.
- Commits pequeños con mensajes descriptivos.
- Cambios a `main` siempre vía Pull Request.

## Stack técnico

| Componente | Rol |
|---|---|
| **Databricks** | Plataforma central (compute + storage + analytics) |
| **Delta Lake** | Formato de almacenamiento transaccional |
| **Apache Spark / PySpark** | Procesamiento distribuido |
| **Spark Structured Streaming** | Ingesta en tiempo real |
| **Apache Kafka (Confluent Cloud)** | Bus de eventos |
| **Databricks SQL Warehouse** | Motor de consulta para BI |
| **Power BI Desktop** | Visualización ejecutiva |
| **GitHub + Databricks Repos** | Control de versiones colaborativo |
