EXEC = main

PROM_DOWNLOAD_LINK = https://github.com/prometheus/prometheus/releases/download/v2.37.5/prometheus-2.37.5.linux-amd64.tar.gz
PROM_ARCHIVE_COMPACT = prometheus.tar.gz
PROM_LONG_NAME = prometheus-2.37.5.linux-amd64
PROM_ETC = /etc/prometheus
PROM = prometheus
SYSTEMD= /etc/systemd/system
USER = $(shell whoami)
CP = cp 
CPR = cp -R
MKDIR = mkdir -pv
DIR = /home/$(USER)
RM = rm -rf
PWD = $(shell pwd)

all: $(EXEC)

$(EXEC): files prometheus microk8s

dir: 
	@echo "CRIANDO DIRETORIO 'CONTAINER'...\n"
	@$(MKDIR) $(DIR)/container/
	@echo "\n"
	
files: dir
	@echo "COPIANDO ARQUIVOS...\n" 
	@$(CPR) configs/web/ $(DIR)/container/
	@$(CP) nginx-pod.yaml $(DIR)/container/

microk8s:
	@if test ! -x $(shell which microk8s); then \
		echo "INSTALANDO MICROK8S....\n" ; \
		sudo snap install microk8s --classic; \
	else \
		echo "MICROK8S JÁ ESTÁ INSTALADO....\n"; \
	fi

prometheus: download_prom rename_prom_dir check_prom_user
	@echo "CRIANDO DIRETORIOS PROMETHEUS...\n"
	@sudo $(MKDIR) /etc/$(PROM)/
	@sudo $(MKDIR) /var/lib/$(PROM)/
	@echo "MUDANDO PERMISSOES ARQUIVOS PROMETHEUS...\n"
	@sudo chown prometheus:prometheus /etc/$(PROM)/
	@sudo chown prometheus:prometheus /var/lib/$(PROM)/
# copia configuração de alvos do prometheus
	@echo "COPIANDO CONFIGURACAO E REGRA DO PROMETHEUS...\n"
	@sudo $(CP) configs/prometheus.yml $(PROM_ETC)/
	@sudo $(CP) configs/alert.rules $(PROM_ETC)/
# muda a permissão do arquivo de prometheus para o usuário prometheus
	@echo "MUDANDO PERMISSOES DOS ARQUIVOS DE CONFIGURACAO...\n"
	@sudo chown prometheus:prometheus $(PROM_ETC)/prometheus.yml
# copia os binarios configuranção do prometheus e muda a permissão
	@echo "COPIANDO BINARIOS PROMETHEUS E PROMTOLLS...\n"
	@sudo $(CP) $(PROM)/$(PROM) /usr/local/bin/
	@sudo $(CP) $(PROM)/promtool /usr/local/bin/
	@echo "MUDANDO PERMISSOES DE EXECUCAO DOS BINARIOS...\n"
	@sudo chown prometheus:prometheus /usr/local/bin/$(PROM)
	@sudo chown prometheus:prometheus /usr/local/bin/promtool
# copia os arquivos de configuração do prometheus
	@echo "COPIANDO ARQUIVOS DA UI...\n" 	
	@sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/ 
	@sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/ 
	@echo "MUDANDO PERMISSOES DOS ARQUIVOS DE UI...\n"
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/
# copia o arquivo de service para o systemd
	@echo "COPIANDO PROMETHEUS.SERVICE...\n"
	@sudo $(CP) configs/prometheus.service $(SYSTEMD)/
# reinicia o systemd, registra e inicia o serviço do prometheus
	@echo "REINICIANDO SYSTEMD...\n"
	@sudo systemctl daemon-reload
	@echo "REINICIANDO SERVICO DO PROMETHEUS...\n"
	@sudo systemctl start prometheus

download_prom: 
	@if test ! -f $(PROM_ARCHIVE_COMPACT); then \
		echo "FAZENDO DOWNLOAD PROMETHEUS......\n"; \
		wget $(PROM_DOWNLOAD_LINK) -O $(PROM_ARCHIVE_COMPACT) --quiet; \
	else \
		echo "PROMETHEUS.TAR.GZ JA EXISTE\n"; \
	fi

rename_prom_dir:
	@if test ! -d $(PROM); then \
		tar -xzf $(PROM_ARCHIVE_COMPACT); \
		mv $(PROM_LONG_NAME) $(PROM); \
		echo "PROMETHEUS DESCOMPACTADO\n"; \
	else \
		echo "PROMETHEUS JA DESCOMPACTADO\n"; \
	fi

check_prom_user:
	@if test ! $(shell id -u prometheus); then \
		echo "CRIANDO USUARIO PROMETHEUS...\n"; \
		sudo useradd --no-create-home --shell /bin/false $(PROM); \
	else \
		echo "USUARIO PROMETHEUS JA EXISTE\n"; \
	fi

clean: 
# TODO: apagar os arquivos do prometheus depois de copiar para o host.

# TODO: mudar tudo para inglês	
# TODO: copia dos arquivos de prometheus/console e prometheus/