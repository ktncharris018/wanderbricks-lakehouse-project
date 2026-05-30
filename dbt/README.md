# Proyecto dbt — Wanderbricks

Implementación de la capa de transformación con **dbt Core + dbt-databricks**,
cumpliendo la sección 3.3 del PDF oficial del proyecto.

## ¿Por qué dbt si los notebooks ya construyen las tablas?

Los notebooks `04_silver_layer.ipynb` y `05_gold_layer.ipynb` son la implementación
ejecutiva del pipeline. Este proyecto dbt es la **capa declarativa equivalente**
que aporta lo que los notebooks por sí solos no pueden:

| Capacidad | Notebooks | dbt |
|---|---|---|
| Construye tablas Silver y Gold | ✅ | ✅ |
| Versionado en Git | ✅ | ✅ |
| Tests automáticos `not_null`, `unique`, `accepted_values`, `relationships` | ❌ | ✅ |
| Linaje de datos visual (`dbt docs`) | ❌ | ✅ |
| Documentación inline de modelos y columnas | parcial | ✅ |
| `dbt Exposures` para vincular modelos a dashboards | ❌ | ✅ |
| Ejecución incremental | ❌ | ✅ (con materialización `incremental`) |

En producción, el equipo de datos usa **Databricks para el cómputo** y
**dbt para versionado, tests y linaje** — exactamente lo que demuestra este proyecto.

## Estructura

```
dbt/
├── dbt_project.yml              Configuración general del proyecto
├── profiles.example.yml         Plantilla de credenciales (copia a ~/.dbt/profiles.yml)
├── .gitignore                   Excluye profiles.yml real, target/, logs/
├── README.md                    Este archivo
└── models/
    ├── sources.yml              Define las tablas bronze como fuentes
    ├── silver/                  Modelos Silver (limpieza, dedupe, cast)
    │   ├── silver_users.sql
    │   ├── silver_destinations.sql
    │   ├── silver_properties.sql
    │   ├── silver_bookings.sql
    │   ├── silver_payments.sql
    │   ├── silver_reviews.sql
    │   └── schema.yml           Tests y documentación de Silver
    └── gold/                    Modelos Gold (Star Schema)
        ├── gold_dim_users.sql
        ├── gold_dim_properties.sql
        ├── gold_dim_destinations.sql
        ├── gold_dim_time.sql
        ├── gold_fact_reservas.sql
        ├── schema.yml           Tests y documentación de Gold
        └── exposures.yml        Vincula modelos a dashboards Power BI
```

## Setup

### 1. Instalar dbt + el conector de Databricks

```bash
pip install dbt-core dbt-databricks
```

Verifica:

```bash
dbt --version
```

### 2. Configurar las credenciales de conexión

```bash
# Linux / Mac
cp profiles.example.yml ~/.dbt/profiles.yml

# Windows (PowerShell)
Copy-Item profiles.example.yml $env:USERPROFILE\.dbt\profiles.yml
```

Edita el archivo y rellena los 3 valores marcados con `< ... >`:

- `host` — Server hostname del SQL Warehouse
- `http_path` — HTTP Path del SQL Warehouse
- `token` — Personal Access Token (PAT) de Databricks

> Los 3 valores se obtienen en Databricks: SQL Warehouses → tu warehouse → Connection details.

### 3. Verificar la conexión

```bash
cd dbt/
dbt debug
```

Debe responder `All checks passed!`.

## Ejecución

### Construir todos los modelos

```bash
dbt run
```

Esto construye en orden: Silver → Gold, ejecutando cada `SELECT` contra el SQL
Warehouse y materializando como tabla Delta en el catálogo correspondiente.

### Construir solo una capa

```bash
dbt run --select silver        # solo modelos Silver
dbt run --select gold          # solo modelos Gold
dbt run --select silver_users  # solo un modelo
```

### Ejecutar los tests

```bash
dbt test                       # todos los tests
dbt test --select silver       # solo tests de Silver
dbt test --select gold_fact_reservas  # solo tests de la fact
```

Los tests definidos en `schema.yml` validan:

- **`not_null`** sobre PKs y FKs críticas
- **`unique`** sobre PKs (`user_id`, `property_id`, `booking_id`, etc.)
- **`accepted_values`** sobre campos enumerados (`booking_status`, `payment_method`)
- **`relationships`** para validar integridad referencial entre dim y fact

### Generar el linaje y la documentación

```bash
dbt docs generate
dbt docs serve
```

Abre automáticamente `http://localhost:8080` con un portal que muestra:

- Diagrama de linaje **bronze → silver → gold** generado automáticamente
- Descripción de cada modelo y cada columna
- Tests aplicados a cada columna
- SQL compilado vs SQL original
- Exposures (qué dashboards consumen cada modelo)

## Decisiones de diseño

- **Materialización `table`** en todas las capas: las tablas se reconstruyen
  completas en cada `dbt run`. Es la opción más simple y suficiente para el
  volumen del dataset.
- **Formato Delta Lake**: garantiza ACID, time travel y compatibilidad con
  Spark Structured Streaming.
- **Schemas separados**: `silver/` y `gold/` viven en schemas distintos, alineado
  con la convención del PDF oficial (sección 8).
- **Fuentes (`sources.yml`)**: las tablas Bronze se referencian con `{{ source(...) }}`
  para que dbt resuelva el linaje completo desde la ingesta.
- **Surrogate keys**: las dimensiones Gold exponen `*_key` además del PK natural
  para flexibilidad futura de SCD Type 2.

## Relación con los notebooks

| Notebook | Equivalente dbt |
|---|---|
| `04_silver_layer.ipynb` | `models/silver/*.sql` + tests en `silver/schema.yml` |
| `05_gold_layer.ipynb` | `models/gold/*.sql` + tests en `gold/schema.yml` |

Los notebooks ejecutan el SQL directamente en Databricks. Los modelos dbt
ejecutan el mismo SQL pero vía el conector dbt-databricks, con la ventaja del
framework alrededor (tests, docs, linaje, exposures).
