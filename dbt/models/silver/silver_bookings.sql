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
-- NOTA: la cláusula `booking_id < 1000000000` excluye las filas amplificadas
-- sintéticamente en Bronze (las copias usan offset numérico n * 10^9).
-- Bronze conserva 72M registros para demostrar escala del pipeline;
-- Silver/Gold procesan únicamente los 72k registros originales.

WITH dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY booking_id
      ORDER BY updated_at DESC
    ) AS rn
  FROM {{ source('bronze', 'bronze_bookings') }}
  WHERE booking_id IS NOT NULL
    AND CAST(booking_id AS BIGINT) < 1000000000
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
