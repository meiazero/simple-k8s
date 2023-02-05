# single-k8s

> The configs to single cluster using Kubernetes

This repo contain the files necessary to up the Pods with Services using kubernetes.

### Dependencies

[make](https://www.gnu.org/software/make/) <br/>

if your distro is debian, you can install using this command:

```bash
make debian

```

### Installations:

[microk8s](https://microk8s.io/#install-microk8s) <br/>
[prometheus](https://prometheus.io/docs/introduction/overview/)

### Usage:

clone the repo: <br/>

```bash
git clone https://github.com/meiazero/single-k8s.git
```

<br/>
clone specific branch:

```bash
git clone https://github.com/meiazero/single-k8s.git --branch main

or

git clone https://github.com/meiazero/single-k8s.git --branch dev
```

only on repo: <br/>

```bash
cd single-k8s
```

run this command: <br/>

```bash
make
```

### After installation:

_delete the repository and make sure the 'container' directory is created in your /home/$USER_

### Also make sure the microk8s has startup using this command:

```bash
microk8s status --wait-ready
```

## finally:

read the documentation on [microk8s.io](https://microk8s.io/docs)

<br/>
<hr/>
<br/>
This personal project has an LGPL license, its distribution is accepted free of charge, under the same or similar license. <br/><br/>
LICENSE: GNU Lesser General Public License (LGPL) <br/><br/>

Maintainer: [meiazero](https://github.com/meiazero)
