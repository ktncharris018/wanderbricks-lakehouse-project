{{
  config(
    materialized='table',
    schema='silver',
    file_format='delta'
  )
}}

-- silver_payments — pagos limpios
-- Filtro de validez: amount > 0

WITH dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY payment_id
      ORDER BY payment_date DESC
    ) AS rn
  FROM {{ source('bronze', 'bronze_payments') }}
  WHERE payment_id IS NOT NULL
)

SELECT
  CAST(payment_id AS BIGINT)           AS payment_id,
  CAST(booking_id AS BIGINT)           AS booking_id,
  CAST(amount AS DECIMAL(10,2))        AS amount,
  TRIM(payment_method)                 AS payment_method,
  TRIM(status)                         AS status,
  CAST(payment_date AS TIMESTAMP)      AS payment_date
FROM dedup
WHERE rn = 1
  AND CAST(amount AS DECIMAL(10,2)) > 0
