#! /usr/bin/sh

echo "

\tWelcome to my script
\t

-v, --version   Show version
-h, --help      Show help


bug report: meiazero@tutanota.com
"

# loop for read the options and execute the functions
while true; do 
    read -p "Enter the option: " OPTION
    
    case $OPTION in
        -v|--version) 
            echo "version option"
            break
            ;;
        -h|--help) 
            echo "help option"
            break
            ;;
        exit) 
            break
            ;;
        *) 
            echo "Invalid option"
            ;;
    esac
done

