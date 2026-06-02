{{
  config(
    materialized='table',
    schema='silver',
    file_format='delta'
  )
}}

-- silver_bookings — reservas limpias con columna derivada total_nights
-- Filtros de validez: total_amount > 0, check_out > check_in
--
-- Procesa los 72M registros amplificados de Bronze para que Silver/Gold
-- y los dashboards reflejen la escala completa del pipeline.

WITH dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY booking_id
      ORDER BY updated_at DESC
    ) AS rn
  FROM {{ source('bronze', 'bronze_bookings') }}
  WHERE booking_id IS NOT NULL
)

SELECT
  CAST(booking_id AS BIGINT)             AS booking_id,
  CAST(user_id AS BIGINT)                AS user_id,
  CAST(property_id AS BIGINT)            AS property_id,
  CAST(check_in AS DATE)                 AS check_in,
  CAST(check_out AS DATE)                AS check_out,
  CAST(guests_count AS INT)              AS guests_count,
  CAST(total_amount AS DECIMAL(10,2))    AS total_amount,
  TRIM(status)                           AS status,
  CAST(created_at AS TIMESTAMP)          AS created_at,
  CAST(updated_at AS TIMESTAMP)          AS updated_at,
  DATEDIFF(
    CAST(check_out AS DATE),
    CAST(check_in AS DATE)
  )                                      AS total_nights
FROM dedup
WHERE rn = 1
  AND CAST(total_amount AS DECIMAL(10,2)) > 0
  AND CAST(check_out AS DATE) > CAST(check_in AS DATE)
