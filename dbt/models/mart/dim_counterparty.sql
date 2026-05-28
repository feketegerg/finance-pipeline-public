{{ config(materialized='table') }}

WITH transactions AS (
    SELECT * FROM {{ ref('int_finance') }}
)

,counterparties AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'final_counterparty_name'
        ]) }} AS counterparty_id,

        final_counterparty_name AS counterparty_name,
        MIN(booking_date) AS first_seen_date,
        MAX(booking_date) AS last_seen_date

    FROM transactions
    WHERE final_counterparty_name IS NOT NULL
    GROUP BY 1, 2
)

SELECT * FROM counterparties
