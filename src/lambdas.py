# checks if there is a file called prometheus
verifyPromExists = lambda file, path: True if (file in path) else False
# checks if there is a file called node_exporter
verifyExpoExists = lambda file, path: True if (file in path) else False 
# check if there is a directory container exists in /home/user/
verifyContainerExists = lambda path: True if ('container' in path) else False
# check if there is a file called pod.yaml exists in directory /home/user/container/
verifyYamlExists = lambda path: True if ('yaml' in path) else False
# check if there is a directory called web/ exists in directory /home/user/container/
verifyWebExists = lambda path: True if ('web/' in path) else False