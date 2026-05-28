WITH source AS (
    SELECT * FROM {{ source('finance', 'raw_transactions') }}
),

standardized_transactions AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
                'transactions_date',
                'amount',
                'counterparty_account_id'
            ])
        }}                              AS transaction_id,

        -- dátumok
        transactions_date::date          AS transaction_date,
        booking_date::date              AS booking_date,

        -- tranzakció típusa
        transaction_type                AS transaction_type,
        UPPER(direction)                 AS direction,

        -- partner
        TRIM(counterparty_name)         AS counterparty_name,
        counterparty_account_id         AS counterparty_account_id,

        -- kategória és leírás
        spending_category               AS spending_category,
        TRIM(description)               AS description,

        -- számla
        account_name                    AS account_name,
        account_number                  AS account_number,

        -- összeg
        amount::INT                     AS amount,
        UPPER(currency)                 AS currency,

        -- metadata
        _source_file                    AS source_file,
        _ingested_at::TIMESTAMP         AS ingested_at

    FROM source
)

SELECT * FROM standardized_transactions
