import os, subprocess, shlex, requests
from lambdas import verifyContainerExists, verifyExpoExists, verifyPromExists, verifyWebExists, verifyYamlExists

# Variáveis de ambiente
promLongName =  'prometheus-2.37.5.linux-amd64.tar.gz'
expoLongName = 'node_exporter-1.5.0.linux-amd64.tar.gz'
promCompressedName = 'prometheus.tar.gz'
expoCompressedName = 'node_exporter.tar.gz'
promDownloadLink = 'https://github.com/prometheus/prometheus/releases/download/v2.37.5/prometheus-2.37.5.linux-amd64.tar.gz'
expoDownloadLink = 'https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz'


def downloadProm():
    if verifyPromExists(promLongName, os.listdir('./')):
        print("+ file {} exists".format(promLongName))
    else:
        print("+ wget {} --quiet".format(promDownloadLink))
        promFullName = requests.get(promDownloadLink)
        open(promLongName, 'wb').write(promFullName.content)

def downloadExpo():
    if verifyExpoExists(expoLongName, os.listdir('./')):
        print("+ file {} exists".format(expoLongName))
    else:
        print("+ wget {} --quiet".format(expoDownloadLink))
        expoFullName = requests.get(expoDownloadLink)
        open(expoLongName, 'wb').write(expoFullName.content)

def decompressProm():
    ls = os.listdir('./')

    # check if the archive has decompressed
    if 'prometheus' in ls:
        print("+ archive 'prometheus' already decompressed")
    else:
        # decompress file prometheus
        subprocess.call(shlex.split('tar -xzf {}'.format(promLongName)))
        # change file to a short name
        os.rename('prometheus-2.37.5.linux-amd64', 'prometheus')

def decompressExpo():
    ls = os.listdir('./')

    # check if the archive has decompressed
    if 'node_exporter' in ls:
        print("+ archive 'node exporter' already decompressed")
    else:
        # decompress file node_exporter
        subprocess.call(shlex.split('tar -xzf {}'.format(expoLongName)))
        # change file to a short name
        os.rename('node_exporter-1.5.0.linux-amd64', 'node_exporter')

def createDirs():
    path = os.environ['HOME']

    if verifyContainerExists(os.listdir(path)):
        print("+ directory 'container' exists")
    else:
        print("+ mkdir {} ".format(path))
        subprocess.call(shlex.split('mkdir -p ' + path + '/container'))
    
def filesYamlExists():
    path = os.environ['HOME'] + '/container'

    # check if the files pod.yaml and deploy.yaml exists in directory container in $HOME
    if verifyYamlExists(os.listdir(subprocess.call(shlex.split('ls -a | grep -i yaml')))):
        print("+ files pod and deploy exists")
    else:
        print("+ cp pod.yaml {} ".format(path))
        subprocess.call(shlex.split('cp pod.yaml '  + path))
        print("+ cp deploy.yaml {} ".format(path))
        subprocess.call(shlex.split('cp deploy.yaml ' + path))

def webDirExists():
    path = os.environ['HOME'] + '/container'

    if verifyWebExists(os.listdir(path)):
        print("+ directory 'web' exists")
    else:
        print("+ copying directory to {}".format(path))
        # create the directory web/ in directory container in $HOME
        subprocess.call(shlex.split('cp -R web/ '+ path))