#!/bin/bash

log_step() {
    echo -e "[INFO] $1 ... $2"
}
# Cambiar hostname del servidor
NEW_HOSTNAME="haproxyn1"

hostnamectl set-hostname "$NEW_HOSTNAME" &>/dev/null
if [ $? -eq 0 ]; then
    echo "[INFO] Cambio de hostname a $NEW_HOSTNAME ... OK"
else
    echo "[INFO] Cambio de hostname ... FALLO"
    exit 1
fi
# 1. Instalar HAProxy, Firewalld y Vim
yum install -y haproxy firewalld vim &>/dev/null
if [ $? -eq 0 ]; then
    log_step "Instalación de HAProxy, Firewalld y Vim" "OK"
else
    log_step "Instalación de HAProxy, Firewalld y Vim" "FALLO"
    exit 1
fi

# 2. Habilitar y levantar servicios
systemctl enable --now haproxy &>/dev/null
systemctl enable --now firewalld &>/dev/null
if [ $? -eq 0 ]; then
    log_step "Habilitación de servicios HAProxy y Firewalld" "OK"
else
    log_step "Habilitación de servicios" "FALLO"
    exit 1
fi

# 3. Abrir puertos en Firewalld
firewall-cmd --permanent --add-port=80/tcp &>/dev/null
firewall-cmd --permanent --add-port=443/tcp &>/dev/null
firewall-cmd --permanent --add-port=8404/tcp &>/dev/null
firewall-cmd --permanent --add-port=22/tcp &>/dev/null
firewall-cmd --reload &>/dev/null
if [ $? -eq 0 ]; then
    log_step "Configuración de Firewall (80, 443, 8404)" "OK"
else
    log_step "Configuración de Firewall" "FALLO"
    exit 1
fi

# 4. Deshabilitar SELinux (temporal)
setenforce 0 &>/dev/null
if [ $? -eq 0 ]; then
    log_step "SELinux puesto en modo permissive" "OK"
else
    log_step "Cambio temporal de SELinux" "FALLO"
    exit 1
fi

# 5. Deshabilitar SELinux permanentemente
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config &>/dev/null
if [ $? -eq 0 ]; then
    log_step "SELinux deshabilitado permanentemente en /etc/selinux/config" "OK"
else
    log_step "Cambio permanente de SELinux" "FALLO"
    exit 1
fi
