import logging
import os
from pathlib import Path
from airflow.models import Variable

import pandas as pd
from sqlalchemy import create_engine

logger = logging.getLogger(__name__)


def get_engine():
    host = Variable.get("FIN_PG_HOST", "localhost")
    port = Variable.get("FIN_PG_PORT", "5432")
    db = Variable.get("FIN_PG_DB", "project_db")
    user = Variable.get("FIN_PG_USER", "project_user")
    password = Variable.get("FIN_PG_PASSWORD", "postgres")

    url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}"
    return create_engine(url)


def load_to_raw(input_path: str | Path, table: str = "raw_transactions") -> int:
    input_path = Path(input_path)
    logger.info(f"Betöltés megkezdve: {input_path} → raw.{table}")

    df = pd.read_parquet(input_path)
    engine = get_engine()

    rows = df.to_sql(
        name=table,
        con=engine,
        if_exists="append",
        index=False,
        schema="raw",
    )

    logger.info(f"Betöltve: {rows} sor → raw.{table}")
    return rows


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    from ingestion.read_excel import read_excel, save_raw
    from ingestion.clean_raw_data import clean_raw_data

    raw_path = save_raw(read_excel(
        os.environ.get("EXCEL_SOURCE", "notebooks/sources/tranzakciok.xlsx")
    ))
    staging_path = clean_raw_data(raw_path)
    load_to_raw(staging_path)
