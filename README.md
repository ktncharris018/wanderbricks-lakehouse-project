# 🏛️ Wanderbricks Lakehouse Project

> **Proyecto Final** · Bases de Datos Avanzada (2026-I)
> **Universidad Popular del Cesar** · Facultad de Ingenierías
> **Docente:** Ing. Amilkar Sierra Romano

---

## 👥 Equipo

| Integrante | Rol principal |
|---|---|
| **Oswaldo Rojano Mora** | Arquitectura · Modelado Dimensional · BI Developer |
| **Juan Fernando Florez** | Data Engineer · Ingesta · Streaming |
| **Kristian Charris** | Analytics Engineer · dbt · Calidad de Datos |

---

## 📋 Resumen ejecutivo

**Wanderbricks** es un pipeline de **Business Intelligence end-to-end** sobre la plataforma **Databricks**, implementando la **arquitectura Medallion** (Bronze → Silver → Gold) sobre el dataset público `samples.wanderbricks` — una plataforma global de reservas de alojamiento turístico análoga a Airbnb / Booking.

El proyecto cubre desde la **ingesta event-driven en tiempo real** hasta la **predicción de revenue con Machine Learning**, integrando:

- **Apache Spark** para procesamiento distribuido
- **Delta Lake** como formato de almacenamiento transaccional
- **dbt Core + dbt-databricks** para transformaciones declarativas con tests automáticos
- **Spark Structured Streaming** para ingesta de eventos
- **3 Dashboards en Power BI** conectados vía DirectQuery
- **Prophet (Meta AI)** para forecasting predictivo de revenue
- **Databricks Workflows** para orquestación end-to-end
- **GitHub + Databricks Repos** con flujo Feature Branch + Pull Requests

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                       FUENTES DE DATOS                          │
│   samples.wanderbricks (batch inicial) + eventos sintéticos     │
└──────────────────────────┬──────────────────────────────────────┘
                           ▼
            ┌──────────────────────────────┐
            │  🟫  BRONZE LAYER (Delta)    │
            │  bronze_users, bookings,     │
            │  properties, destinations,   │
            │  payments, reviews           │
            └──────────────┬───────────────┘
                           │ dbt run --select silver
                           ▼
            ┌──────────────────────────────┐
            │  ⬜  SILVER LAYER (Delta)    │
            │  Limpieza · Dedup · Cast ·   │
            │  TRIM · Reglas de negocio    │
            └──────────────┬───────────────┘
                           │ dbt run --select gold
                           ▼
            ┌──────────────────────────────┐
            │  🟡  GOLD LAYER — Star Schema│
            │  1 fact + 4 dims + 8 vistas  │
            │  + tabla de forecast (IA)    │
            └──────────────┬───────────────┘
                           ▼
            ┌──────────────────────────────┐
            │  📊  POWER BI · DirectQuery  │
            │  3 dashboards interactivos   │
            └──────────────────────────────┘
```

**Detalles completos**: [`documentation/arquitectura.md`](documentation/arquitectura.md)

---

## 📁 Estructura del repositorio

```
wanderbricks-lakehouse-project/
│
├── 📓 NOTEBOOKS DE DATABRICKS
│   ├── 01_exploracion_dataset.ipynb       Exploración inicial
│   ├── 02_bronze_layer.ipynb              Ingesta cruda a Delta
│   ├── 03_data_quality_analysis.ipynb     Validaciones automatizadas
│   ├── 04_silver_layer.ipynb              Silver con SQL (respaldo)
│   ├── 05_gold_layer.ipynb                Gold Star Schema (respaldo)
│   ├── 06_streaming_pipeline.ipynb        Ingesta event-driven 6 entidades
│   ├── 07_powerbi.ipynb                   Vistas analíticas para BI
│   ├── 08_run_dbt.ipynb                   Ejecutor dbt dentro de Databricks
│   ├── 09_workflow_demo.ipynb             Orquestador end-to-end
│   └── 10_ai_prediction.ipynb             🤖 Forecasting con Prophet
│
├── 🔧 DBT PROJECT (transformaciones declarativas)
│   ├── dbt_project.yml
│   ├── profiles.example.yml
│   └── models/
│       ├── sources.yml                    Define Bronze como fuente
│       ├── silver/                        6 modelos + tests
│       │   ├── silver_*.sql
│       │   └── schema.yml                 not_null · unique · accepted_values · relationships
│       └── gold/                          5 modelos + exposures
│           ├── gold_dim_*.sql
│           ├── gold_fact_reservas.sql
│           ├── schema.yml
│           └── exposures.yml              Vincula dashboards a modelos
│
├── 🎨 DIAGRAMAS (Mermaid renderizables en GitHub)
│   ├── conceptual_model.md                ER del negocio
│   └── star_schema.md                     Modelo dimensional Gold
│
├── 📚 DOCUMENTACIÓN
│   ├── arquitectura.md                    Arquitectura técnica completa
│   ├── dashboards_powerbi.md              Guía visual por dashboard
│   └── databricks_workflow.md             Orquestación con Jobs
│
├── 🎯 INFORME FINAL
│   └── INFORME_FINAL.md                   Documento académico entregable
│
└── README.md                              Este archivo
```

---

## 🚀 Cómo ejecutar el proyecto

### Prerrequisitos

- Workspace de **Databricks** (Free Edition / Serverless es suficiente)
- **Power BI Desktop** instalado (gratis)
- Repo clonado en **Databricks Repos** vía GitHub

### Orden de ejecución

| # | Notebook | Tiempo | Acción |
|---|---|---|---|
| 1 | `01_exploracion_dataset` | 1 min | Explorar dataset |
| 2 | `02_bronze_layer` | 2 min | Crear 6 tablas Bronze |
| 3 | `03_data_quality_analysis` | 3 min | Validar calidad |
| 4 | `06_streaming_pipeline` | 1 min | Simular eventos nuevos |
| 5 | `08_run_dbt` | 3 min | dbt build (Silver + Gold + tests) |
| 6 | `07_powerbi` | 1 min | Crear vistas analíticas |
| 7 | `10_ai_prediction` | 2 min | Generar forecast con Prophet |
| 8 | Power BI | manual | Conectar vía DirectQuery |

**Tiempo total**: ~15 minutos para el pipeline completo end-to-end.

### Demo en vivo (sustentación)

Para la demostración del flujo Bronze → Silver → Gold → Dashboard:

1. Ejecutar `09_workflow_demo.ipynb` → corre los notebooks 06 + 08 en cadena automáticamente.
2. Refrescar Power BI → los dashboards reflejan los nuevos eventos.

**Tiempo de demo**: ~3-5 minutos.

---

## 🛠️ Stack técnico

| Capa | Tecnología | Función |
|---|---|---|
| **Almacenamiento** | Delta Lake | Formato transaccional sobre Parquet |
| **Procesamiento** | Apache Spark + PySpark | Motor distribuido |
| **Streaming** | Spark Structured Streaming | Ingesta event-driven |
| **Transformación** | dbt Core + dbt-databricks | SQL declarativo + tests |
| **Orquestación** | Databricks Workflows | Jobs con DAG visual |
| **BI** | Power BI Desktop + DirectQuery | 3 dashboards interactivos |
| **ML** | Prophet (Meta) | Forecasting series temporales |
| **Gobernanza** | Unity Catalog (Volumes) | Storage gobernado |
| **Versionado** | GitHub + Databricks Repos | Feature branches + PRs |

---

## 📊 Resultados

### Modelos de datos creados

- **6 tablas Bronze** (datos crudos inmutables)
- **6 tablas Silver** (limpios, deduplicados, tipificados)
- **5 tablas Gold** (Star Schema: 1 fact + 4 dimensiones)
- **8 vistas analíticas** especializadas
- **30+ tests de calidad** automáticos en dbt
- **1 modelo ML** de forecasting (Prophet)

### Dashboards Power BI

| # | Dashboard | Foco |
|---|---|---|
| 1 | **Executive Overview** | KPIs financieros, GMV vs Revenue, distribución global |
| 2 | **Customer Analytics** | Segmentación RFM, LTV, comportamiento de clientes |
| 3 | **Pipeline & Data Quality** | Salud del pipeline, anomalías, observabilidad |

---

## 📖 Documentos clave

- 📋 **[INFORME FINAL DEL PROYECTO](INFORME_FINAL.md)** — documento académico completo
- 🏗️ [Arquitectura técnica](documentation/arquitectura.md)
- 🎨 [Guía de dashboards Power BI](documentation/dashboards_powerbi.md)
- 🔄 [Orquestación con Databricks Workflows](documentation/databricks_workflow.md)
- 📐 [Modelo conceptual](diagrams/conceptual_model.md)
- ⭐ [Star Schema](diagrams/star_schema.md)
- 🔧 [README de dbt](dbt/README.md)

---

## 🎤 Defensa rápida (elevator pitch)

> *"Implementamos una arquitectura **Lakehouse Medallion** sobre Databricks con dbt como capa de transformación declarativa, demostrando el flujo end-to-end desde la ingesta event-driven en tiempo real hasta la predicción de revenue con Machine Learning. El pipeline procesa 6 entidades de negocio (reservas, usuarios, propiedades, destinos, pagos, reseñas), las transforma vía 11 modelos dbt con 30+ tests automáticos, y entrega un Star Schema dimensional consumido por 3 dashboards en Power BI vía DirectQuery. Complementamos con forecasting predictivo usando Prophet de Meta, pasando de descriptive a predictive analytics."*

---

## 🏆 Cumplimiento de la guía oficial

| Requisito del PDF | Estado |
|---|---|
| Arquitectura Medallion (Bronze→Silver→Gold) | ✅ |
| Apache Spark / PySpark | ✅ |
| Delta Lake | ✅ |
| Spark Structured Streaming | ✅ |
| dbt Core + dbt-databricks | ✅ |
| Tests dbt (not_null, unique, accepted_values, relationships) | ✅ (30+ tests) |
| schema.yml para linaje | ✅ |
| dbt Exposures | ✅ |
| Modelo dimensional Star Schema | ✅ |
| Unity Catalog | ✅ (Volumes) |
| Power BI conectado al SQL Warehouse | ✅ (DirectQuery) |
| Mínimo 3 dashboards | ✅ (Executive, Customer, Data Quality) |
| GitHub + Databricks Repos | ✅ |
| Feature Branch Workflow | ✅ |

**Extras implementados** (más allá de la guía):
- ⭐ Machine Learning con Prophet (forecasting)
- ⭐ Workflow orquestado end-to-end con Databricks Jobs
- ⭐ Linaje automático con `dbt docs generate`
- ⭐ Notebook ejecutor de dbt desde Databricks (sin instalación local)

---

## 📝 Licencia

Proyecto académico — Universidad Popular del Cesar · 2026.

---

**Wanderbricks Lakehouse Project** · Construido con ☕ por Oswaldo, Juan Fernando y Kristian.
