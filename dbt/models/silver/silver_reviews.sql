{{
  config(
    materialized='table',
    schema='silver',
    file_format='delta'
  )
}}

-- silver_reviews — reseñas limpias
-- Filtros de validez: is_deleted = false, rating entre 0 y 5
--
-- Procesa las reviews amplificadas en Bronze para reflejar la escala del pipeline.

WITH dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY review_id
      ORDER BY updated_at DESC
    ) AS rn
  FROM {{ source('bronze', 'bronze_reviews') }}
  WHERE review_id IS NOT NULL
)

SELECT
  CAST(review_id AS BIGINT)         AS review_id,
  CAST(booking_id AS BIGINT)        AS booking_id,
  CAST(user_id AS BIGINT)           AS user_id,
  CAST(property_id AS BIGINT)       AS property_id,
  CAST(rating AS DECIMAL(3,1))      AS rating,
  TRIM(comment)                     AS comment,
  CAST(is_deleted AS BOOLEAN)       AS is_deleted,
  CAST(created_at AS TIMESTAMP)     AS created_at,
  CAST(updated_at AS TIMESTAMP)     AS updated_at
FROM dedup
WHERE rn = 1
  AND CAST(is_deleted AS BOOLEAN) = false
  AND CAST(rating AS DECIMAL(3,1)) BETWEEN 0 AND 5
