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

    # Reemplazo el index.html actual
    sudo cp index.html /var/www/html/index.html
    # falta hacer toda la pagina  y eso
    firefox http://127.0.0.1/index.html 
}

###########################################################
#                  6) Crear nueva ubicación               #
###########################################################
function crearNuevaUbicacion(){
    # Creo la carpeta de produccion
    if [[ -d /var/www/EHU_analisisdesentimiento/public_html ]]
    then
        echo "Ya existe el directorio"
    else
        sudo mkdir -p /var/www/EHU_analisisdesentimiento/public_html
        echo "Creando ubicacion..."
    fi

    #Concedo los permisos
    echo "Concediendo permisos al directorio..."
    sudo chown -R $USER:$USER /var/www/EHU_analisisdesentimiento/public_html
}

###########################################################
#                  7) Ejecutar entorno virtual            #
###########################################################
function ejecutarEntornoVirtual(){
    # Actualizamos todo
    echo "Actualizando e instalando librerias..."
    sudo apt update
    # La siguiente linea la descomento porque tardara muchisimo y no es imprescindible
    #sudo apt -y upgrade
    # Descargamos el pip de python y otras herramientas de desarrollo python
    sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools python3-venv python3-virtualenv

    # y si no esta?
    if [[ -d /var/www/EHU_analisisdesentimiento/public_html ]]
    then
        echo "Ya existe /var/www/EHU_analisisdesentimiento/public_html"
    else
        echo "Creando la carpeta necesaria..."
        sudo mkdir -p /var/www/EHU_analisisdesentimiento/public_html
        echo "Concediendo permisos a l directorio..."
        sudo chown -R $USER:$USER /var/www/EHU_analisisdesentimiento/public_html
    fi

    if [[ -d /var/www/EHU_analisisdesentimiento/public_html/venv ]]
    then
        echo "El entorno virtual ya está creado"
        echo "Activando entorno virtual ..."
        cd /var/www/EHU_analisisdesentimiento/public_html
        source venv/bin/activate
    else
        # Creamos el entorno de desarrollo
        echo "Creando entorno virtual ..."
        cd /var/www/EHU_analisisdesentimiento/public_html
        virtualenv -p python3 venv
        #Activamos el entorno de desarrollo
        echo "Activando entorno virtual ..."
        source venv/bin/activate
    fi
}

##################################################################################
#               8) Instala librerias del entorno virtual                     #
##################################################################################

function instalarLibreriasEntornoVirtual()
{
    #Comprobar si pip ya esta en su ultima version
    # si no, instalar
    aux=$(python3 -m pip install --upgrade pip | grep "Requirement already up-to-date")
    if [ -z "$aux" ]
    then
        echo "instalando pip en su ultima version..."
    else
        echo "pip ya estaba instalado en su ultima version..."
    fi
         
    #Comprobar si las librerias ya estan instaladas
    # si no, instalar
    aux=$(pip show transformers 2>&1 | grep "Package(s) not found")
    if [ -z "$aux" ]
    then
        echo "La librería Transformers ya estaba instalada "
    else
        echo "instalando las librerias necesarias..."
        pip install transformers[torch]
    fi

    aux=$(pip show torch 2>&1 | grep "Package(s) not found")
    if [ -z "$aux" ]
    then
        echo "La librería PyTorch ya estaba instalada "
    else
        echo "instalando las librerias necesarias..."
        pip install transformers[torch]
    fi
}


##################################################################################
#               9) Copia ficheros del proyecto a la nueva ubicación                     #
##################################################################################

function copiarFicherosProyectoNuevaUbicacion()
{
    #Simplemente copia los ficheros a la ubicación nueva
    echo "copiando la carpeta static a la nueva ubicacion..."
    cp -R /var/www/analisisdesentimiento/public_html/static /var/www/EHU_analisisdesentimiento/public_html/
    echo "copiando la carpeta templates a la nueva ubicacion..."
    cp -R /var/www/analisisdesentimiento/public_html/templates/ /var/www/EHU_analisisdesentimiento/public_html/
    echo "copiando el archivo webserviceanalizadordesentimiento.py a la nueva ubicacion..."
    cp /var/www/analisisdesentimiento/public_html/webserviceanalizadordesentimiento.py /var/www/EHU_analisisdesentimiento/public_html/

}


###########################################################
#               10) Instala Flask                     #
###########################################################

function instalarFlask()
{
    #Movernos al directorio adecuado
    cd /var/www/EHU_analisisdesentimiento/public_html
     
    #Activar el entorno virtual
    echo "activando en entorno virtual..."
    source venv/bin/activate
     
    #Comprobar si flask ya está instalado
    #Si no, instalarlo
    aux=$(pip show flask 2>&1 | grep "Package(s) not found: flask")
    if [ -z "$aux" ]
    then
        echo "flask ya estaba instalado"
    else
        echo "instalando flask..."
        pip install flask
    fi
}


###########################################################
#               11) Prueba Flask                     #
###########################################################

function probarFlask()
{
    #Abre el navegador para que el usuario compruebe manualmente que funciona
    echo "abriendo el navegador..."
    echo "pulsar CTRL+C para detener el servidor de desarrollo Flask"
    firefox http://127.0.0.1:5000/
    python3 /var/www/EHU_analisisdesentimiento/public_html/webserviceanalizadordesentimiento.py
}


###########################################################
#               12) Instala gUnicorn                     #
###########################################################

function instalarGunicorn()
{
    #Movernos al directorio adecuado
    cd /var/www/EHU_analisisdesentimiento/public_html
    
    #Activar el entorno virtual
    source venv/bin/activate
    
    #Comprobar si gunicorn ya está instalado
    #Si no, instalarlo
    aux=$(pip show gunicorn 2>&1 | grep "Package(s) not found: gunicorn")
    if [ -z "$aux" ]
    then
        echo "gunicorn ya estaba instalado"
    else
        echo "instalando gunicorn..."
        pip install gunicorn
    fi
}


###########################################################
#               13) Configura gunicorn                    #
###########################################################
function configurarGunicorn()
{
    # Mira a ver si el archivo wsgi.py existe
    aux=$(ls /var/www/EHU_analisisdesentimiento/public_html | grep "wsgi.py")
    if [ -z "$aux" ] # si no existe, grep devolverá un string vacío
    then 
       echo "creando wsgi.py ..."
       # crea el archivo wsgi.py con este contenido
       sudo echo -e "from webserviceanalizadordesentimiento import app 
if __name__ == \"__main__\":
   app.run()
" > /var/www/EHU_analisisdesentimiento/public_html/wsgi.py
        echo "Se ha creado wsgi.py en /var/www/EHU_analisisdesentimiento/public_html/wsgi.py"
    else
        echo "wsgi.py ya existe"
        echo "Si crees que wsgi.py tiene algún problema"
        echo "Bórralo en /var/www/EHU_analisisdesentimiento/public_html/wsgi.py"
        echo "Con: sudo rm /var/www/EHU_analisisdesentimiento/public_html/wsgi.py"
        echo "Y vuelve a ejecutar la opción 13)"
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
    aux=$(ls -lias /var/www | grep "www-data www-data")
    if [ -z "$aux" ] # Si no lo es, grep devolverá un string vacío
    then 
        echo "Estableciendo propiedad ..."
        sudo chown -R www-data:www-data /var/www
        echo "Se ha establecido la propiedad"
    else
        echo "La propiedad ya estaba esablecida"
    fi
    
    # Mira si los permisos son exáctamente 775
    aux=$(ls -lias /var/www | grep "rwxrwxr-x")
    if [ -z "$aux" ] # Si no lo son, grep devolverá un string vacío
    then 
        echo "Estableciendo permisos ..."
        sudo chmod -R 775 /var/www
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
" | sudo tee -a /etc/systemd/system/flask.service
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
" | sudo tee -a /etc/nginx/conf.d/flask.conf
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

###########################################################
#         18) Rearranca Nginx             #
###########################################################
function rearrancarNginx()
{
    echo "Arrancando el demonio NGINX..."
    sudo systemctl restart nginx
    echo "NGINX arrancado"
 }


###########################################################
#         19) Testea Virtual Hosts             #
###########################################################
function testearVirtualHost()
 {
    #Abre el navegador para que el usuario compruebe manualmente si funciona
    echo "Comprobar el correcto funcionamiento"
    firefox http://localhost:8888/
}


###########################################################
#         20) Ver nGinx Logs             #
###########################################################
function verNginxLogs()
 {
    #Si ha habido algún error, el usuario deberá comprobar los siguientes ficheros:"
    echo "Verifica los registros de error de Nginx:"
    sudo tail -n 100 /var/log/nginx/error.log
}


###########################################################
#         21) Controla intentos conexión SSH             #
###########################################################
function controlarIntentosConexionSSH()
{
    #Muestra por pantalla los intentos de conexión
    echo "Imprimiendo los intentos de conexion..."
    ficheros=$(ls /var/log/ | grep -e "^auth.log")
    for fichero in $ficheros
    do
        esgz=$(echo /var/log/$fichero | grep ".gz")
        if [ -z $esgz ]
        then
            notifssh=$(less /var/log/$fichero | grep "sshd" | tr -s ' ' '@')
        else
            notifssh=$(zcat /var/log/$fichero | grep "sshd" | tr -s ' ' '@')
        fi

        for notif in $notifssh
        do
            status=$(echo $notif | cut -d@ -f6)
            if [ $status = "Failed" ]
            then
                status="fail"
            else
                if [ $status = "Accepted" ]
                then
                    status="accept"
                fi
            fi

            if [ $status = "fail" -o $status = "accept" ]
            then
                nombre=$(echo $notif | cut -d@ -f9)
                mes=$(echo $notif | cut -d@ -f1)
                dia=$(echo $notif | cut -d@ -f2)
                hora=$(echo $notif | cut -d@ -f3)
                echo "Status: [$status] Account name: $nombre Date: $mes, $dia, $hora"
            fi
        done
    done
    echo "Esos eran todos los intentos de conexion"
}


###########################################################
#         22) Sale del menú             #
###########################################################
function salirMenu()
{
    echo "Adios :) \n"
    echo "Joel García, Diego Esteban, Maria Bogajo y Paula Pinto"
    exit 0
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
    echo -e "8) Instala librerias del entorno virtual \n"
    echo -e "9) Copia ficheros del proyecto a la nueva ubicación \n"
    echo -e "10) Instala Flask \n"
    echo -e "11) Prueba Flask \n"
    echo -e "12) Instala gUnicorn \n"
    echo -e "13) Configura gunicorn \n"
    echo -e "14) Establece permisos \n"
    echo -e "15) Crea servicio flask \n"
    echo -e "16) Configura proxy inverso \n"
    echo -e "17) Carga ficheros de configuración \n"
    echo -e "18) Rearranca Nginx \n"
    echo -e "19) Testea Virtual Hosts \n"
    echo -e "20) Ver nGinx Logs \n"
    echo -e "21) Controla intentos conexión SSH \n"
    echo -e "22) Sale del menú \n"
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
            8) instalarLibreriasEntornoVirtual;;
            9) copiarFicherosProyectoNuevaUbicacion;;
            10) instalarFlask;;
            11) probarFlask;;
            12) instalarGunicorn;;
            13) configurarGunicorn;;
            14) pasarPropiedadyPermisos;;
            15) crearServicioSystemdFlask;;
            16) configurarNginxProxyInverso;;
            17) cargarFicherosConfiguracionNginx;;
            18) rearrancarNginx;;
            19) testearVirtualHost;;
            20) verNginxLogs;;
            21) controlarIntentosConexionSSH;;
            22) salirMenu;;
            23) fin;;
            *) ;;
    esac 
done 

echo "Fin del Programa" 
exit 0
