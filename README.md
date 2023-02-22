# Simple-k8s
  

> The script installs  Kubernetes with [microk8s](https://microk8s.io/#install-microk8s) and a stack for monitoring. 
 
This repository contains the files needed to a service and pod with the  monitoring stack using  [prometheus](https://prometheus.io/docs/introduction/overview/), [node_exporter](https://prometheus.io/docs/guides/node-exporter/) and [grafana](https://grafana.com/docs/grafana/latest/installation/debian/).

:warning: The script is restricted for studies, don't use it in production or on your personal machine.

## **:pencil: What's installing?** 
[microk8s](https://microk8s.io/#install-microk8s) :heavy_check_mark:,
[Prometheus](https://prometheus.io/docs/introduction/overview/) :heavy_check_mark:,
[Node Exporter](https://prometheus.io/docs/guides/node-exporter/) :heavy_check_mark:,
[Grafana](https://grafana.com/docs/grafana/latest/installation/debian/) :hourglass:, 
[kubernetes](kubernetes.io/) :hourglass:

## **:pushpin: Requirements:**
Installs the [make](https://www.gnu.org/software/make/) using your  package manager.
```bash
sudo apt install make
```

## **:computer: Installation** 
clone the repository: 
```bash
git clone  https://github.com/meiazero/simple-k8s.git
```

*clone specific branch:*
```bash
git clone  https://github.com/meiazero/simple-k8s.git  --branch  main
or
git clone  https://github.com/meiazero/simple-k8s.git  --branch  dev
```
<br/>

**:file_folder: Inside the directory:**
```bash
cd  simple-k8s
```
**:running: Run this command**
```bash
make
```
**If your distro is Debian, also run this command :**
```bash
make debian
```

## **:fire: After installation:** 
_delete the repository and make sure the 'container' directory is created in your /home/$USER_

## **:pray: Testing microk8s** 
```bash
microk8s status  --wait-ready
```

## **:grin: More :**
Read the documentation on [microk8s.io](https://microk8s.io/docs) :book:
<hr/>

**Maintainer**: [meiazero](https://github.com/meiazero)

**LICENSE**: GNU Lesser General Public License (LGPL)
*This personal project has an LGPL license, its distribution is accepted free of charge, under the same or similar license.* 
 