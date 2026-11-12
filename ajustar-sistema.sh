#!/usr/bin/env bash
# Ajustes do sistema para este PC (Xeon E5-2620 v3 + Huananzhi X99 + RTX 2060).
# Precisa de senha. Rodar num terminal normal, com o Chrome fechado:
#   sudo bash ~/dev/linux-setup/ajustar-sistema.sh
# Na primeira vez, depois REINICIAR o PC: o nome novo e os parâmetros de boot só valem depois disso.
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

echo "==> Swap comprimida na própria RAM (zram)"
# O Chrome com muitas abas enchia os 16 GB e o resto ia pro /swapfile no SSD (Kingston A400,
# lento): 4,3 GB gravados no swap nos primeiros 25 min ligado (12/11/2026). O zram guarda
# essas páginas comprimidas com zstd (uns 3 pra 1) na RAM: 8 GB de swap que ocupam uns 2–3 GB.
# O /swapfile fica de reserva, com prioridade menor: só é usado se o zram encher.
apt-get install -y systemd-zram-generator
cat > /etc/systemd/zram-generator.conf <<'FIM'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
FIM
systemctl daemon-reload
systemctl start dev-zram0.swap
# Com o swap rápido, compensa usar mais ele e menos o cache de disco (valores do ArchWiki
# para zram). page-cluster=0: lê uma página por vez, no zram não vale ler adiantado.
cat > /etc/sysctl.d/99-desempenho.conf <<'FIM'
vm.swappiness=180
vm.watermark_boost_factor=0
vm.watermark_scale_factor=125
vm.page-cluster=0
FIM
sysctl -q -p /etc/sysctl.d/99-desempenho.conf
swapon --show

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
echo "Pronto! O zram já está valendo. Reiniciar só é preciso na primeira vez (nome do PC e boot)."
