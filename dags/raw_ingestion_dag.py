import logging
from datetime import datetime
from pathlib import Path

from airflow import DAG

from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.sensors.filesystem import FileSensor

from ingestion.read_excel import read_excel, save_raw, archive_source
from ingestion.clean_raw_data import clean_raw_data
from ingestion.load_to_raw import load_to_raw

logger = logging.getLogger(__name__)


def ingest(**context):
    source = Path(Variable.get("EXCEL_SOURCE", default_var="notebooks/sources/tranzakciok.xlsx"))
    raw_dir = Variable.get("RAW_DIR", default_var="data/raw")

    if not source.exists():
        logger.info(f"Forrás fájl nem található, pipeline kihagyva: {source}")
        return

    df = read_excel(source)
    raw_path = save_raw(df, output_dir=raw_dir)
    archive_source(source)
    context["ti"].xcom_push(key="raw_path", value=str(raw_path))


def clean(**context):
    staging_dir = Variable.get("STAGING_DIR", default_var="data/staging")
    raw_path = context["ti"].xcom_pull(task_ids="ingest", key="raw_path")
    staging_path = clean_raw_data(raw_path, output_dir=staging_dir)
    context["ti"].xcom_push(key="staging_path", value=str(staging_path))


def load(**context):
    staging_path = context["ti"].xcom_pull(task_ids="clean", key="staging_path")
    load_to_raw(staging_path)


with DAG(
    dag_id="raw_ingestion",
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
) as dag:

    wait_for_file = FileSensor(
        task_id="wait_for_file",
        filepath=Variable.get("EXCEL_SOURCE", default_var="notebooks/sources/tranzakciok.xlsx"),
        timeout=300,
        poke_interval=30,
        mode="reschedule",
        soft_fail=True,
    )

    ingest_task = PythonOperator(
        task_id="ingest",
        python_callable=ingest,
    )

    clean_task = PythonOperator(
        task_id="clean",
        python_callable=clean,
    )

    load_task = PythonOperator(
        task_id="load",
        python_callable=load,
    )

    trigger_dbt_finance = TriggerDagRunOperator(
        task_id="trigger_dbt_finance",
        trigger_dag_id="dbt_finance",
        wait_for_completion=False,
    )

    (
        wait_for_file
        >> ingest_task
        >> clean_task
        >> load_task
        >> trigger_dbt_finance
    )
