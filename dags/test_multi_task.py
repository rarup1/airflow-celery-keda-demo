from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

def simple_task():
    sleep(5)
    return "Hello, this is a test task!"

with DAG('test_keda_scaling', start_date=datetime(2023, 1, 1), schedule_interval=None) as dag:
    tasks = [PythonOperator(task_id=f"task_{i}", python_callable=simple_task) for i in range(50)]
