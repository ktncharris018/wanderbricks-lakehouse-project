{{
  config(
    materialized='table',
    schema='gold',
    file_format='delta'
  )
}}

-- gold_dim_users — dimensión de usuarios
-- Equivalente a la celda gold_dim_users del notebook 05_gold_layer.ipynb

SELECT
  user_id              AS user_key,
  user_id,
  name,
  email,
  country,
  user_type,
  is_business,
  company_name,
  created_at           AS registration_date
FROM {{ ref('silver_users') }}
