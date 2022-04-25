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
        echo "nginx ya estaba instalado"
    fi
}

function arrancarNGINX()
{
    # Mira a ver si está arrancado
    aux=$(sudo systemctl status nginx | grep "Active: active (running)")
    if [ -z "$aux" ] # si no está arrancado, grep devolverá un string vacío
    then 
       echo "arrancando ..."
       sudo sudo systemctl start nginx
    else
        echo "nginx ya estaba arrancado"
    fi
}

function configurarGunicorn()
{
    # Mira a ver si el archivo wsgi.py existe
    aux=$(ls /var/www/EHU_analisisdesentimiento | grep "wsgi.py")
    if [ -z "$aux" ] # si no existe, grep devolverá un string vacío
    then 
       echo "creando wsgi.py ..."
       # crea el archivo wsgi.py con este contenido
       echo -e "from webserviceanalizadordesentimiento import app 
if __name__ == \"__main__\":
   app.run()
" > /var/www/EHU_analisisdesentimiento/wsgi.py

    else
        echo "wsgi.py ya existe"
    fi
    
    echo "configurando gunicorn ..."
    # Mira a ver si ya está configurado gunicorn. Si lo está reconfigurarlo dará un error
    # si no estaba configurado, se configura
    aux=$(gunicorn --bind 0.0.0.0:5000 wsgi:app | grep "[ERROR] Connection in use")
    if [ -n "$aux" ] # Si da ese error, grep devolverá un string no vacío
    then 
        echo "gunicorn ya estaba configurado"
    fi

    # Abre el navegador para que el usuario compruebe manualmente si funciona
    firefox http://127.0.0.1:5000
}

function pasarPropiedadyPermisos()
{
    # Mira si el usuario y grupo es www-data
    aux=$(ls -lias /var/www/EHU_analisisdesentimiento/public_html | grep "www-data www-data")
    if [ -z "$aux" ] # Si no lo es, grep devolverá un string vacío
    then 
        echo "estableciendo propiedad ..."
        sudo chown -R www-data:www-data /var/www/EHU_analisisdesentimiento/public_html
    else
        echo "la propiedad ya estaba esablecida"
    fi
    
    # Mira si los permisos son exáctamente 775
    aux=$(ls -lias /var/www/EHU_analisisdesentimiento/public_html | grep "rwxrwxr-x")
    if [ -z "$aux" ] # Si no lo son, grep devolverá un string vacío
    then 
        echo "estableciendo permisos ..."
        chmod -R 775 /var/www/EHU_analisisdesentimiento/public_html
    else
        echo "los permisos ya estaban establecidos"
    fi
}

function crearServicioSystemdFlask()
{
    # Mira si el archivo flask.service existe
    aux=$(ls /etc/systemd/system | grep "flask.service")
    if [ -z "$aux" ] # si no existe, grep devolverá un string vacío
    then 
        echo "creando flask.service ..."
        # crea el archivo flask.service con este contenido
        echo -e "[Unit]
Description=Gunicorn instance to serve Flask
After=network.target
[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/EHU_analisisdesentimiento/public_html
Environment="PATH=/var/www/EHU_analisisdesentimiento/public_html/venv/bin"
ExecStart=/var/www/EHU_analisisdesentimiento/public_html/venv/bin/gunicorn --bind 0.0.0.0:5000 wsgi:app
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/flask.service
        sudo systemctl daemon-reload
    else
        echo "flask.service ya existía"
    fi

    # Mira a ver si está arrancado
    aux=$(sudo systemctl status flask | grep "Active: active (running)")
    if [ -z "$aux" ]  # si no está arrancado, grep devolverá un string vacío
    then 
        echo "arrancando flask"
        sudo systemctl start flask
    else
        echo "flask ya estaba arrancado"
    fi

    # Hace que flask se inicie al iniciar el ordenador
    sudo systemctl enable flask
    # Mira a ver si está arrancado
    aux=$(sudo systemctl status flask | grep "Active: active (running)")
    if [ -z "$aux" ] # si no está arrancado, grep devolverá un string vacío
    then 
        # Si no está arrancado después de haberlo arrancado con systemctl, significa que
        # el usuario debería arreglar el problema
        echo "no se ha podido arrancar flask"
        echo "escribe: sudo systemctl status flask"
        echo "para más detalles"
    else
        echo "arrancado flask correctamente"
    fi
}

function configurarNginxProxyInverso()
{
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
    else
        echo "flask.conf ya existe"
    fi

    # Mira a ver si se ha configurado correctamente
    aux=$(sudo nginx -t |grep "nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful")

    if [ -z "$aux" ] # Si no se ha configurado correctamente, grep devolverá un string vacío
        # Si no está configurado correctamente, significa que
        # el usuario debería arreglar el problema
        echo "hay algún error en los archivos de nginx"
        echo "escribe: sudo nginx -t"
        echo "para más detalles"
    fi
}

function cargarFicherosConfiguracionNginx()
{
    # simplemente recarga el daemon
    sudo systemctl reload nginx
}

### Main ###
opcionmenuppal=0
while test $opcionmenuppal -ne 23
do
    #Muestra el menu
    echo -e "1) Instala nginX \n"
    echo -e "2) Arranca nginX \n"
    echo -e "13) Configura gunicorn \n"
    echo -e "14) Establece permisos \n"
    echo -e "15) Crea servicio flask \n"
    echo -e "16) Configura proxy inverso \n"
    echo -e "17) Carga ficheros de configuración \n"
    echo -e "23) fin \n"
    read -p "Elige una opcion:" opcionmenuppal
    case $opcionmenuppal in
            1) instalarNGINX;;
            2) arrancarNGINX;;
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

