import logging
import os
import shutil
import warnings
from pathlib import Path
from datetime import datetime, timezone

import pandas as pd

logger = logging.getLogger(__name__)

COLUMN_MAP = {
    "Tranzakció dátuma": "transactions_date",
    "Könyvelés dátuma": "booking_date",
    "Típus": "transaction_type",
    "Bejövő/Kimenő": "direction",
    "Partner neve": "counterparty_name",
    "Partner számlaszáma/azonosítója": "counterparty_account_id",
    "Költési kategória": "spending_category",
    "Közlemény": "description",
    "Számla név": "account_name",
    "Számla szám": "account_number",
    "Összeg": "amount",
    "Pénznem": "currency",
}


def read_excel(path: str | Path) -> pd.DataFrame:
    path = Path(path)
    logger.info(f"Excel beolvasása: {path}")

    with warnings.catch_warnings():
        warnings.simplefilter("ignore", UserWarning)
        df = pd.read_excel(path, dtype={"Számla szám": str})

    df = df.rename(columns=COLUMN_MAP)

    df["transactions_date"] = pd.to_datetime(df["transactions_date"])
    df["booking_date"] = pd.to_datetime(df["booking_date"])
    df["amount"] = pd.to_numeric(df["amount"])
    df["direction"] = df["direction"].map({"Bejövő": "IN", "Kimenő": "OUT"})
    df["_source_file"] = path.name
    df["_ingested_at"] = datetime.now(timezone.utc)

    logger.info(f"Beolvasva: {len(df)} sor")
    return df


def save_raw(df: pd.DataFrame, output_dir: str | Path = None) -> Path:
    if output_dir is None:
        output_dir = os.environ.get("RAW_DIR", "data/raw")

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out_path = output_dir / f"transactions_raw_{timestamp}.parquet"
    df.to_parquet(out_path, index=False)

    logger.info(f"Raw Parquet mentve: {out_path}")
    return out_path


def archive_source(path: str | Path, archive_dir: str | Path = None) -> Path:
    path = Path(path)
    if archive_dir is None:
        archive_dir = path.parent / "archive"

    archive_dir = Path(archive_dir)
    archive_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    dest = archive_dir / f"{path.stem}_{timestamp}{path.suffix}"
    shutil.move(str(path), dest)

    logger.info(f"Forrás archiválva: {path} → {dest}")
    return dest


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    source = Path(os.environ.get("EXCEL_SOURCE", "notebooks/sources/tranzakciok.xlsx"))
    df = read_excel(source)
    out = save_raw(df)
    logger.info(f"Kész: {out}")
