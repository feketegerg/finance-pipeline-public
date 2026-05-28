CREATE TABLE raw.raw_transactions_test (
    transactions_date TIMESTAMP WITH TIME ZONE NOT NULL,
    booking_date DATE NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    counterparty_name VARCHAR(255),
    counterparty_account_id VARCHAR(255),
    spending_category VARCHAR(255),
    description TEXT,
    account_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(255) NOT NULL,
    amount NUMERIC(78, 0) NOT NULL,
    currency VARCHAR(10) NOT NULL
);