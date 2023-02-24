from src.functions import *
import sys

def main():
    args = sys.argv

    if len(args) != 1:
        # print(args)
        if args[1] == '-d' or args[1] == "--download":
            downloadProm()
            decompressProm()
            downloadExpo()
            decompressExpo()
            createDirs()
            webDirExists()
            try:
                if args[2] == '--microk8s':
                    print("\n microk8s installation\n")
                elif args[2] == '--kubernetes':
                    print("\n kubernetes installation\n")
                else:
                    pass
            except:
                pass

        elif args[1] == '-h' or args[1] == '--help':
            print("Usage:\tpython3 main.py \n\n-d, --download \t\t to download prometheus and node exporter \n--microk8s \t\t\t to install in microk8s \n--kubernetes \t\t\t to install in kubernetes\n")
        else:
            print("\ninvalid flag '{}' Use -h or --help to see the help\n".format(args[1]))
    else:
        print("\nargument invalid, use -h or --help to see the help\n")


main()
