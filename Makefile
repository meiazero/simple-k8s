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
	@echo "CREATING DIRECTORY 'CONTAINER'...\n"
	@$(MKDIR) $(DIR)/container/
	@echo "\n"
	
files: dir
	@echo "COPYING FILES...\n" 
	@$(CPR) configs/web/ $(DIR)/container/
	@$(CP) nginx-pod.yaml $(DIR)/container/

microk8s:
	@if test ! -x $(shell which microk8s); then \
		echo "INSTALLING MICROK8S....\n" ; \
		sudo snap install microk8s --classic; \
	else \
		echo "MICROK8S IS INSTALLED....\n"; \
	fi

prometheus: download_prom rename_prom_dir check_prom_user
	@echo "CREATING DIRECTORY PROMETHEUS...\n"
	@sudo $(MKDIR) /etc/$(PROM)/
	@sudo $(MKDIR) /var/lib/$(PROM)/
	@echo "CHANGING PROMETHEUS FILES PERMISSIONS...\n"
	@sudo chown prometheus:prometheus /etc/$(PROM)/
	@sudo chown prometheus:prometheus /var/lib/$(PROM)/
# copia configuração de alvos do prometheus
	@echo "COPYING CONFIGURATION FILES AND RULES OF PROMETHEUS...\n"
	@sudo $(CP) configs/prometheus.yml $(PROM_ETC)/
	@sudo $(CP) configs/alert.rules $(PROM_ETC)/
# muda a permissão do arquivo de prometheus para o usuário prometheus
	@echo "CHANGING CONFIGURATION FILES PERMISSIONS...\n"
	@sudo chown prometheus:prometheus $(PROM_ETC)/prometheus.yml
# copia os binários configuração do prometheus e muda a permissão
	@echo "COPYING BINARY OF PROMETHEUS AND PROMTOOLS...\n"
	@sudo $(CP) $(PROM)/$(PROM) /usr/local/bin/
	@sudo $(CP) $(PROM)/promtool /usr/local/bin/
	@echo "CHANGING BINARY EXECUTE PERMISSION...\n"
	@sudo chown prometheus:prometheus /usr/local/bin/$(PROM)
	@sudo chown prometheus:prometheus /usr/local/bin/promtool
# copia os arquivos de configuração do prometheus
	@echo "COPYING UI FILES...\n" 	
	@sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/ 
	@sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/ 
	@echo "CHANGING PERMISSIONS DOS UI FILES...\n"
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/
# copia o arquivo de serviço para o systemd
	@echo "COPYING PROMETHEUS.SERVICE...\n"
	@sudo $(CP) configs/prometheus.service $(SYSTEMD)/
# reinicia o systemd, registra e inicia o serviço do prometheus
	@echo "RESTART SYSTEMD...\n"
	@sudo systemctl daemon-reload
	@echo "START PROMETHEUS SERVICE...\n"
	@sudo systemctl start prometheus

download_prom: 
	@if test ! -f $(PROM_ARCHIVE_COMPACT); then \
		echo "DOWNLOADING PROMETHEUS...\n"; \
		wget $(PROM_DOWNLOAD_LINK) -O $(PROM_ARCHIVE_COMPACT) --quiet; \
	else \
		echo "PROMETHEUS.TAR.GZ EXISTING\n"; \
	fi

rename_prom_dir:
	@if test ! -d $(PROM); then \
		tar -xzf $(PROM_ARCHIVE_COMPACT); \
		mv $(PROM_LONG_NAME) $(PROM); \
		echo "PROMETHEUS DECOMPRESSED\n"; \
	else \
		echo "PROMETHEUS HAS ALREADY BEEN DECOMPRESSED\n"; \
	fi

check_prom_user:
	@if test ! $(shell id -u prometheus); then \
		echo "CREATING USER PROMETHEUS...\n"; \
		sudo useradd --no-create-home --shell /bin/false $(PROM); \
	else \
		echo "USER PROMETHEUS ALREADY EXISTS\n"; \
	fi

clean: 
# TODO: apagar os arquivos do prometheus depois de copiar para o host.