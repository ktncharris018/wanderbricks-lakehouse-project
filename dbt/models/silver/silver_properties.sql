{{
  config(
    materialized='table',
    schema='silver',
    file_format='delta'
  )
}}

-- silver_properties — propiedades limpias y deduplicadas
-- Filtros de validez: base_price > 0, max_guests > 0

WITH dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY property_id
      ORDER BY created_at DESC
    ) AS rn
  FROM {{ source('bronze', 'bronze_properties') }}
  WHERE property_id IS NOT NULL
)

SELECT
  CAST(property_id AS BIGINT)              AS property_id,
  CAST(host_id AS BIGINT)                  AS host_id,
  CAST(destination_id AS BIGINT)           AS destination_id,
  TRIM(title)                              AS title,
  TRIM(property_type)                      AS property_type,
  CAST(max_guests AS INT)                  AS max_guests,
  CAST(bedrooms AS INT)                    AS bedrooms,
  CAST(bathrooms AS INT)                   AS bathrooms,
  CAST(base_price AS DECIMAL(10,2))        AS base_price,
  CAST(property_latitude AS DOUBLE)        AS property_latitude,
  CAST(property_longitude AS DOUBLE)       AS property_longitude,
  CAST(created_at AS DATE)                 AS created_at
FROM dedup
WHERE rn = 1
  AND base_price > 0
  AND max_guests > 0
