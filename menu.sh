#!/bin/bash

##Instalacion y Mantenimiento de una Aplicación Web
#Importar funciones de otros ficheros

###########################################################
#                  1) INSTALL NGINX                     #
###########################################################
function instalarNGINX()
{
    aux=$(aptitude show nginx | grep "State: installed")
    aux2=$(aptitude show nginx | grep "Estado: instalado")
    aux3=$aux$aux2
    if [ -z "$aux3" ]
    then 
       echo "instalando ..."
       sudo apt install nginx
    else
         echo "nginx ya estaba instalado"
        fi 
}

### Main ###
opcionmenuppal=0
while test $opcionmenuppal -ne 23
do
    #Muestra el menu
            echo -e "1 Instala nginX \n"
    echo -e "23) fin \n"
            read -p "Elige una opcion:" opcionmenuppal
    case $opcionmenuppal in
            1) instalarNGINX;;
            23) fin;;
            *) ;;

    esac 
done 
