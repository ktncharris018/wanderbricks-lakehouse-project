# Modelo Conceptual — Wanderbricks

Este diagrama representa las entidades principales del dominio de negocio (reservas de alojamiento turístico) y sus relaciones, antes de aplicar el modelado dimensional.

```mermaid
erDiagram
    USERS {
        bigint user_id PK
        string email
        string name
        string country
        string user_type
        boolean is_business
        string company_name
        timestamp created_at
    }
    DESTINATIONS {
        bigint destination_id PK
        string destination
        string country
        string state_or_province
        string state_or_province_code
    }
    PROPERTIES {
        bigint property_id PK
        bigint host_id
        bigint destination_id FK
        string title
        string property_type
        int max_guests
        int bedrooms
        int bathrooms
        decimal base_price
        double property_latitude
        double property_longitude
    }
    BOOKINGS {
        bigint booking_id PK
        bigint user_id FK
        bigint property_id FK
        date check_in
        date check_out
        int guests_count
        decimal total_amount
        string status
        timestamp created_at
        timestamp updated_at
    }
    PAYMENTS {
        bigint payment_id PK
        bigint booking_id FK
        decimal amount
        string payment_method
        string status
        timestamp payment_date
    }
    REVIEWS {
        bigint review_id PK
        bigint booking_id FK
        bigint user_id FK
        bigint property_id FK
        decimal rating
        string comment
        boolean is_deleted
        timestamp created_at
        timestamp updated_at
    }

    USERS        ||--o{ BOOKINGS : "realiza"
    PROPERTIES   ||--o{ BOOKINGS : "es reservada en"
    DESTINATIONS ||--o{ PROPERTIES : "contiene"
    BOOKINGS     ||--o{ PAYMENTS  : "genera"
    BOOKINGS     ||--o{ REVIEWS   : "recibe"
    USERS        ||--o{ REVIEWS   : "escribe"
    PROPERTIES   ||--o{ REVIEWS   : "es evaluada en"
```

## Entidades

| Entidad | Descripción |
|---|---|
| **USERS** | Clientes registrados en la plataforma. Pueden ser personas individuales o cuentas empresariales (`is_business`). |
| **DESTINATIONS** | Ubicaciones geográficas (ciudad / estado / país) donde se ofertan propiedades. |
| **PROPERTIES** | Alojamientos disponibles para reserva. Cada uno pertenece a un destino y a un host. |
| **BOOKINGS** | Entidad transaccional central: una reserva conecta un usuario con una propiedad por un rango de fechas. |
| **PAYMENTS** | Movimientos financieros asociados a una reserva. Una reserva puede tener uno o varios pagos. |
| **REVIEWS** | Calificaciones y comentarios que un usuario deja sobre la propiedad luego de su estancia. |

## Reglas de negocio aplicadas en Silver

- Un `booking` válido tiene `check_out > check_in` y `total_amount > 0`.
- Solo se consideran `payments` con `amount > 0`.
- Solo se consideran `reviews` con `is_deleted = false` y `rating` entre 0 y 5.
- Cada entidad se deduplica por su PK conservando la versión más reciente (`updated_at` o `created_at`).
