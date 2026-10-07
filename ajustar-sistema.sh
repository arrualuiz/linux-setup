#!/usr/bin/env bash
# Ajustes do sistema para este PC (Xeon E5-2620 v3 + Huananzhi X99 + GT 420).
# Precisa de senha. Rodar num terminal normal, com o Chrome fechado:
#   sudo bash ~/dev/linux-setup/ajustar-sistema.sh
# Depois REINICIAR o PC: o nome novo e os parâmetros de boot só valem depois disso.
# Pode rodar de novo sem problema (não duplica nada).
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Rode com sudo: sudo bash $0"; exit 1
fi
NOME_PC=arruadev

echo "==> Parâmetros de boot (GRUB)"
# iommu=pt                            a placa de som PCI (C-Media) gerava milhares de erros "DMAR"
#                                     com a proteção de memória (IOMMU) no modo padrão
# cpufreq.default_governor=performance processador sempre pronto na frequência máxima
# mitigations=off                     desliga as proteções contra Spectre/Meltdown: +5–15% num Xeon v3,
#                                     em troca de segurança. Para voltar, tirar daqui e de /etc/default/grub
for p in iommu=pt cpufreq.default_governor=performance mitigations=off; do
  if ! grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub | grep -qF -- "$p"; then
    sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"/\1 $p\"/" /etc/default/grub
  fi
done
grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
update-grub

echo "==> Nome do PC: $NOME_PC (era 'notebook', o SSD veio de um notebook)"
hostnamectl set-hostname "$NOME_PC"
sed -i "s/^127\.0\.1\.1\s.*/127.0.1.1\t$NOME_PC/" /etc/hosts

echo "==> Menos uso de swap (16 GB de RAM dão conta)"
echo 'vm.swappiness=10' > /etc/sysctl.d/99-desempenho.conf
sysctl -q -p /etc/sysctl.d/99-desempenho.conf

echo "==> Removendo sobras de notebook"
# verificador do pendrive de instalação, applet de placa híbrida NVIDIA, leitor de digital,
# sensor de rotação de tela, controle térmico de notebook, driver de vídeo Intel, modem 3G
SOBRAS=""
for p in casper nvidia-prime-applet switcheroo-control fprintd libpam-fprintd fingwit libpam-fingwit \
         iio-sensor-proxy thermald xserver-xorg-video-intel modemmanager; do
  dpkg -s "$p" >/dev/null 2>&1 && SOBRAS="$SOBRAS $p"
done
if [ -n "$SOBRAS" ]; then
  # shellcheck disable=SC2086
  apt-get remove --purge -y $SOBRAS
else
  echo "   nada para remover"
fi
systemctl reset-failed

echo
echo "Pronto! Agora reinicie o PC."
