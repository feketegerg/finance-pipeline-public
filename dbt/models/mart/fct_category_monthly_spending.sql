{{ config(materialized='table') }}

WITH transactions AS (

    SELECT *
    FROM {{ ref('fct_transactions') }}

)

,categories AS (
    SELECT * FROM {{ ref('dim_category') }}

)

,monthly_by_category AS (
    SELECT
        EXTRACT(year FROM booking_date)::INT AS spent_year,
        EXTRACT(month FROM booking_date)::INT AS spent_month,
        TO_CHAR(booking_date, 'YYYY-MM') AS year_month,
        cat.category_name,
        SUM(amount) AS total_spent
    FROM transactions tran
    LEFT JOIN categories cat ON cat.category_id = tran.category_id
    WHERE
        is_expense = TRUE
    GROUP BY 1, 2, 3, 4
)

SELECT * FROM monthly_by_category
