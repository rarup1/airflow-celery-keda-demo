from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from datetime import datetime
import pandas as pd
from faker import Faker
import random
import logging


# Faker instance
fake = Faker()

# Function to generate a portion of the dataframe
def generate_records(task_id, num_records):
    records = []
    for _ in range(num_records):
        record = {
            'name': fake.name(),
            'address': fake.address(),
            'email': fake.email(),
            'phone_number': fake.phone_number(),
            'job': fake.job(),
        }
        records.append(record)
    
    # Convert to DataFrame
    df = pd.DataFrame(records)
    
    # Save to CSV (or you can store in a more appropriate location)
    logging.info(f"Task {task_id} generated {len(df)} records.")
    

# DAG definition
default_args = {
    'start_date': datetime(2023, 10, 1),
}

with DAG('generate_fake_data_dag', default_args=default_args, schedule_interval=None, catchup=False) as dag:
    
    # Generate 100 records divided across 50 tasks
    total_records = 10000
    num_tasks = 50
    records_per_task = total_records // num_tasks
    
    # Create 50 tasks
    for i in range(1, num_tasks + 1):
        task = PythonOperator(
            task_id=f'generate_records_task_{i}',
            python_callable=generate_records,
            op_args=[i, records_per_task],
        )
