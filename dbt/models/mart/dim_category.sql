{{ config(materialized='table') }}

WITH transactions AS (
    SELECT * FROM {{ ref('int_finance') }}
)

,categories AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'final_category'
        ]) }} AS category_id,

        final_category AS category_name,

        COUNT(*) AS transaction_count,
        MIN(booking_date) AS first_seen_date,
        MAX(booking_date) AS last_seen_date

    FROM transactions
    WHERE final_category IS NOT NULL
    GROUP BY 1, 2
)

SELECT * FROM categories
