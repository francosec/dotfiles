#!/bin/sh
# Instala a permissão da luz da tela do notebook. Rodar com sudo.
set -e
cd "$(dirname "$0")"
install -m 644 90-backlight.rules /etc/udev/rules.d/90-backlight.rules
udevadm control --reload
chmod a+w /sys/class/backlight/*/brightness     # vale já, sem reiniciar
echo "instalado"
