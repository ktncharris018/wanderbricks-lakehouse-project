{{
  config(
    materialized='table',
    schema='gold',
    file_format='delta'
  )
}}

-- gold_dim_time — dimensión temporal generada dinámicamente
-- Se construye a partir del rango real observado en silver_bookings

WITH bounds AS (
  SELECT
    MIN(check_in)  AS min_date,
    MAX(check_out) AS max_date
  FROM {{ ref('silver_bookings') }}
),

dates AS (
  SELECT
    EXPLODE(
      SEQUENCE(min_date, max_date, INTERVAL 1 DAY)
    ) AS date
  FROM bounds
)

SELECT
  date                                  AS tiempo_id,
  date,
  YEAR(date)                            AS year,
  QUARTER(date)                         AS quarter,
  MONTH(date)                           AS month,
  DATE_FORMAT(date, 'MMMM')             AS month_name,
  DAY(date)                             AS day,
  DAYOFWEEK(date)                       AS day_of_week,
  DATE_FORMAT(date, 'EEEE')             AS day_name,
  WEEKOFYEAR(date)                      AS week_of_year,
  CASE
    WHEN DAYOFWEEK(date) IN (1, 7) THEN true
    ELSE false
  END                                   AS is_weekend
FROM dates
