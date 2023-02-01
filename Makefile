all: directories files install_microk8s init_cluster

check_docker:
	@echo "=======================\nVerificando Docker\n=======================\n";
	@if test ! -x "$(shell which docker)"; then \
		echo "\n\tDocker não encontrado. Instalando Docker...\n"; \
		sudo apt-get install -y apt-transport-https ca-certificates curl snapd;\
		curl -fsSL get.docker.com | sh; \
	else \
		echo "Docker está instalado\n"; \
	fi

install_microk8s:
	@echo "=======================\nVerificando Micro-K8s\n=======================\n";
	@if test ! -x "$(shell which microk8s)"; then \
		@echo "\n\Micro K8s não encontrado. Instalando Micro K8s...\n"; \
		sudo snap install microk8s --classic --channel=1.26; \
	else \
		echo "Micro K8s está instalado\n"; \
	fi
	

directories:
	@echo "=======================\nCriando diretórios\n=======================\n"; \
	mkdir -p /home/$(shell whoami)/container/web \
			/home/$(shell whoami)/container/prometheus \
			/home/$(shell whoami)/container/portainer;
	@echo "Criando diretório -> 'container'\nCriando diretório -> 'container/web'\nCriando diretório -> 'container/prometheus'\nCriando diretório -> 'container/portainer'\n"

files: directories
	@echo "=======================\nCopiando arquivos\n=======================\n";  
	@echo "Copiando 'config/prometheus/*' -> '/home/$(shell whoami)/container/prometheus/'" ; \
	cp -R configs/prometheus /home/$(shell whoami)/container/ ;
	@echo "Copiando 'config/web/*' -> '/home/$(shell whoami)/container/web/'" ;\
	cp -R configs/web /home/$(shell whoami)/container/ ;
	@echo "Copiando 'nginx-pod.yaml' -> '/home/$(shell whoami)/container/''" ;\
	cp nginx-pod.yaml /home/$(shell whoami)/container/ ;
	@echo "-----------------------------\nArquivos copiados com sucesso...\n-----------------------------\n" ;

init_cluster: install_microk8s check_swap
	@echo "\n=======================\nPronto para iniciar cluster\n=======================\n\n'microk8s status --wait-ready'\n\nCaso nao haja kubectl instalado no sistema, use um alias para o microk8s\nadicione em seu .bashrc ou .zshrc essa linha:\n\talias kubectl='microk8s kubectl'\ncheque os pods, nodes e services com:\n kubectl get services\nkubectl get pods --all-namespaces\nkubectl get nodes\n\npara parar o microk8s use:\nmicrok8s stop e microk8s start para iniciar";
	

check_swap:
	@if grep -q "^[^#]" /etc/fstab; then \
		sudo swapoff -a; \
		echo "Disable the swap memory on /etc/fstab."; \
	fi