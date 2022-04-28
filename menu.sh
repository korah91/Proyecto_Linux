#!/bin/bash

##Instalacion y Mantenimiento de una Aplicación Web
#Importar funciones de otros ficheros

###########################################################
#                  1) INSTALL NGINX                     #
###########################################################
function instalarNGINX()
{
    aux=$(sudo dpkg -s nginx | grep "Status: install ok installed")
    if [ -z "$aux" ]
    then 
       echo "instalando ..."
       sudo apt install nginx
    else
        echo -e "nginx ya estaba instalado\n"
    fi
}
###########################################################
#                  2) ARRANCAR NGINX                     #
###########################################################
function arrancarNGINX()
{
    # Mira a ver si está arrancado
    aux=$(sudo systemctl status nginx | grep "Active: active (running)")
    if [ -z "$aux" ] # si no está arrancado, grep devolverá un string vacío
    then 
       echo -e "arrancando ...\n"
       sudo sudo systemctl start nginx
       echo -e "se ha arrancado NGINX"
    else
        echo -e "nginx ya estaba arrancado\n"
    fi
}

###########################################################
#                  3) TESTEAR PUERTOS NGINX               #
###########################################################
function TestearPuertosNGINX(){
    # Primero compruebo si netstat esta instalado
    aux=$( dpkg -l | grep net-tools)

    if [ -z "$aux" ]
    then
        echo -e "Se ha instalado netstat\n"
        sudo apt install -y net-tools
    fi
    # tanp Para ver solo conexiones TCP que están Escuchando
    # Con awk leo la columna de la direccion y con cut el puerto
    # Leo solo el primer resultado con head -1
    aux=$(sudo netstat -tanp | grep nginx | awk '{print $ 4}' | cut -d':' -f 2 | head -1)

    if [ -z "$aux" ] 
    then
        echo "Todavia no se ha arrancado NGINX"
    else
        echo -e "NGINX usa el puerto ${aux}\n"
    fi
}

###########################################################
#                  4) Visualizar Index                    #
###########################################################
function visualizarIndex(){
    echo -e "Abriendo firefox en localhost:80 ...\n"
    firefox http://localhost:80
}

###########################################################
#                  5) Personalizar Index                  #
###########################################################
function personalizarIndex(){
    sudo mkdir /var/www/EHU_analisisdesentimiento/public_html
    #Copio el index que ya funciona a la carpeta de producción
# esto esta mal lo tengo que mirar    sudo cp index.html

    #Concedo los permisos
    sudo chown -R $USER:$GROUP /var/www/EHU_analisisdesentimiento/public_html


}
###########################################################
#                  6) Crear nueva ubicación               #
###########################################################
function crearNuevaUbicacion(){

}
###########################################################
#                  7) Ejecutar entorno virtual            #
###########################################################
function ejecutarEntornoVirtual(){
    # Actualizamos todo
    sudo apt -y upgrade
    # Descargamos el pip de python y otras herramientas de desarrollo python
    sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools python3-venv
    # Creamos el entorno de desarrollo
    cd /var/www/EHU_analisisdesentimiento/public_html
    virtualenv -p python3 venv
    #Activamos el entorno de desarrollo
    source venv/bin/activate
}

###########################################################
#               13) Configura gunicorn                    #
###########################################################
function configurarGunicorn()
{
    # Mira a ver si el archivo wsgi.py existe
    aux=$(ls /var/www/EHU_analisisdesentimiento | grep "wsgi.py")
    if [ -z "$aux" ] # si no existe, grep devolverá un string vacío
    then 
       echo "creando wsgi.py ..."
       # crea el archivo wsgi.py con este contenido
       sudo echo -e "from webserviceanalizadordesentimiento import app 
if __name__ == \"__main__\":
   app.run()
" > /var/www/EHU_analisisdesentimiento/wsgi.py
        echo "Se ha creado wsgi.py en /var/www/EHU_analisisdesentimiento/wsgi.py"
    else
        echo "wsgi.py ya existe"
        echo "Si crees que wsgi.py tiene algún problema"
        echo "Bórralo en /var/www/EHU_analisisdesentimiento/wsgi.py"
        echo "Con: sudo rm /var/www/EHU_analisisdesentimiento/wsgi.py"
        echo "Y vuelve a ejecutar la opción 15)"
        echo
    fi
    
    echo "Configurando gunicorn ..."
    # Mira a ver si ya está configurado gunicorn. Si lo está reconfigurarlo dará un error
    # si no estaba configurado, se configura
    aux=$(gunicorn --bind 0.0.0.0:5000 wsgi:app 2>&1 | grep "\[ERROR\] Connection in use")
    if [ -n "$aux" ] # Si da ese error, grep devolverá un string no vacío
    then 
        echo "Gunicorn ya estaba configurado"
    else
        echo "Se ha configurado gunicorn"
    fi

    echo "Se va a abir el navegador para que compruebes que funciona"
    # Abre el navegador para que el usuario compruebe manualmente si funciona
    firefox http://127.0.0.1:5000
    echo "Se ha abierto el navegador"
}

###########################################################
#               14) Establece permisos                    #
###########################################################
function pasarPropiedadyPermisos()
{
    # Mira si el usuario y grupo es www-data
    aux=$(ls -lias /var/www/EHU_analisisdesentimiento/public_html | grep "www-data www-data")
    if [ -z "$aux" ] # Si no lo es, grep devolverá un string vacío
    then 
        echo "Estableciendo propiedad ..."
        sudo chown -R www-data:www-data /var/www/EHU_analisisdesentimiento/public_html
        echo "Se ha establecido la propiedad"
    else
        echo "La propiedad ya estaba esablecida"
    fi
    
    # Mira si los permisos son exáctamente 775
    aux=$(ls -lias /var/www/EHU_analisisdesentimiento/public_html | grep "rwxrwxr-x")
    if [ -z "$aux" ] # Si no lo son, grep devolverá un string vacío
    then 
        echo "Estableciendo permisos ..."
        chmod -R 775 /var/www/EHU_analisisdesentimiento/public_html
        echo "Se han establecido los permisos"
    else
        echo "Los permisos ya estaban establecidos"
    fi
}

###########################################################
#               15) Crea servicio flask                   #
###########################################################
function crearServicioSystemdFlask()
{
    echo "Comprobando si existe flask.service ..."
    # Mira si el archivo flask.service existe
    aux=$(ls /etc/systemd/system | grep "flask.service")
    if [ -z "$aux" ] # si no existe, grep devolverá un string vacío
    then 
        echo "Creando flask.service ..."
        # crea el archivo flask.service con este contenido
        echo -e "[Unit]
Description=Gunicorn instance to serve Flask
After=network.target
[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/EHU_analisisdesentimiento/public_html
Environment=\"PATH=/var/www/EHU_analisisdesentimiento/public_html/venv/bin\"
ExecStart=/var/www/EHU_analisisdesentimiento/public_html/venv/bin/gunicorn --bind 0.0.0.0:5000 wsgi:app
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/flask.service
        echo "Se ha creado flask.service en /etc/systemd/system/flask.service"
        echo ""
        echo "Creado flask.service en /etc/systemd/system/flask.service"
        echo "Recargando los archivos de configuración ..."
        sudo systemctl daemon-reload
        echo "Recargados los archivos de configuración"
    else
        echo "flask.service ya existe"
        echo "Si crees que flask.service tiene algún problema"
        echo "Bórralo en /etc/systemd/system/flask.service"
        echo "Con: sudo rm /etc/systemd/system/flask.service"
        echo "Y vuelve a ejecutar la opción 15)"
    fi

    echo "Comprobando si flask estaba arrancado ..."
    # Mira a ver si está arrancado
    aux=$(sudo systemctl status flask | grep "Active: active (running)")
    if [ -z "$aux" ]  # si no está arrancado, grep devolverá un string vacío
    then 
        echo "Arrancando flask ... "
        sudo systemctl start flask
    else
        echo "Flask ya estaba arrancado"
    fi

    echo ""
    echo "Configurando flask para que se inicie cuando lo haga el ordenador"
    # Hace que flask se inicie al iniciar el ordenador
    sudo systemctl enable flask
    # Mira a ver si está arrancado
    aux=$(sudo systemctl status flask | grep "Active: active (running)")
    if [ -z "$aux" ] # si no está arrancado, grep devolverá un string vacío
    then 
        # Si no está arrancado después de haberlo arrancado con systemctl, significa que
        # el usuario debería arreglar el problema
        echo "No se ha podido arrancar flask"
        echo "Escribe: sudo systemctl status flask"
        echo "Para más detalles"
    else
        echo "Activado flask correctamente"
    fi
}

###########################################################
#              16) Configura proxy inverso                #
###########################################################
function configurarNginxProxyInverso()
{
    echo "Comprobando si existe flask.conf ..."
    # Mira si el archivo flask.conf existe
    aux=$(ls /etc/nginx/conf.d | grep "flask.conf")
    if [ -z "$aux" ] # si no existe, grep devolverá un string vacío
    then 
       echo "creando flask.conf ..."
       # crea el archivo flask.service con este contenido
       echo -e "server {
    listen 8888;
    server_name localhost;
    location / {
        include proxy_params;
        proxy_pass  http://127.0.0.1:5000;
    }
}
" > /etc/nginx/conf.d/flask.conf
        echo "Se ha creado flask.conf en /etc/nginx/conf.d/flask.conf"
    else
        echo "flask.conf ya existe"
        echo "Si crees que flask.conf tiene algún problema"
        echo "Bórralo en /etc/nginx/conf.d/flask.conf"
        echo "Con: sudo rm /etc/nginx/conf.d/flask.conf"
        echo "Y vuelve a ejecutar la opción 16)"
    fi

    echo ""
    echo "Comprobando que la configuración del proxy inverso es correcta ..."
    # Mira a ver si se ha configurado correctamente
    aux=$(sudo nginx -t 2>&1 | grep "nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful")
    if [ -z "$aux" ] # Si no se ha configurado correctamente, grep devolverá un string vacío
    then
        # Si no está configurado correctamente, significa que
        # el usuario debería arreglar el problema
        echo "Hay algún error en los archivos de nginx"
        echo "Escribe: sudo nginx -t"
        echo "Para más detalles"
    else
        echo "La configuración es correcta"
    fi
}

###########################################################
#         17) Carga ficheros de configuración             #
###########################################################
function cargarFicherosConfiguracionNginx()
{
    echo "Recargando el daemon nginx"
    # simplemente recarga el daemon
    sudo systemctl reload nginx
    echo "Se ha recargado el daemon nginx"
}

### Main ###
opcionmenuppal=0
while test $opcionmenuppal -ne 23
do
    #Muestra el menu
    echo -e "###################################################"
    echo -e "1) Instala nginX \n"
    echo -e "2) Arranca nginX \n"
    echo -e "3) Testear puertos nginX \n"
    echo -e "4) Visualizar el Index\n"
    echo -e "5) Personalizar el Index\n"
    echo -e "6) Crear nueva ubicacion\n"
    echo -e "7) Ejecutar entorno virtual\n"
    echo -e "13) Configura gunicorn \n"
    echo -e "14) Establece permisos \n"
    echo -e "15) Crea servicio flask \n"
    echo -e "16) Configura proxy inverso \n"
    echo -e "17) Carga ficheros de configuración \n"
    echo -e "23) fin \n"
    read -p "Elige una opcion:" opcionmenuppal
    echo -e "###################################################\n"
    case $opcionmenuppal in
            1) instalarNGINX;;
            2) arrancarNGINX;;
            3) TestearPuertosNGINX;;
            4) visualizarIndex;;
            5) personalizarIndex;;
            6) crearNuevaUbicacion;;
            7) ejecutarEntornoVirtual;;
            13) configurarGunicorn;;
            14) pasarPropiedadyPermisos;;
            15) crearServicioSystemdFlask;;
            16) configurarNginxProxyInverso;;
            17) cargarFicherosConfiguracionNginx;;
            23) fin;;
            *) ;;

    esac 
done 

echo "Fin del Programa" 
exit 0

