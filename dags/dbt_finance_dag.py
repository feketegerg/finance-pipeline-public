import os
from datetime import datetime

from airflow import DAG
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount

DBT_IMAGE = "ghcr.io/dbt-labs/dbt-postgres:1.9.0"
DBT_PROJECT_DIR = "/dbt/finance"
DBT_PROFILES_DIR = "/dbt"

MOUNTS = [
    Mount(
        source="/home/gergo/home-lab-infrastructure/dbt/profiles.yml",
        target="/dbt/profiles.yml",
        type="bind",
    ),
    Mount(
        source="/home/gergo/personal-finance-pipeline/dbt",
        target="/dbt/finance",
        type="bind",
    ),
]

BASE_COMMAND = f"{{}} --project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROFILES_DIR}"


def dbt_task(task_id: str, command: str) -> DockerOperator:
    return DockerOperator(
        task_id=task_id,
        image=DBT_IMAGE,
        command=BASE_COMMAND.format(command),
        mounts=MOUNTS,
        network_mode="infra-network",
        auto_remove="success",
        mount_tmp_dir=False,
        environment={
            "DBT_PROJECT_USER_PASSWORD": os.environ.get("DBT_PROJECT_USER_PASSWORD"),
        },
    )


with DAG(
    dag_id="dbt_finance",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
) as dag:

    deps = dbt_task("dbt_deps", "deps")
    run_staging = dbt_task("dbt_run_staging", "run --select staging")
    test_staging = dbt_task("dbt_test_staging", "test --select staging")
    run_intermediate = dbt_task("dbt_run_intermediate", "run --select intermediate")
    test_intermediate = dbt_task("dbt_test_intermediate", "test --select intermediate")
    run_mart = dbt_task("dbt_run_mart", "run --select mart")
    test_mart = dbt_task("dbt_test_mart", "test --select mart")

    (
        deps 
        >> run_staging 
        >> test_staging 
        >> run_intermediate 
        >> test_intermediate 
        >> run_mart 
        >> test_mart
    )
