{{ config(materialized='view') }}

WITH stg_finance AS (
    SELECT * FROM {{ ref('stg_finance') }}
)

,trasformed_transactions AS (
    SELECT
        transaction_id,
        transaction_date,
        booking_date,
        transaction_type,
        direction,

        counterparty_name,
        counterparty_name AS final_counterparty_name,

        counterparty_account_id,

        spending_category,
        COALESCE(spending_category, 'Nem kategorizált') AS final_category,

        description,
        account_name,
        account_number,
        amount,
        currency,
        source_file,
        ingested_at,

        CASE
            WHEN direction = 'OUT' THEN TRUE
            ELSE FALSE
        END AS is_outflow,

        CASE
            WHEN direction = 'IN' THEN TRUE
            ELSE FALSE
        END AS is_inflow,

        CASE
            WHEN direction = 'OUT'
            AND COALESCE(description, '') NOT LIKE '%persely%'
            THEN TRUE
            ELSE FALSE
        END AS is_expense,

        CASE
            WHEN direction = 'IN'
            AND COALESCE(description, '') NOT LIKE '%persely%'
            THEN TRUE
            ELSE FALSE
        END AS is_income,

        CASE
            WHEN description LIKE '%persely%'
            THEN TRUE
            ELSE FALSE
        END AS is_transfer
    FROM stg_finance
)

SELECT * FROM trasformed_transactions
