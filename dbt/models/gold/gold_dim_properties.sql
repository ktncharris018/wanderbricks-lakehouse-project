{{
  config(
    materialized='table',
    schema='gold',
    file_format='delta'
  )
}}

-- gold_dim_properties — dimensión de propiedades
-- Se omite la columna description para mantener la dimensión liviana

SELECT
  property_id              AS property_key,
  property_id,
  host_id,
  destination_id,
  title,
  property_type,
  max_guests,
  bedrooms,
  bathrooms,
  base_price,
  property_latitude,
  property_longitude
FROM {{ ref('silver_properties') }}
