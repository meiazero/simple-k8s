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
		echo "DEPENDENCIES FOR DEBIAN ALREADY INSTALLED\n"; \
	fi

dir: 
	@echo "+ $(MKDIR) $(DIR)/container/"
	@$(MKDIR) $(DIR)/container/
	
files: dir
	@echo "+ $(CPR) configs/web/ $(DIR)/container/" 
	@$(CPR) configs/web/ $(DIR)/container/
	@echo "+ $(CP) nginx-pod.yaml $(DIR)/container/"
	@$(CP) nginx-pod.yaml $(DIR)/container/

microk8s:
	@if test !  $(shell ls /snap/bin | grep -i microk8s | cut -d '.' -f3 | tr -d '[:space:]'); then \
		echo "+ sudo snap install microk8s --classic > /dev/null" ; \
		sudo snap install microk8s --classic > /dev/null ; \
	else \
		echo "MICROK8S IS INSTALLED....\n"; \
	fi

prometheus: download_prom rename_prom_dir check_prom_user check_prom_bin
	@echo "+ sudo $(MKDIR) /etc/$(PROM)/"
	@sudo $(MKDIR) /etc/$(PROM)/
	@echo "+ sudo $(MKDIR) /var/lib/$(PROM)/"
	@sudo $(MKDIR) /var/lib/$(PROM)/
	@echo "+ sudo chown prometheus:prometheus /etc/$(PROM)/"
	@sudo chown prometheus:prometheus /etc/$(PROM)/
	@echo "+ sudo chown prometheus:prometheus /var/lib/$(PROM)/"
	@sudo chown prometheus:prometheus /var/lib/$(PROM)/
# copia configuração de alvos do prometheus
	@echo "+ sudo $(CP) configs/prometheus.yml $(PROM_ETC)/"
	@sudo $(CP) configs/prometheus.yml $(PROM_ETC)/
	@echo "+ sudo $(CP) configs/alert.rules $(PROM_ETC)/"
	@sudo $(CP) configs/alert.rules $(PROM_ETC)/
# muda a permissão do arquivo de prometheus para o usuário prometheus
	@echo "+ sudo chown prometheus:prometheus $(PROM_ETC)/prometheus.yml"
	@sudo chown prometheus:prometheus $(PROM_ETC)/prometheus.yml
# copia os arquivos de configuração do prometheus
	@echo "+ sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/"
	@sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/
	@echo "+ sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/"
	@sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/ 
	@echo "+ sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/"
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/
	@echo "+ sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/"
	@sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/
# copia o arquivo de serviço para o systemd
	@echo "+ sudo $(CP) configs/prometheus.service $(SYSTEMD)/"
	@sudo $(CP) configs/prometheus.service $(SYSTEMD)/
# reinicia o systemd, registra e inicia o serviço do prometheus
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
		echo "PROMETHEUS.TAR.GZ EXISTING\n"; \
	fi

rename_prom_dir:
	@if test ! -d $(PROM); then \
		echo "+ tar -xzf $(PROM_COMPRESSED)" ; \
		tar -xzf $(PROM_COMPRESSED); \
		echo "+ mv $(PROM_LONG_NAME) $(PROM)" ; \
		mv $(PROM_LONG_NAME) $(PROM); \
	else \
		echo "PROMETHEUS HAS ALREADY BEEN DECOMPRESSED\n"; \
	fi

check_prom_user:
	@if test ! $(shell id -u prometheus); then \
		echo "+ sudo useradd --no-create-home --shell /bin/false $(PROM)"; \
		sudo useradd --no-create-home --shell /bin/false $(PROM); \
	else \
		echo "USER PROMETHEUS ALREADY EXISTS\n"; \
	fi

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
		echo "PROMETHEUS ALREADY COPIED\n"; \
	fi

node_exporter: download_expo rename_expo_dir check_expo_user check_expo_bin
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
		echo "NODE_EXPORTER.TAR.GZ EXISTING\n"; \
	fi

rename_expo_dir:
	@if test ! -d $(EXPO); then \
		echo "+ tar -xzf $(EXPO_COMPRESSED)" ; \
		tar -xzf $(EXPO_COMPRESSED); \
		echo "+ mv $(EXPO_LONG_NAME) $(EXPO)" ; \
		mv $(EXPO_LONG_NAME) $(EXPO); \
	else \
		echo "NODE EXPORTER HAS ALREADY BEEN DECOMPRESSED\n"; \
	fi

check_expo_user:
	@if test ! $(shell id -u node_exporter ); then \
		echo "+ sudo useradd --no-create-home --shell /bin/false $(EXPO)"; \
		sudo useradd --no-create-home --shell /bin/false $(EXPO); \
    else \
		echo "USER NODE_EXPORTER ALREADY EXISTS\n"; \
    fi

check_expo_bin:
	@if test ! $(shell ls /usr/local/bin | grep -i $(EXPO)); then \
		echo "+ sudo $(CP) $(EXPO)/$(EXPO) /usr/local/bin/" ; \
        sudo $(CP) $(EXPO)/$(EXPO) /usr/local/bin/ ; \
		echo "+ sudo chown node_exporter:node_exporter /usr/local/bin/$(EXPO)" ; \
		sudo chown node_exporter:node_exporter /usr/local/bin/$(EXPO) ; \
	else \
		echo "NODE_EXPORTER ALREADY COPIED\n"; \
	fi

grafana: grafana_add_repo
	@echo "+ sudo $(MPKG) install -y -qq grafana > /dev/null"
	@sudo $(MPKG) install -y -qq grafana > /dev/null
	@echo "+ systemctl daemon-reload"
	@sudo systemctl daemon-reload
	@echo "+ sudo systemctl start grafana-server"
	@sudo systemctl start grafana-server

grafana_key:
	@echo "+ sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key"
	@sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key

grafana_add_repo: grafana_key
	@if test ! -f $(ls /etc/apt/sources.list.d | grep -i grafana); then \
		echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list ; \
		echo "\n+ $(MPKG) update -qq > /dev/null \n" ; \
		sudo $(MPKG) update -qq > /dev/null ; \
	else: \
		echo "GRAFANA REPOSITORY ALREADY EXISTS\n"; \
	fi

clear: 
	@echo "+ $(RM) $(PROM) $(PROM_COMPRESSED)"
	@$(RM) $(PROM) $(PROM_COMPRESSED) 
	@echo "+ $(RM) $(EXPO) $(EXPO_COMPRESSED)"
	@$(RM) $(EXPO) $(EXPO_COMPRESSED)

# TODO: testar instalação de Node Exporter
# TODO: testar instalação do Grafana