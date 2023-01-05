all: directories files check_docker check_k8s init_cluster

check_docker:
	@echo "=======================\nVerificando Docker\n=======================\n";
	@if test ! -x "$(shell which docker)"; then \
		echo "\n\tDocker não encontrado. Instalando Docker...\n"; \
		curl -fsSL https://get.docker.com | sh; \
	else \
		echo "Docker está instalado\n"; \
	fi

check_k8s:
	@echo "=======================\nVerificando Kubernetes\n=======================\n";
	@if test ! -x "$(shell which kubectl)"; then \
		echo "\n\tKubernetes não encontrado. Instalando Kubernetes...\n"; \
		echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
		curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
		sudo apt update && sudo apt install -y kubectl kubeamd kubelet; \
	else \
		echo "Kubernetes está instalado\n"; \
	fi

directories:
	@echo "=======================\nCriando diretórios\n=======================\n";
	mkdir -p /home/$(shell whoami)/container/web \
			/home/$(shell whoami)/container/prometheus \
			/home/$(shell whoami)/container/portainer
	@echo "Criando diretório -> 'container'\nCriando diretório -> 'container/web'\nCriando diretório -> 'container/prometheus'\nCriando diretório -> 'container/portainer'\n"

files: directories
	@echo "=======================\nCopiando arquivos\n=======================\n"
	@echo "Copiando 'config/prometheus/*' -> 'container/prometheus/'"
	@echo "Copiando 'config/web/*' -> 'container/web/'"
	cp -R configs/prometheus/ container/prometheus/
	cp -R configs/web/ container/web/
	@echo "-----------------------------\nArquivos copiados com sucesso...\n-----------------------------\n"

init_cluster: check_k8s
	@echo "=======================\nIniciando cluster\n=======================\n";
	@echo "Criando Pod web1"
	kubectl apply -f pods/pod1-apache.yaml
	@echo "Criando Pod web2\n"
	kubectl apply -f pods/pod2-apache.yaml
	@echo "Iniciando Service pod-web1"
	kubectl apply -f services/pods-services/service-pod-web1.yaml
	@echo "Iniciando Service pod-web2\n"
	kubectl apply -f services/pods-services/service-pod-web2.yaml
	@echo "Criando Pod monitoramento\n"
	kubectl apply -f pods/pilha-monitoramento.yaml
	@echo "Iniciando Service prometheus"
	kubectl apply -f services/pods-services/service-prometheus.yaml
	@echo "Iniciando Service grafana\n"
	kubectl apply -f services/pods-services/service-grafana.yaml
	@echo "-----------------------------\nCluster iniciado com sucesso...\n-----------------------------\n"