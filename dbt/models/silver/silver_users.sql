{{
  config(
    materialized='table',
    schema='silver',
    file_format='delta'
  )
}}

-- silver_users — usuarios limpios y deduplicados
-- Equivalente a la celda silver_users del notebook 04_silver_layer.ipynb
--
-- Transformaciones aplicadas:
--   1. Deduplicación por user_id conservando el registro más reciente (created_at DESC)
--   2. TRIM de columnas de texto
--   3. Cast de tipos: BIGINT, TIMESTAMP, BOOLEAN
--   4. Filtrado de user_id nulos

WITH dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY created_at DESC
    ) AS rn
  FROM {{ source('bronze', 'bronze_users') }}
  WHERE user_id IS NOT NULL
)

SELECT
  CAST(user_id AS BIGINT)            AS user_id,
  TRIM(email)                        AS email,
  TRIM(name)                         AS name,
  TRIM(country)                      AS country,
  TRIM(user_type)                    AS user_type,
  CAST(is_business AS BOOLEAN)       AS is_business,
  TRIM(company_name)                 AS company_name,
  CAST(created_at AS TIMESTAMP)      AS created_at
FROM dedup
WHERE rn = 1
