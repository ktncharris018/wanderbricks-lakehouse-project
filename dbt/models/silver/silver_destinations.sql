{{
  config(
    materialized='table',
    schema='silver',
    file_format='delta'
  )
}}

-- silver_destinations — destinos limpios
-- Equivalente a la celda silver_destinations del notebook 04_silver_layer.ipynb

WITH dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY destination_id
      ORDER BY destination_id
    ) AS rn
  FROM {{ source('bronze', 'bronze_destinations') }}
  WHERE destination_id IS NOT NULL
)

SELECT
  CAST(destination_id AS BIGINT)        AS destination_id,
  TRIM(destination)                     AS destination,
  TRIM(country)                         AS country,
  TRIM(state_or_province)               AS state_or_province,
  TRIM(state_or_province_code)          AS state_or_province_code,
  description
FROM dedup
WHERE rn = 1
