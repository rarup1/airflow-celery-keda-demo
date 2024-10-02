from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from datetime import datetime

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 9, 22),  # Set your start date
}

# Define the DAG
with DAG(
    'mock_k8s_dag',
    default_args=default_args,
    description='A simple DAG to demonstrate KubernetesPodOperator',
    schedule_interval='@once',  # Run once
    catchup=False,
) as dag:

    # Define the KubernetesPodOperator task
    print_task = KubernetesPodOperator(
        task_id='print_hello',
        name='print-hello-pod',
        namespace='airflow',  # Replace with your namespace
        image='python:3.8-slim',  # Use a lightweight image
        cmds=["python", "-c"],
        arguments=["print('Hello from Kubernetes!')"],
        is_delete_operator_pod=True,  # Clean up the pod after execution
    )

    # add task that waits for 30 seconds then ends using k8s pod operator
    task_wait = KubernetesPodOperator(
        namespace='airflow',
        image="alpine",
        cmds=["sh", "-c"],
        arguments=["echo 'waiting 30 seconds' && sleep 30"],
        labels={"foo": "bar"},
        name="task-sleep",
        task_id="task-sleep",
        get_logs=True
    )


    # Set task dependencies (if any)
    print_task >> task_wait

