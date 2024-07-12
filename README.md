Bash script designed to automate the installation, configuration, and maintenance of a web application using NGINX, Python's Flask framework, and various other tools using a script template given by the professor. 

The script was developed by a team of four students as part of a university project during our third year of engineering studies.

## Introduction

This script automates the setup and maintenance of a web application environment. It handles the installation and configuration of NGINX, Flask, and Gunicorn, sets up a virtual environment, manages file permissions, and monitors server logs and SSH connection attempts.

## Script Functions

1. **Install NGINX:** Installs NGINX if not already installed.
2. **Start NGINX:** Starts NGINX if not already running.
3. **Test NGINX Ports:** Checks the ports used by NGINX.
4. **View Index:** Opens the default NGINX index page.
5. **Customize Index:** Replaces the default index.html with a custom one.
6. **Create New Location:** Sets up a new directory for the web application.
7. **Setup Virtual Environment:** Sets up a Python virtual environment.
8. **Install Virtual Environment Libraries:** Installs necessary Python libraries.
9. **Copy Project Files to New Location:** Copies project files to the new location.
10. **Install Flask:** Installs Flask in the virtual environment.
11. **Test Flask:** Opens the Flask application.
12. **Install Gunicorn:** Installs Gunicorn in the virtual environment.
13. **Configure Gunicorn:** Configures Gunicorn for the Flask app.
14. **Set Permissions:** Sets the appropriate file permissions.
15. **Create Flask Service:** Sets up a systemd service for Flask.
16. **Configure Reverse Proxy:** Configures NGINX as a reverse proxy.
17. **Reload NGINX Configuration:** Reloads NGINX configuration.
18. **Restart NGINX:** Restarts the NGINX service.
19. **Test Virtual Hosts:** Tests the NGINX virtual hosts.
20. **View NGINX Logs:** Views the NGINX logs.
21. **Monitor SSH Connection Attempts:** Monitors SSH connection attempts.
22. **Exit Menu:** Exits the script menu.

## HTML File
The `index.html` file contains basic HTML structure for displaying group members.

## Usage

1. Clone the repository.
2. Run the script: ./script.sh
3. Follow the menu options to install, configure, and maintain the web application environment.
