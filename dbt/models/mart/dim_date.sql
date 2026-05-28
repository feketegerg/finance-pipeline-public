{{ config(materialized='table') }}

WITH date_spine AS (

    SELECT
        GENERATE_SERIES(
            (SELECT MIN(booking_date)::date FROM {{ ref('int_finance') }}),
            (SELECT MAX(booking_date)::date FROM {{ ref('int_finance') }}),
            INTERVAL '1 day'
        )::date AS date_day

)

,dates AS (
    SELECT
        date_day,
        EXTRACT(year FROM date_day)::INT AS year,
        EXTRACT(quarter FROM date_day)::INT AS quarter,
        EXTRACT(month FROM date_day)::INT AS month,
        EXTRACT(week FROM date_day)::INT AS week,

        EXTRACT(day FROM date_day)::INT AS day_of_month,
        EXTRACT(dow FROM date_day)::INT AS day_of_week,

        CASE
            WHEN EXTRACT(dow FROM date_day) IN (0, 6) THEN TRUE
            ELSE FALSE
        END AS is_weekend,

        DATE_TRUNC('month', date_day)::date AS month_start_date,
        DATE_TRUNC('week', date_day)::date AS week_start_date,

        TO_CHAR(date_day, 'YYYY-MM') AS year_month

    FROM date_spine

)

SELECT * FROM dates
