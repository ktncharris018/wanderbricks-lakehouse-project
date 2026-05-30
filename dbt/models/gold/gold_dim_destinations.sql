{{
  config(
    materialized='table',
    schema='gold',
    file_format='delta'
  )
}}

-- gold_dim_destinations — dimensión geográfica
-- Se descarta description (markdown extenso) para no degradar Power BI

SELECT
  destination_id              AS destination_key,
  destination_id,
  destination                 AS destination_name,
  country,
  state_or_province,
  state_or_province_code
FROM {{ ref('silver_destinations') }}
