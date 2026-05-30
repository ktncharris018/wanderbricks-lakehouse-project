{{
  config(
    materialized='table',
    schema='gold',
    file_format='delta'
  )
}}

-- gold_fact_reservas — tabla de hechos central del Star Schema
-- Granularidad: una fila por reserva (booking_id).
--
-- Métricas:
--   - total_amount         (importe de la reserva)
--   - total_nights         (noches reservadas, derivado en Silver)
--   - cantidad_reservas    (constante 1, para SUM en agregaciones)
--   - payment_amount       (suma de pagos completed por booking)
--
-- destination_id se obtiene vía JOIN con silver_properties (bookings no lo trae).
-- Los pagos se pre-agregan por booking_id para evitar duplicar filas de la fact.

WITH pagos_agregados AS (
  SELECT
    booking_id,
    SUM(amount) AS payment_amount
  FROM {{ ref('silver_payments') }}
  WHERE status = 'completed'
  GROUP BY booking_id
)

SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  p.destination_id,
  b.check_in                       AS tiempo_id,
  b.total_amount,
  b.total_nights,
  1                                AS cantidad_reservas,
  COALESCE(pa.payment_amount, 0)   AS payment_amount,
  b.status                         AS booking_status,
  b.check_in,
  b.check_out,
  b.guests_count
FROM {{ ref('silver_bookings') }} b
LEFT JOIN {{ ref('silver_properties') }} p
  ON b.property_id = p.property_id
LEFT JOIN pagos_agregados pa
  ON b.booking_id = pa.booking_id
