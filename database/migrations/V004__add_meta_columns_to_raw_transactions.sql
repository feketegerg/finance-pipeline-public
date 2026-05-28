ALTER TABLE raw.raw_transactions
    ADD COLUMN _source_file  VARCHAR(255),
    ADD COLUMN _ingested_at  TIMESTAMP WITH TIME ZONE;

ALTER TABLE raw.raw_transactions_test
    ADD COLUMN _source_file  VARCHAR(255),
    ADD COLUMN _ingested_at  TIMESTAMP WITH TIME ZONE;
