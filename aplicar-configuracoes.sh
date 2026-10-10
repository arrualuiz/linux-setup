#!/usr/bin/env bash
# Reaplica as configurações do Cinnamon, atalhos, ícones e lançadores.
# Rodar por último (depois dos apps instalados), com:
#   bash ~/dev/linux-setup/aplicar-configuracoes.sh
set -uo pipefail
cd "$(dirname "$0")"
C=configs
A=~/.local/share/applications
D="$(xdg-user-dir DESKTOP)"

echo "==> Efeitos visuais desligados (PC fica mais leve)"
for k in desktop-effects desktop-effects-workspace desktop-effects-on-dialogs desktop-effects-on-menus enable-vfade startup-animation; do
  gsettings set org.cinnamon $k false 2>/dev/null || true
done
gsettings set org.cinnamon.desktop.interface enable-animations false

echo "==> Lançadores do Chrome (Pessoal e PUC) e do Jupyter"
mkdir -p $A ~/.local/share/icons/chrome-perfis
cp $C/icones/*.png ~/.local/share/icons/chrome-perfis/
cp $C/aplicativos/*.desktop $A/
update-desktop-database $A 2>/dev/null || true

echo "==> Ícones na área de trabalho (só no monitor principal)"
gsettings set org.nemo.desktop desktop-layout 'true::false'
for f in chrome-pessoal chrome-puc jupyter-lab; do
  cp $A/$f.desktop "$D/"; chmod +x "$D/$f.desktop"
  gio set "$D/$f.desktop" metadata::trusted true 2>/dev/null || true
done
for f in org.gnome.Terminal com.microsoft.VSCode sublime_text dbeaver-ce firefox; do
  src=$(ls /usr/share/applications/$f.desktop 2>/dev/null) || continue
  cp "$src" "$D/"; chmod +x "$D/$f.desktop"; gio set "$D/$f.desktop" metadata::trusted true 2>/dev/null || true
done
ln -sfn ~/dev/faculdade/pucpr/ads "$D/Faculdade"
# Ícones livres pra arrastar: sem "organizar automaticamente", mas encaixando na grade.
# O nemo-desktop regrava esse arquivo, então edita antes e mata com -9 (o Cinnamon reabre).
m=~/.config/nemo/desktop-metadata
mkdir -p ~/.config/nemo
if grep -q '^\[desktop-monitor-0\]' "$m" 2>/dev/null; then
  sed -i '/^nemo-icon-view-auto-layout=/d; /^\[desktop-monitor-0\]/a nemo-icon-view-auto-layout=false' "$m"
else
  printf '[desktop-monitor-0]\nnemo-icon-view-auto-layout=false\n' >> "$m"
fi
if pkill -9 -x nemo-desktop; then
  sleep 2; pgrep -x nemo-desktop >/dev/null || (setsid nemo-desktop >/dev/null 2>&1 &)
fi

echo "==> Barras de tarefas: uma por monitor, botões separados por janela"
d=~/.config/cinnamon/spices/grouped-window-list@cinnamon.org
mkdir -p $d
cp $C/cinnamon/16.json $C/cinnamon/17.json $d/
while IFS='=' read -r k v; do gsettings set org.cinnamon "$k" "$v"; done < $C/cinnamon/paineis.txt

echo "==> Atalhos de teclado (Print, Shift+Print, Super+V, Super+., Super+Tab, Ctrl+Alt+P)"
dconf load /org/cinnamon/desktop/keybindings/ < $C/cinnamon/atalhos.dconf
# o Super+. era do seletor de emoji do ibus; fica só o Super+;
gsettings set org.freedesktop.ibus.panel.emoji hotkey "['<Super>semicolon']" 2>/dev/null || true

echo "==> CopyQ abrindo junto com o sistema"
mkdir -p ~/.config/autostart
cp $C/autostart/copyq.desktop ~/.config/autostart/

echo "==> Nomes amigáveis das saídas de som (só vale com o mesmo hardware)"
mkdir -p ~/.config/wireplumber/main.lua.d
cp $C/wireplumber/51-nomes-audio.lua ~/.config/wireplumber/main.lua.d/

echo "==> Energia: nunca suspender, nunca apagar a tela, sem bloqueio automático"
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 0
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 0
gsettings set org.cinnamon.desktop.session idle-delay 0
gsettings set org.cinnamon.desktop.screensaver lock-enabled false

echo "==> Perfil de energia: desempenho"
powerprofilesctl set performance 2>/dev/null || true

if lspci | grep -q 'GT 420'; then
  echo "==> GT 420: desligando a aceleração de vídeo no Chrome, no VS Code, no Spotify e nos apps GTK4 (com o nouveau ela trava o PC)"
  if pgrep -x chrome >/dev/null; then
    echo "   ⚠️ Feche os dois Chromes e rode este script de novo para valer neles."
  else
    for d in ~/.config/google-chrome ~/.config/chrome-puc; do
      [ -f "$d/Local State" ] || continue
      python3 - "$d/Local State" <<'EOF'
import json, sys
f = sys.argv[1]
s = json.load(open(f))
s["hardware_acceleration_mode"] = {"enabled": False}
json.dump(s, open(f, "w"))
EOF
    done
  fi
  # Spotify usa o mesmo motor do Chrome; ele regrava o prefs ao fechar, então só com ele fechado
  p=~/.var/app/com.spotify.Client/config/spotify/prefs
  if pgrep -x spotify >/dev/null; then
    echo "   ⚠️ Feche o Spotify e rode este script de novo para valer nele."
  elif flatpak info --user com.spotify.Client >/dev/null 2>&1; then
    mkdir -p "${p%/*}"; touch "$p"
    sed -i '/^ui.hardware_acceleration=/d' "$p"; echo 'ui.hardware_acceleration=false' >> "$p"
  fi
  grep -q GSK_RENDERER ~/.profile || printf '\n# GT 420 + nouveau: apps GTK4 (ex.: Monitor do Sistema) travam a placa de vídeo; desenhar sem GPU\nexport GSK_RENDERER=cairo\n' >> ~/.profile
  [ -f ~/.vscode/argv.json ] && sed -i 's|^\t// "disable-hardware-acceleration": true,|\t"disable-hardware-acceleration": true,|' ~/.vscode/argv.json
fi

echo
echo "Pronto! Faça logout e login (ou reinicie) para tudo aparecer certinho."
