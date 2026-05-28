import logging
import os
from pathlib import Path

from ingestion.read_excel import read_excel, save_raw, archive_source
from ingestion.clean_raw_data import clean_raw_data
from ingestion.load_to_raw import load_to_raw

logger = logging.getLogger(__name__)


def run():
    source = Path(os.environ.get("EXCEL_SOURCE", "notebooks/sources/tranzakciok.xlsx"))

    logger.info("=== 1/3 ingest ===")
    df = read_excel(source)
    raw_path = save_raw(df)
    archive_source(source)

    logger.info("=== 2/3 clean ===")
    staging_path = clean_raw_data(raw_path)

    logger.info("=== 3/3 load ===")
    rows = load_to_raw(staging_path)

    logger.info(f"Pipeline kész — {rows} sor betöltve.")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    run()
