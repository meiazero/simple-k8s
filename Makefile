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
		echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
		curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
		sudo apt update && sudo apt install -y kubectl kubeadm kubelet; \
		sudo rm /etc/containerd/config.toml; \
		sudo systemctl restart containerd ; \
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
	@echo "Copiando 'config/prometheus/*' -> '/home/$(shell whoami)/container/prometheus/'"
	cp -R configs/prometheus /home/$(shell whoami)/container/
	@echo "Copiando 'config/web/*' -> '/home/$(shell whoami)/container/web/'"
	cp -R configs/web /home/$(shell whoami)/container/
	@echo "-----------------------------\nArquivos copiados com sucesso...\n-----------------------------\n"
	cp -R pods /home/$(shell whoami)/container/
	cp -R services /home/$(shell whoami)/container/

init_cluster: check_k8s check_swap
	@echo "=======================\nPronto para iniciar cluster\n=======================\n";
	

check_swap:
	@if grep -q "^[^#]" /etc/fstab; then \
		sudo swapoff -a; \
	fi