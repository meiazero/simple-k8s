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
	cp -R configs/prometheus container/prometheus/
	@echo "Copiando 'config/web/*' -> 'container/web/'"
	cp -R configs/web container/web/
	@echo "-----------------------------\nArquivos copiados com sucesso...\n-----------------------------\n"

init_cluster: check_k8s check_and_disable_swap
	@echo "=======================\nPronto para iniciar cluster\n=======================\n";
	
check_and_disable_swap:
	# Verifica se a memória swap está ativa
	@if grep -q "^[^#]" /etc/fstab; then \
		# Desativa a memória swap \
		sudo swapoff -a \
	fi