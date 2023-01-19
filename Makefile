all: directories files check_docker install_microk8s init_cluster

check_docker:
	@echo "=======================\nVerificando Docker\n=======================\n";
	@if test ! -x "$(shell which docker)"; then \
		echo "\n\tDocker não encontrado. Instalando Docker...\n"; \
		sudo apt-get install -y apt-transport-https ca-certificates curl snapd \
		curl -fsSL https://get.docker.com | sh; \
	else \
		echo "Docker está instalado\n"; \
	fi

install_microk8s:
	@echo "=======================\nVerificando Micro-K8s\n=======================\n";
	@if test ! -x "$(shell which microk8s)"; then \
		@echo "\n\Micro K8s não encontrado. Instalando Micro K8s...\n"; \
		sudo snap install microk8s --classic --channel=1.26; \
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
		@echo "Disable the swap memory on /etc/fstab."; \
	fi