# Databricks Workflow — Pipeline End-to-End

Este documento describe cómo configurar el **flujo automatizado** del proyecto
Wanderbricks como un **Databricks Job** programable, para demostrar la sección 5
de la guía: *"Demostración en vivo del flujo completo Bronze → Silver → Gold"*.

## Dos opciones de orquestación

| Opción | Cómo funciona | Uso |
|---|---|---|
| **A. Notebook orquestador (`09_workflow_demo`)** | Ejecuta 06 + 08 en secuencia con `dbutils.notebook.run()` | Demo manual (Run all) |
| **B. Databricks Job formal** | UI de Databricks orquesta tareas como DAG | Demo programada / producción |

Ambas son válidas. La **Opción B es más impactante** para la sustentación porque demuestra que sabes operar pipelines productivos.

---

## Opción A — Notebook orquestador (uso inmediato)

Ya está creado: `09_workflow_demo.ipynb`.

**Cómo usarlo**:
1. Abrir el notebook en Databricks.
2. **Run all**.
3. Espera 3-5 minutos.
4. Refrescar Power BI manualmente al final.

**Pros**: simple, no requiere configuración.
**Contras**: ejecución manual cada vez.

---

## Opción B — Databricks Job formal

Esta es la versión que se ve en empresas reales. El job ejecuta los notebooks
en orden, con dependencias, schedule y alertas.

### Paso 1 — Crear el Job en la UI de Databricks

1. Menú izquierdo → **Jobs & Pipelines** → botón **Create job**.
2. Nombre del job: `wanderbricks_e2e_pipeline`
3. Configurar la **primera tarea (task)**:
   - **Task name**: `01_streaming_ingestion`
   - **Type**: `Notebook`
   - **Source**: `Workspace`
   - **Path**: `/Workspace/Users/<tu_email>/wanderbricks-lakehouse-project/06_streaming_pipeline`
   - **Cluster**: `Serverless`
   - **Parameters**: (vacío)

4. Agregar segunda tarea con dependencia:
   - Botón **+ Add task** → seleccionar como **dependency** la tarea anterior
   - **Task name**: `02_dbt_silver_and_gold`
   - **Type**: `Notebook`
   - **Path**: `/Workspace/Users/<tu_email>/wanderbricks-lakehouse-project/08_run_dbt`
   - **Cluster**: `Serverless`
   - **Depends on**: `01_streaming_ingestion`

5. **Save**.

### Paso 2 — Resultado: DAG visual

El job se ve así (Databricks lo renderiza automáticamente):

```
┌──────────────────────────┐
│ 01_streaming_ingestion   │   ← inserta eventos en Bronze
│ (notebook 06)            │
└──────────────┬───────────┘
               │
               ▼
┌──────────────────────────┐
│ 02_dbt_silver_and_gold   │   ← dbt limpia Silver y construye Gold
│ (notebook 08)            │
└──────────────────────────┘
```

### Paso 3 — Configurar schedule (opcional)

Para que el job se ejecute automáticamente cada cierto tiempo:

1. En la página del job → **Add schedule** o **Schedules & Triggers**.
2. Opciones:
   - **Manual**: solo cuando le des Run.
   - **Continuous**: ejecuta siempre que termina (no recomendado para demo).
   - **Scheduled**: cron expression. Ejemplos:
     - Cada hora: `0 0 * * * ?`
     - Cada día a las 8am: `0 0 8 * * ?`
     - Cada lunes a las 9am: `0 0 9 ? * MON`
3. **Save**.

### Paso 4 — Configurar notificaciones (opcional)

1. **Edit notifications** en la página del job.
2. **Add notification** → email cuando:
   - El job comienza.
   - El job termina (éxito).
   - El job falla.
3. Agregar tu email → **Save**.

### Paso 5 — Ejecutar el Job en vivo

Para la demo:
1. En la página del job → botón **Run now**.
2. Te lleva a la página de la ejecución → vas viendo el DAG en vivo.
3. Cada tarea cambia de color: gris (pending) → azul (running) → verde (success).
4. Al finalizar, mostrar el panel de **Run details** con los tiempos y logs.

**Esto es muy impactante para el profesor** porque muestra orquestación
profesional, no solo "abrir un notebook y darle Run".

---

## Para la sustentación

### Narrativa recomendada

> *"Implementamos el pipeline end-to-end como un Databricks Job orquestado.
> El job tiene dos tareas con dependencia: la primera ingesta eventos sintéticos
> en las 6 tablas Bronze (notebook 06), y la segunda corre dbt para construir
> Silver y Gold (notebook 08). Ambas usan cluster Serverless. El job está
> programable con cron expressions — en producción correría cada hora para
> simular ingesta continua. La conexión con Power BI vía DirectQuery garantiza
> que los dashboards reflejan los datos en tiempo real sin necesidad de
> refrescos manuales."*

### Demo en vivo (5 minutos)

1. **Conteos iniciales** (1 min): mostrar `SELECT COUNT(*) FROM bronze.*` en una celda.
2. **Run del job** (3 min): clic en **Run now** del Databricks Job → mostrar DAG en vivo.
3. **Conteos finales** (30 seg): mostrar que crecieron.
4. **Power BI refresh** (30 seg): cambiar a Power BI → Refresh → KPIs suben.

---

## Decisiones de diseño defendibles

### ¿Por qué un Databricks Job y no un Airflow externo?

- **Cohesión**: Databricks Jobs viven en el mismo workspace que los notebooks. No hay que mantener un servidor Airflow extra.
- **Costo**: Airflow productivo requiere instancia EC2 / cluster Kubernetes. Databricks Jobs no tienen costo adicional al del compute.
- **Visibilidad**: el DAG y los logs están integrados en la UI de Databricks.
- **Para producción real**, muchas empresas usan Airflow + dbt + Databricks Jobs en conjunto. Para un proyecto académico con 2 tareas, Databricks Job es suficiente.

### ¿Por qué dependencias en lugar de un solo notebook orquestador?

- **Granularidad**: si falla la primera tarea, no se ejecuta la segunda (ahorra recursos).
- **Reintentos**: Databricks Jobs permiten configurar `retries` por tarea (si dbt falla por timeout, reintentar 3 veces).
- **Paralelización**: en el futuro, las tareas independientes (ej. ingestar bookings y users) se pueden ejecutar en paralelo.
- **Auditoría**: cada tarea tiene su propio log, tiempo y estado.

### ¿Por qué el orden 06 → 08 y no al revés?

- **06 (ingesta)** primero inserta los eventos en Bronze.
- **08 (dbt)** después procesa Silver y Gold con los datos completos (originales + nuevos).
- Invertir el orden generaría que dbt procese SIN los nuevos eventos → dashboards desactualizados.

---

## Próximos pasos para producción

Si este proyecto pasara a producción real, las mejoras serían:

1. **Reemplazar el productor sintético** (notebook 06) por Apache Kafka + Spark Structured Streaming.
2. **Separar el job** en múltiples tareas paralelas por entidad (1 task por cada `dbt run --select silver.silver_<entidad>`).
3. **Agregar tarea de notificación** que avise a un canal de Slack/Teams cuando termine.
4. **Configurar alertas en Power BI** que disparen si un KPI cae por debajo de un umbral.
5. **Implementar Databricks Workflows con Delta Live Tables (DLT)** que orqueste automáticamente sin escribir Python.

Eso es ya nivel arquitecto de datos senior — fuera del scope del proyecto académico, pero documentable como roadmap.
