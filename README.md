# finance-pipeline-public

Personal finance data pipeline — a modern, Docker-based data stack that ingests bank transactions, transforms them through a medallion architecture, and serves analytics via a BI dashboard. Designed for personal use with future ML integration in mind.

> This repository contains the **pipeline layer**.  
> The infrastructure (Docker Compose, PostgreSQL init, Airflow/Superset config) lives in the companion repo: [`finance-infra-public`](../finance-infra-public).

---

## Repository Structure

```
finance-pipeline-public/
├── dags/
│   ├── raw_ingestion_dag.py        # Daily ingestion: Excel → Parquet → PostgreSQL
│   └── dbt_finance_dag.py          # dbt transformation run (triggered by raw_ingestion)
├── ingestion/
│   ├── read_excel.py               # Reads bank Excel export, outputs raw Parquet
│   ├── clean_raw_data.py           # Deduplicates and cleans, outputs staging Parquet
│   ├── load_to_raw.py              # Loads staging Parquet into raw.raw_transactions
│   └── pipeline.py                 # Standalone runner (without Airflow)
├── database/
│   ├── bootstrap/                  # One-time SQL: create role, database, grants
│   └── migrations/                 # Flyway versioned DDL migrations (V001–V005)
├── dbt/
│   ├── dbt_project.yml
│   ├── packages.yml                # dbt_utils dependency
│   ├── models/
│   │   ├── staging/finance/        # stg_finance (view)
│   │   ├── intermediate/           # int_finance (view, business flags)
│   │   └── mart/                   # dim_* and fct_* tables
│   └── tests/finance/intermediate/ # Custom dbt data quality tests
├── notebooks/
│   └── csv_ingestion_to_raw.ipynb  # Exploratory ingestion notebook
├── Dockerfile                      # Pipeline container image
└── requirements.txt                # Python dependencies
```

---

## Pipeline Flow

```
Bank Excel export (tranzakciok.xlsx)
        │
        ▼
  raw_ingestion DAG
  ├── wait_for_file  (FileSensor, 300s timeout)
  ├── ingest         read_excel()  →  data/raw/*.parquet
  ├── clean          clean_raw()   →  data/staging/*.parquet
  ├── load           load_to_raw() →  raw.raw_transactions
  └── trigger_dbt ─────────────────────────────┐
                                               ▼
                                    dbt_finance DAG
                                    ├── dbt deps
                                    ├── dbt run  + test  (staging)
                                    ├── dbt run  + test  (intermediate)
                                    └── dbt run  + test  (mart)
```

---

## Ingestion Scripts

### `read_excel.py`
- Reads the bank's Excel transaction export
- Maps column names from Hungarian to English
- Normalizes direction values (`IN` / `OUT`), casts types
- Adds metadata columns: `_source_file`, `_ingested_at`
- Outputs a timestamped raw Parquet file (e.g. `transactions_raw_20260528T083215Z.parquet`)

### `clean_raw_data.py`
- Removes duplicates
- Converts amount to absolute value
- Strips whitespace, replaces NaN with `None`
- Outputs a staging Parquet file

### `load_to_raw.py`
- Reads the staging Parquet
- Connects to PostgreSQL via SQLAlchemy (credentials from Airflow Variables)
- Appends rows to `raw.raw_transactions`

---

## dbt Models

### Materialization strategy

| Layer | Materialization | Purpose |
|---|---|---|
| staging | view | Type casting, deduplication, surrogate key |
| intermediate | view | Business logic and computed flags |
| mart | table | Analytics-ready, denormalized for BI |

### Staging — `stg_finance`
- Generates `transaction_id` surrogate key (SHA hash of date + amount + counterparty)
- Standardizes types, trims strings, uppercases direction and currency

### Intermediate — `int_finance`
Adds computed boolean flags:

| Flag | Logic |
|---|---|
| `is_outflow` | direction = OUT |
| `is_inflow` | direction = IN |
| `is_expense` | OUT and not a savings transfer |
| `is_income` | IN and not a savings transfer |
| `is_transfer` | description contains savings transfer keyword |
| `final_category` | coalesces null category to "Nem kategorizált" |

### Mart

| Model | Type | Description |
|---|---|---|
| `dim_date` | dimension | Calendar with year, quarter, month, week, weekend flag |
| `dim_category` | dimension | Category masterdata with first/last seen dates |
| `dim_counterparty` | dimension | Counterparty masterdata |
| `fct_transactions` | fact | All transactions with FK joins to dimensions |
| `fct_monthly_spending` | fact | Monthly total spending aggregate |
| `fct_monthly_saving` | fact | Income vs. expenses, net savings per month |
| `fct_category_monthly_spending` | fact | Monthly spending broken down by category |

### Data quality tests
- Schema tests: `unique`, `not_null`, `accepted_values` on every key column
- Custom tests (intermediate layer):
  - `assert_int_finance_flags_directions` — no row can have both `is_inflow` and `is_outflow` false
  - `assert_int_finance_flags_exclusive` — `is_expense`, `is_income`, `is_transfer` are mutually exclusive
  - `assert_int_finance_transfer_not_expense_or_income` — a transfer cannot also be an expense or income

---

## Database Migrations

Flyway versioned migrations under `database/migrations/`:

| Version | Description |
|---|---|
| V001 | Create schemas: raw, staging, intermediate, mart, reference, dbo |
| V002 | Create `raw.raw_transactions` table |
| V003 | Create `raw.raw_transactions_test` table |
| V004 | Add metadata columns (`_source_file`, `_ingested_at`) |
| V005 | Grant schema privileges to `project_user` |

Migrations run automatically on stack startup via the Flyway service defined in the infra repo.

---

### Prerequisites

- The infra stack must be running — see [`finance-infra-public`](../finance-infra-public) for setup
- Both repos cloned side by side:

```
finance/
├── finance-infra-public/
├── finance-pipeline-public/   ← this repo
└── finance-inbox/             ← drop Excel files here
```

## License

Personal / private use. Not licensed for redistribution.
