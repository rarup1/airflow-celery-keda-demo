MINIKUBE_MOUNT_PATH="$(pwd):/mnt/workspace"
MINIKUBE_DRIVER=docker
MINIKUBE_MEMORY=8192
MINIKUBE_CPUS=4
MINIKUBE_DISK_SIZE=20g

AIRFLOW_NAMESPACE=airflow
AIRFLOW_DAGS_HOST_PATH='/mnt/workspace/dags'
AIRFLOW_VALUES_FILE=values.yaml
AIRFLOW_HELM_RELEASE_NAME=airflow
AIRFLOW_CHART_NAME=apache-airflow/airflow
AIRFLOW_VARIABLES_FILE=variables.yaml


KEDA_NAMESPACE=keda
KEDA_VERSION="v2.15.1"
KEDA_CHART_NAME=kedacore/keda


# .PHONY: all start_minikube set_permissions create_namespace deploy_airflow_vars deploy_airflow minikube_dashboard port_forward

all: start_minikube create_namespaces deploy_airflow_vars deploy_airflow

helm_repo_add:
	helm repo add apache-airflow https://airflow.apache.org
	helm repo add kedacore https://kedacore.github.io/charts
	helm repo update

# Start Minikube with the DAGs directory mounted
start_minikube:
	minikube start --mount --mount-string="$(MINIKUBE_MOUNT_PATH)" \
		--driver $(MINIKUBE_DRIVER) \
		--memory=$(MINIKUBE_MEMORY) \
		--cpus=$(MINIKUBE_CPUS) \
		--disk-size=$(MINIKUBE_DISK_SIZE) \
		--addons=dashboard,metrics-server

create_namespaces:
	kubectl create namespace $(AIRFLOW_NAMESPACE) || echo "Namespace $(AIRFLOW_NAMESPACE) already exists"
	kubectl create namespace $(KEDA_NAMESPACE) || echo "Namespace $(KEDA_NAMESPACE) already exists"

deploy_keda:
	helm install keda $(KEDA_CHART_NAME) \
    	--namespace $(KEDA_NAMESPACE) \
    	--version $(KEDA_VERSION)

deploy_airflow_vars:
	kubectl apply -f $(AIRFLOW_VARIABLES_FILE) -n $(AIRFLOW_NAMESPACE)

create_docker_img:
	eval $(minikube -p minikube docker-env)
	docker build --pull --tag local-airflow:2.10 -f Dockerfile_celery .

deploy_airflow:
	helm install $(AIRFLOW_HELM_RELEASE_NAME) $(AIRFLOW_CHART_NAME) --namespace $(AIRFLOW_NAMESPACE) -f $(AIRFLOW_VALUES_FILE)
upgrade_airflow:
	helm upgrade $(AIRFLOW_HELM_RELEASE_NAME) $(AIRFLOW_CHART_NAME) --namespace $(AIRFLOW_NAMESPACE) -f $(AIRFLOW_VALUES_FILE)

# Port-forward the Airflow webserver pod
port_forward:
	kubectl get pod -n $(AIRFLOW_NAMESPACE) -l component=webserver -o jsonpath="{.items[0].metadata.name}" | xargs -I {} kubectl port-forward {} 8080:8080 --namespace $(AIRFLOW_NAMESPACE)
