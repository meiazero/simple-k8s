EXEC = main

FLAVOR = $(shell lsb_release -i | cut -d ':' -f2 | tr -d '[:space:]')
PROM_DOWNLOAD_LINK = https://github.com/prometheus/prometheus/releases/download/v2.37.5/prometheus-2.37.5.linux-amd64.tar.gz
EXPO_DOWNLOAD_LINK = https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
PROM_COMPRESSED = prometheus.tar.gz
EXPO_COMPRESSED = node_exporter.tar.gz
PROM_LONG_NAME = prometheus-2.37.5.linux-amd64
EXPO_LONG_NAME = node_exporter-1.5.0.linux-amd64
PROM_ETC = /etc/prometheus
PROM = prometheus
EXPO = node_exporter
SYSTEMD= /etc/systemd/system
USER = $(shell whoami)
MKDIR = mkdir -p
DIR = /home/$(USER)
PWD = $(shell pwd)
MPKG = apt-get
RM = rm -rf
CPR = cp -R
CP = cp

all: $(EXEC)

$(EXEC): dependencies files prometheus node_exporter grafana microk8s

dependencies: 
	@echo "+ sudo $(MPKG) update -qq >/dev/null"
	@sudo $(MPKG) update -qq >/dev/null
	@echo "+ sudo $(MPKG) install -qq -y curl git snapd adduser apt-transport-https software-properties-common wget >/dev/null"
	@sudo $(MPKG) install -qq -y curl git snapd adduser apt-transport-https software-properties-common wget >/dev/null

debian:
	@if test ! $(FLAVOR) = "Debian"; then \
		echo "+ sudo snap install core snapd > /dev/null "; \
		sudo snap install core snapd > /dev/null ; \
	else \
		echo "+ debian dependencies ok"; \
	fi

dir: 
	@echo "+ $(MKDIR) $(DIR)/container/"
	@$(MKDIR) $(DIR)/container/
	
files: dir
	@echo "+ $(CPR) configs/web/ $(DIR)/container/" 
	@$(CPR) configs/web/ $(DIR)/container/
	@echo "+ $(CP) nginx-pod.yaml $(DIR)/container/"
	@$(CP) pod-nginx.yaml $(DIR)/container/
	@echo "+ $(CP) deploy-nginx.yaml $(DIR)/container/"
	@$(CP) deploy-nginx.yaml $(DIR)/container 

microk8s:
	@if test !  $(shell ls /snap/bin | grep -i microk8s | cut -d '.' -f3 | tr -d '[:space:]'); then \
		echo "+ sudo snap install microk8s --classic > /dev/null" ; \
		sudo snap install microk8s --classic > /dev/null ; \
	else \
		echo "+ microk8s installed"; \
	fi

prometheus: download_prom rename_prom_dir check_prom_user check_prom_bin
# cria o diretorio do prometheus em /etc e /var/lib, depois muda as permissões dele 
	@echo "+ sudo $(MKDIR) /etc/$(PROM)/"
	@sudo $(MKDIR) /etc/$(PROM)/
	@echo "+ sudo $(MKDIR) /var/lib/$(PROM)/"
	@sudo $(MKDIR) /var/lib/$(PROM)/
	@echo "+ sudo chown prometheus:prometheus /etc/$(PROM)/"
	@sudo chown prometheus:prometheus /etc/$(PROM)/
	@echo "+ sudo chown prometheus:prometheus /var/lib/$(PROM)/"
	@sudo chown prometheus:prometheus /var/lib/$(PROM)/
# copia configuração do prometheus, muda a permissão dos arquivos para o usuário prometheus
	@echo "+ sudo $(CP) configs/prometheus.yml $(PROM_ETC)/"
	@sudo $(CP) configs/prometheus.yml $(PROM_ETC)/
	@echo "+ sudo $(CP) configs/alert.rules $(PROM_ETC)/"
	@sudo $(CP) configs/alert.rules $(PROM_ETC)/
	@echo "+ sudo chown prometheus:prometheus $(PROM_ETC)/prometheus.yml"
	@sudo chown prometheus:prometheus $(PROM_ETC)/prometheus.yml
# copia os arquivos de ui para /etc/prometheus, muda as permissões para o usuário prometheus
	@echo "+ sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/"
	@sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/
	@echo "+ sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/"
	@sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/ 
	@echo "+ sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/"
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/
	@echo "+ sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/"
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/
# copia o arquivo de serviço para o systemd, reinicia o systemd, registra e inicia o serviço do prometheus
	@echo "+ sudo $(CP) configs/prometheus.service $(SYSTEMD)/"
	@sudo $(CP) configs/prometheus.service $(SYSTEMD)/
	@echo "+ sudo systemctl daemon-reload"
	@sudo systemctl daemon-reload
	@echo "+ sudo systemctl enable prometheus"
	@sudo systemctl enable prometheus
	@echo "+ sudo systemctl start prometheus"
	@sudo systemctl start prometheus

download_prom: 
	@if test ! -f $(PROM_COMPRESSED); then \
		echo "+ wget $(PROM_DOWNLOAD_LINK) -O $(PROM_COMPRESSED) --quiet"; \
		wget $(PROM_DOWNLOAD_LINK) -O $(PROM_COMPRESSED) --quiet; \
	else \
		echo "+ prometheus.tar.gz exist"; \
	fi
# acima verifica se o arquivo comprimido do prometheus existe, se não existir ele faz o download 

rename_prom_dir:
	@if test ! -d $(PROM); then \
		echo "+ tar -xzf $(PROM_COMPRESSED)" ; \
		tar -xzf $(PROM_COMPRESSED); \
		echo "+ mv $(PROM_LONG_NAME) $(PROM)" ; \
		mv $(PROM_LONG_NAME) $(PROM); \
	else \
		echo "+ prometheus has already been decompressed"; \
	fi
# acima verifica se o diretorio do prometheus descompactado existe, se não existir ele vai descompactar e renomear o diretorio  

check_prom_user:
	@if test ! $(shell id -u prometheus); then \
		echo "+ sudo useradd --no-create-home --shell /bin/false $(PROM)"; \
		sudo useradd --no-create-home --shell /bin/false $(PROM); \
	else \
		echo "+ user $(PROM) already exists"; \
	fi
# acima faz a verificaçao se o usuario prometheus existe, se não existir ele cria o usuario

check_prom_bin:
	@if test ! $(shell ls /usr/local/bin | grep -i $(PROM)); then \
		echo "+ sudo $(CP) $(PROM)/$(PROM) /usr/local/bin/ " ; \
		sudo $(CP) $(PROM)/$(PROM) /usr/local/bin/ ; \
		echo "+ sudo $(CP) $(PROM)/promtool /usr/local/bin/ " ; \
		sudo $(CP) $(PROM)/promtool /usr/local/bin/  ; \
		echo "+ sudo chown prometheus:prometheus /usr/local/bin/$(PROM)" ; \
		sudo chown prometheus:prometheus /usr/local/bin/$(PROM) ; \
		echo "+ sudo chown prometheus:prometheus /usr/local/bin/promtool" ; \
		sudo chown prometheus:prometheus /usr/local/bin/promtool ; \
	else \
		echo "+ prometheus already copied "; \
	fi
# acima verifica se o binario do prometheus e promtools existe, se não existir ele copia o binario para o /usr/local/bin/ e muda a permissão para o usuario prometheus

node_exporter: download_expo rename_expo_dir check_expo_user check_expo_bin
# copia o arquivo de serviço para o systemd, reinicia o systemd, registra e inicia o serviço do node_exporter 
	@echo "+ sudo $(CP) configs/node_exporter.service $(SYSTEMD)/"
	@sudo $(CP) configs/node_exporter.service $(SYSTEMD)/
	@echo "+ sudo systemctl daemon-reload"
	@sudo systemctl daemon-reload
	@echo "+ sudo systemctl enable node_exporter"
	@sudo systemctl enable node_exporter
	@echo "+ sudo systemctl start node_exporter"
	@sudo systemctl start node_exporter

download_expo: 
	@if test ! -f $(EXPO_COMPRESSED); then \
		echo "+ wget $(EXPO_DOWNLOAD_LINK) -O $(EXPO_COMPRESSED) --quiet"; \
		wget $(EXPO_DOWNLOAD_LINK) -O $(EXPO_COMPRESSED) --quiet; \
	else \
		echo "+ node_exporter.tar.gz existing "; \
	fi
# acima verifica se o arquivo comprimido do node_exporter existe, se não existir ele faz o download 

rename_expo_dir:
	@if test ! -d $(EXPO); then \
		echo "+ tar -xzf $(EXPO_COMPRESSED)" ; \
		tar -xzf $(EXPO_COMPRESSED); \
		echo "+ mv $(EXPO_LONG_NAME) $(EXPO)" ; \
		mv $(EXPO_LONG_NAME) $(EXPO); \
	else \
		echo "+ node_exporter has already been decompressed"; \
	fi
# acima verifica se o diretorio do node_exporter descompactado existe, se não existir ele vai descompactar e renomear o diretorio

check_expo_user:
	@if test ! $(shell id -u node_exporter ); then \
		echo "+ sudo useradd --no-create-home --shell /bin/false $(EXPO)"; \
		sudo useradd --no-create-home --shell /bin/false $(EXPO); \
    else \
		echo "+ user node_exporter already exists"; \
    fi
# acima faz a verificaçao se o usuario node_exporter existe, se não existir ele cria o usuario

check_expo_bin:
	@if test ! $(shell ls /usr/local/bin | grep -i $(EXPO)); then \
		echo "+ sudo $(CP) $(EXPO)/$(EXPO) /usr/local/bin/" ; \
        sudo $(CP) $(EXPO)/$(EXPO) /usr/local/bin/ ; \
		echo "+ sudo chown node_exporter:node_exporter /usr/local/bin/$(EXPO)" ; \
		sudo chown node_exporter:node_exporter /usr/local/bin/$(EXPO) ; \
	else \
		echo "+ node_exporter already copied"; \
	fi
# acima verifica se o binario do node_exporter existe, se não existir ele copia o binario para o /usr/local/bin/ e muda a permissão para o usuario node_exporter

grafana: grafana_add_repo
# faz a instalação do grafana via gerenciador de pacotes (apt), reiniar o systemd e inicia o serviço do grafana
	@echo "+ sudo $(MPKG) install -y -qq grafana > /dev/null"
	@sudo $(MPKG) install -y -qq grafana > /dev/null
	@echo "+ systemctl daemon-reload"
	@sudo systemctl daemon-reload
	@echo "+ sudo systemctl enable grafana-server"
	@sudo systemctl enable grafana-server
	@echo "+ sudo systemctl start grafana-server"
	@sudo systemctl start grafana-server

grafana_add_repo: grafana_key
	@if test ! $(shell ls /etc/apt/sources.list.d | grep -i grafana); then \
		echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list ; \
		echo " + $(MPKG) update -qq > /dev/null  " ; \
		sudo $(MPKG) update -qq > /dev/null ; \
	else: \
		echo "+ grafana apt repository already exists "; \
	fi
# acima verifica se o repositorio do grafana existe, se não existir ele adiciona o repositorio do grafana

grafana_key:
	@echo "+ sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key"
	@sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
# acima faz o download da chave do grafana

clear:
# remove os arquivos baixados e descompactados
	@echo "+ $(RM) $(PROM) $(PROM_COMPRESSED)"
	@$(RM) $(PROM) $(PROM_COMPRESSED) 
	@echo "+ $(RM) $(EXPO) $(EXPO_COMPRESSED)"
	@$(RM) $(EXPO) $(EXPO_COMPRESSED)

# TODO: testar instalação de Node Exporter
# TODO: testar instalação do Grafana
