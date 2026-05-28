import logging
import os
from pathlib import Path
from datetime import datetime, timezone

import pandas as pd

logger = logging.getLogger(__name__)


def clean_raw_data(input_path: str | Path, output_dir: str | Path = None) -> Path:
    if output_dir is None:
        output_dir = os.environ.get("STAGING_DIR", "data/staging")

    input_path = Path(input_path)
    output_dir = Path(output_dir)

    logger.info(f"Tisztítás megkezdve: {input_path}")
    df = pd.read_parquet(input_path)

    df = df.drop_duplicates()
    df["amount"] = df["amount"].abs()
    df["counterparty_name"] = df["counterparty_name"].str.strip()
    df["description"] = df["description"].str.strip()
    df = df.where(pd.notna(df), other=None)

    output_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out_path = output_dir / f"transactions_clean_{timestamp}.parquet"
    df.to_parquet(out_path, index=False)

    logger.info(f"Staging Parquet mentve: {out_path} ({len(df)} sor)")
    return out_path


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    from ingestion.read_excel import read_excel, save_raw

    raw_path = save_raw(read_excel(
        os.environ.get("EXCEL_SOURCE", "notebooks/sources/tranzakciok.xlsx")
    ))
    clean_raw_data(raw_path)
