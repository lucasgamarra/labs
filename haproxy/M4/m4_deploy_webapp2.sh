#!/bin/bash

log_step() {
    echo -e "[INFO] $1 ... $2"
}
# ==============================
# Verificación de Rocky Linux 9
# ==============================

if [ -f /etc/os-release ]; then
    . /etc/os-release

    if [[ "$ID" == "rocky" && "$VERSION_ID" =~ ^9 ]]; then
        echo -e "\e[31m"
        echo "────────────────────────────────────────────────────────────"
        echo "ATENCIÓN:"
        echo
        echo "La versión recomendada para este laboratorio es Rocky Linux 8."
        echo "Usted ha seleccionado Rocky Linux 9."
        echo
        echo "En esta versión se ha identificado un problema conocido que"
        echo "puede provocar la interrupción de la conexión SSH luego de"
        echo "instalar determinados paquetes (por ejemplo, git)."
        echo
        echo "Para mitigar este inconveniente, se procederá a realizar una"
        echo "actualización completa del sistema antes de continuar."
        echo
        echo "Por favor, aguarde mientras se completa el proceso..."
        echo "────────────────────────────────────────────────────────────"
        echo -e "\e[0m"

        dnf update -y
        if [ $? -ne 0 ]; then
            echo "[ERROR] Falló la actualización del sistema en Rocky Linux 9"
            exit 1
        fi
    fi
fi
# Cambiar hostname del servidor
NEW_HOSTNAME="webapp2"

hostnamectl set-hostname "$NEW_HOSTNAME" &>/dev/null
if [ $? -eq 0 ]; then
    echo "[INFO] Cambio de hostname a $NEW_HOSTNAME ... OK"
else
    echo "[INFO] Cambio de hostname ... FALLO"
    exit 1
fi

# 1. Instalar Apache, Firewalld y Vim
yum install -y httpd firewalld vim &>/dev/null
if [ $? -eq 0 ]; then
    log_step "Instalación de Apache, Firewalld y Vim" "OK"
else
    log_step "Instalación de Apache, Firewalld y Vim" "FALLO"
    exit 1
fi

# 2. Habilitar servicios
systemctl enable --now httpd &>/dev/null
systemctl enable --now firewalld &>/dev/null
if [ $? -eq 0 ]; then
    log_step "Habilitación de servicios Apache y Firewalld" "OK"
else
    log_step "Habilitación de servicios Apache y Firewalld" "FALLO"
    exit 1
fi

# 3. Abrir puertos 80 y 443
firewall-cmd --permanent --add-port=80/tcp &>/dev/null
firewall-cmd --permanent --add-port=443/tcp &>/dev/null
firewall-cmd --permanent --add-port=22/tcp &>/dev/null
firewall-cmd --reload &>/dev/null
if [ $? -eq 0 ]; then
    log_step "Apertura de puertos 80 y 443 en Firewalld" "OK"
else
    log_step "Apertura de puertos 80 y 443" "FALLO"
    exit 1
fi

# 4. Crear página web APP2 con color verde
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>APP2</title>
    <style>
        body {
            background: linear-gradient(to right, #00ff87, #00b33c);
            font-family: Arial, sans-serif;
            color: white;
            text-align: center;
            padding-top: 150px;
        }
        .box {
            background: rgba(255,255,255,0.2);
            padding: 40px;
            border-radius: 15px;
            display: inline-block;
            font-size: 32px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="box">🌐 Servidor actual: <strong>APP1 - SERVER 2</strong></div>
</body>
</html>
EOF

if [ $? -eq 0 ]; then
    log_step "Creación de página web APP1" "OK"
else
    log_step "Creación de página web APP1" "FALLO"
    exit 1
fi

# 5. Reiniciar Apache
systemctl restart httpd &>/dev/null
if [ $? -eq 0 ]; then
    log_step "Reinicio del servicio Apache" "OK"
else
    log_step "Reinicio del servicio Apache" "FALLO"
    exit 1
fi

# 6. Probar con curl
curl -s http://localhost | grep -q "APP1"
if [ $? -eq 0 ]; then
    log_step "Prueba de acceso con curl" "OK"
else
    log_step "Prueba de acceso con curl" "FALLO"
    exit 1
fi
