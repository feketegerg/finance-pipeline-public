{{ config(materialized='table') }}

WITH transactions AS (
    SELECT * FROM {{ ref('int_finance') }}
)

,transactions_enriched AS (
    SELECT
        transaction_id,

        booking_date,
        transaction_date,

        {{ dbt_utils.generate_surrogate_key([
            'final_category'
        ]) }} AS category_id,

        {{ dbt_utils.generate_surrogate_key([
            'final_counterparty_name'
        ]) }} AS counterparty_id,

        amount,
        currency,

        direction,
        transaction_type,

        is_outflow,
        is_inflow,
        is_expense,
        is_income,
        is_transfer

    FROM transactions
)

SELECT * FROM transactions_enriched
