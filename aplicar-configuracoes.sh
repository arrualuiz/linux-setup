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

echo
echo "Pronto! Faça logout e login (ou reinicie) para tudo aparecer certinho."
