{{ config(materialized='table') }}

WITH transactions AS (

    SELECT *
    FROM {{ ref('fct_transactions') }}

)

,monthly AS (

    SELECT
        EXTRACT(year FROM booking_date)::INT AS spent_year,
        EXTRACT(month FROM booking_date)::INT AS spent_month,
        TO_CHAR(booking_date, 'YYYY-MM') AS year_month,
        SUM(amount) AS total_spent
    FROM transactions
    WHERE
        is_expense = TRUE
    GROUP BY 1, 2, 3
)

SELECT * FROM monthly