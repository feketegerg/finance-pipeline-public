{{ config(materialized='table') }}

WITH transactions AS (

    SELECT * FROM {{ ref('fct_transactions') }}

)

,monthly_in_out AS (
    SELECT
        EXTRACT(YEAR FROM booking_date)::INT AS spent_year,
        EXTRACT(MONTH FROM booking_date)::INT AS spent_month,
        TO_CHAR(booking_date, 'YYYY-MM') AS year_month,
        SUM(CASE WHEN is_expense = TRUE THEN amount ELSE 0 END) AS total_spent,
        SUM(CASE WHEN is_income = TRUE THEN amount ELSE 0 END) AS total_income
    FROM transactions
    GROUP BY 1, 2, 3
)

,result AS (
    SELECT
        spent_year,
        spent_month,
        year_month,
        total_spent,
        total_income,
        total_income - total_spent AS total_saving
    FROM monthly_in_out
)

SELECT * FROM result
