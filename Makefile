EXEC = main

FLAVOR = $(shell lsb_release -i | cut -d ':' -f2 | tr -d '[:space:]')
PROM_ETC = /etc/prometheus
SYSTEMD= /etc/systemd/system
USER = $(shell whoami)
MPKG = apt-get
RM = rm -rf

all: $(EXEC)

$(EXEC): dependencies files prometheus node_exporter grafana

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

microk8s:
	@if test !  $(shell ls /snap/bin | grep -i microk8s | cut -d '.' -f3 | tr -d '[:space:]'); then \
		echo "+ sudo snap install microk8s --classic > /dev/null" ; \
		sudo snap install microk8s --classic > /dev/null ; \
	else \
		echo "+ microk8s installed"; \
	fi

prometheus: prom_dir  prom_configs prom_ui prom_svc

prom_svc:
# copia o arquivo de serviço para o systemd, reinicia o systemd, registra e inicia o serviço do prometheus
	@if test ! -f $(SYSTEMD)/prometheus.service; then \
		echo "+ sudo $(CP) configs/prometheus.service $(SYSTEMD)/" ; \
		sudo $(CP) configs/prometheus.service $(SYSTEMD)/ ; \
		echo "+ sudo systemctl daemon-reload" ; \
		sudo systemctl daemon-reload ; \
		echo "+ sudo systemctl enable prometheus" ; \
		sudo systemctl enable prometheus ; \
		echo "+ sudo systemctl start prometheus" ; \
		sudo systemctl start prometheus ; \
	else \
		echo "+ prometheus service already created"; \
	fi

prom_dir:  rename_prom_dir 
# cria o diretorio do prometheus em /etc e /var/lib, depois muda as permissões dele 
	@if test ! -d /etc/$(PROM); then \
		echo "+ sudo $(MKDIR) /etc/$(PROM)/" ; \
		sudo $(MKDIR) /etc/$(PROM)/ ; \
		echo "+ sudo $(MKDIR) /var/lib/$(PROM)/" ; \
		sudo $(MKDIR) /var/lib/$(PROM)/ ; \
		echo "+ sudo chown prometheus:prometheus /etc/$(PROM)/" ; \
		sudo chown prometheus:prometheus /etc/$(PROM)/ ; \
		echo "+ sudo chown prometheus:prometheus /var/lib/$(PROM)/" ; \
		sudo chown prometheus:prometheus /var/lib/$(PROM)/ ; \
	else \
		echo "+ prometheus directories already created"; \
	fi

check_prom_user: check_prom_user
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

prom_configs: 
	@if test ! $(shell ls $(PROM_ETC)/ | grep -i $(PROM)); then \
		echo "+ sudo $(CP) configs/prometheus.yml $(PROM_ETC)/" ; \
		sudo $(CP) configs/prometheus.yml $(PROM_ETC)/ ; \
		echo "+ sudo $(CP) configs/alert.rules $(PROM_ETC)/" ; \
		sudo $(CP) configs/alert.rules $(PROM_ETC)/ ; \
		echo "+ sudo chown $(PROM):$(PROM) $(PROM_ETC)/prometheus.yml" ; \
		sudo chown $(PROM):$(PROM) $(PROM_ETC)/prometheus.yml ; \
		echo "+ sudo chown $(PROM):$(PROM) $(PROM_ETC)/alert.rules" ; \
		sudo chown $(PROM):$(PROM) $(PROM_ETC)/alert.rules ; \
	else \
		echo "+ prometheus configs already copied"; \
	fi

prom_ui:
	@if test ! -d $(PROM_ETC)/consoles/; then \
		echo "+ sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/" ; \
		sudo $(CPR) $(PROM)/consoles/ $(PROM_ETC)/ ; \
		echo "+ sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/" ; \
		sudo $(CPR) $(PROM)/console_libraries/ $(PROM_ETC)/ ; \
		echo "+ sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/" ; \
		sudo chown -R prometheus:prometheus $(PROM_ETC)/consoles/ ; \
		echo "+ sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/" ; \
		sudo chown -R prometheus:prometheus $(PROM_ETC)/console_libraries/ ; \
	else \
		echo "+ prometheus ui already copied" ; \
	fi

node_exporter: expo_user_check expo_svc

expo_svc:
# copia o arquivo de serviço para o systemd, reinicia o systemd, registra e inicia o serviço do node_exporter 
	@if test ! -f $(SYSTEMD)/node_exporter.service; then \
		echo "+ sudo $(CP) configs/node_exporter.service $(SYSTEMD)/" ; \
		sudo $(CP) configs/node_exporter.service $(SYSTEMD)/ ; \
		echo "+ sudo systemctl daemon-reload" ; \
		sudo systemctl daemon-reload ; \
		echo "+ sudo systemctl enable node_exporter" ; \
		sudo systemctl enable node_exporter ; \
		echo "+ sudo systemctl start node_exporter" ; \
		sudo systemctl start node_exporter ; \
	else \
		echo "+ node_exporter service already copied"; \
	fi
ifica se o diretorio do node_exporter descompactado existe, se não existir ele vai descompactar e renomear o diretorio

expo_user_check: expo_bin_check
	@if test ! $(shell id -u node_exporter ); then \
		echo "+ sudo useradd --no-create-home --shell /bin/false $(EXPO)"; \
		sudo useradd --no-create-home --shell /bin/false $(EXPO); \
    else \
		echo "+ user node_exporter already exists"; \
    fi
# acima faz a verificaçao se o usuario node_exporter existe, se não existir ele cria o usuario

expo_bin_check:
	@if test ! $(shell ls /usr/local/bin | grep -i $(EXPO)); then \
		echo "+ sudo $(CP) $(EXPO)/$(EXPO) /usr/local/bin/" ; \
        sudo $(CP) $(EXPO)/$(EXPO) /usr/local/bin/ ; \
		echo "+ sudo chown node_exporter:node_exporter /usr/local/bin/$(EXPO)" ; \
		sudo chown node_exporter:node_exporter /usr/local/bin/$(EXPO) ; \
	else \
		echo "+ node_exporter already copied"; \
	fi
# acima verifica se o binario do node_exporter existe, se não existir ele copia o binario para o /usr/local/bin/ e muda a permissão para o usuario node_exporter

grafana: grafana_install
	@if test ! $(shell ls /usr/lib/systemd/system/ | grep -i grafana ); then \
		echo "+ systemctl daemon-reload" ; \
		sudo systemctl daemon-reload ; \
		echo "+ sudo systemctl enable grafana-server" ; \
		sudo systemctl enable grafana-server ; \
		echo "+ sudo systemctl start grafana-server" ; \
		sudo systemctl start grafana-server ; \
	else \
		echo "+ grafana service already started"; \
	fi

grafana_install: grafana_key grafana_add_repo
# faz a instalação do grafana via gerenciador de pacotes (apt), reiniar o systemd e inicia o serviço do grafana
	@if test ! $(shell which grafana-server); then \
		echo "+ sudo $(MPKG) install -y -qq grafana > /dev/null" ; \
		sudo $(MPKG) install -y -qq grafana > /dev/null ; \
	else \
		echo "+ grafana already installed"; \
	fi

grafana_add_repo: grafana_key
	@if test ! $(shell ls /etc/apt/sources.list.d | grep -i grafana); then \
		echo "+ add grafana apt repository" ; \
		echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list ; \
		echo " + $(MPKG) update -qq > /dev/null  " ; \
		sudo $(MPKG) update -qq > /dev/null ; \
	else \
		echo "+ grafana apt repository already exists "; \
	fi
# acima verifica se o repositorio do grafana existe, se não existir ele adiciona o repositorio do grafana

grafana_key:
# acima faz o download da chave do grafana
	@if test ! $(shell ls /usr/share/keyrings | grep -i grafana); then \
		echo "+ sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key" ; \
		sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key ; \
	else \
		echo "+ download grafana key to /usr/share/keyrings"; \
	fi

kubernetes: install_k8s
	@echo "+ sudo apt-mark hold kubeadm kubelet kubectl"
	@sudo apt-mark hold kubeadm kubelet kubectl >/dev/null

install_k8s: kubernetes_add_repo
# faz a instalação do kubernetes via gerenciador de pacotes (apt), reiniar o systemd e inicia o serviço do kubernetes
	@echo "+ sudo $(MPKG) install -y -qq kubeadm kubelet kubectl > /dev/null"
	@sudo $(MPKG) install -y -qq kubeadm kubelet kubectl > /dev/null
	@echo "+ systemctl daemon-reload"
	@sudo systemctl daemon-reload
	@echo "+ sudo systemctl enable kubelet"
	@sudo systemctl enable kubelet
	@echo "+ sudo systemctl start kubelet"
	@sudo systemctl start kubelet

kubernetes_add_repo:
	@if test ! $(shell ls /etc/apt/sources.list.d | grep -i kubernetes); then \
		echo "+ $(MKDIR) /etc/apt/keyrings/"
		sudo mkdir -p /etc/apt/keyrings/ 
		echo "+ sudo wget -q -O /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg" ; \
		sudo wget -q -O /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg ; \
		echo "+ adding kubernetes repository" ; \
		echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list ; \
		echo "+ $(MPKG) update -qq > /dev/null  " ; \
		sudo $(MPKG) update -qq > /dev/null ; \
	else \
		echo "+ kubernetes apt repository already exists "; \
	fi

clear: prom_clear expo_clear

prom_clear:
	@if test $(shell ls | grep -i $(PROM)); then \
		echo "+ $(RM) $(PROM) $(PROM_COMPRESSED)" ; \
		$(RM) $(PROM) $(PROM_COMPRESSED) ; \
	else \
		echo "+ Prometheus already clear"; \
	fi
	
expo_clear:
	@if test $(shell ls | grep -i $(EXPO)); then \
		echo "+ $(RM) $(EXPO) $(EXPO_COMPRESSED)" ; \
		$(RM) $(EXPO) $(EXPO_COMPRESSED) ; \
	else \
		echo "+ Node Exporter already clear"; \
	fi 