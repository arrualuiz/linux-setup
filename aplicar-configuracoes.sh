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

echo "==> Lançadores do Chrome (Arrua, PUC, UFPR e Contas), do Jupyter, do Paseo e dos projetos"
mkdir -p $A ~/.local/share/icons/chrome-perfis
cp $C/icones/*.png ~/.local/share/icons/chrome-perfis/
cp $C/aplicativos/*.desktop $A/
update-desktop-database $A 2>/dev/null || true
# google-chrome.desktop e com.google.Chrome.desktop (Hidden=true) escondem os atalhos do sistema,
# senão a barra liga as janelas do Chrome a eles e não ao "Chrome Arrua" fixado.
for t in text/html x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about x-scheme-handler/unknown; do
  xdg-mime default chrome-pessoal.desktop $t
done

echo "==> Ícones na área de trabalho (nos dois monitores: os atalhos dos sites eu arrumo no segundo)"
gsettings set org.nemo.desktop desktop-layout 'true::true'
# os projeto-*.desktop ficam só no menu: na área de trabalho, desde 16/11, quem abre o VS Code de cada projeto são os
# atalhos dos sites ("Casamento - trabalhar (VS Code)"), que o pastas-de-projetos monta
for f in chrome-pessoal chrome-puc chrome-ufpr chrome-contas jupyter-lab; do
  cp $A/$f.desktop "$D/"; chmod +x "$D/$f.desktop"
  gio set "$D/$f.desktop" metadata::trusted true 2>/dev/null || true
done
for f in org.gnome.Terminal com.microsoft.VSCode sublime_text dbeaver-ce firefox; do
  src=$(ls /usr/share/applications/$f.desktop 2>/dev/null) || continue
  cp "$src" "$D/"; chmod +x "$D/$f.desktop"; gio set "$D/$f.desktop" metadata::trusted true 2>/dev/null || true
done
# Pastas "Últimos projetos" (mexidos desde 01/09/2026) e "Faculdade", com um atalho VS Code + Claude em cada projeto,
# e os atalhos dos sites soltos na área de trabalho (a lista é o SITES.md do caderno)
bash $C/bin/pastas-de-projetos
# Ícones livres pra arrastar nos dois monitores: sem "organizar automaticamente", mas encaixando na grade.
# O nemo-desktop regrava esse arquivo, então edita antes e mata com -9 (o Cinnamon reabre).
m=~/.config/nemo/desktop-metadata
mkdir -p ~/.config/nemo
touch "$m"
for mon in 0 1; do
  if grep -q "^\[desktop-monitor-$mon\]" "$m"; then
    sed -i "/^\[desktop-monitor-$mon\]/,/^\$/{/^nemo-icon-view-auto-layout=/d}; /^\[desktop-monitor-$mon\]/a nemo-icon-view-auto-layout=false" "$m"
  else
    printf '\n[desktop-monitor-%s]\nnemo-icon-view-auto-layout=false\n' "$mon" >> "$m"
  fi
done
if pkill -9 -x nemo-desktop; then
  sleep 2; pgrep -x nemo-desktop >/dev/null || (setsid nemo-desktop >/dev/null 2>&1 &)
fi

echo "==> Explorador (Nemo): pastas de trabalho nos Marcadores e Recentes com 30 dias"
# "Recentes" da barra lateral guarda 30 dias em vez de 7
gsettings set org.cinnamon.desktop.privacy recent-files-max-age 30
gsettings set org.gnome.desktop.privacy recent-files-max-age 30 2>/dev/null || true
# Marcadores: só acrescenta o que falta, depois das 5 pastas padrão (que ficam em "Meu computador")
b=~/.config/gtk-3.0/bookmarks
mkdir -p ~/.config/gtk-3.0; touch "$b"
while IFS='|' read -r pasta nome; do
  [ -d "$pasta" ] || continue
  uri=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).as_uri())' "$pasta")
  awk -v u="$uri" '$1==u{f=1} END{exit !f}' "$b" || echo "$uri $nome" >> "$b"
done <<EOF
$HOME/dev/projetos|Projetos
$HOME/dev/projetos/rascunhos-e-anotacoes|Rascunhos e anotações
$HOME/dev/site-casamento|Site do casamento
$HOME/dev/stigpr-site|Site do STIGPR
$HOME/dev/faculdade|Faculdade (arquivos)
$D/Faculdade|Faculdade (atalhos)
$D/Financeiro|Financeiro
EOF

echo "==> Pomodoro (applet da loja do Cinnamon), do lado do relógio no monitor 1"
if [ ! -d ~/.local/share/cinnamon/applets/pomodoro@gregfreeman.org ]; then
  t=$(mktemp -d)
  curl -fsSL -o $t/p.zip https://cinnamon-spices.linuxmint.com/files/applets/pomodoro@gregfreeman.org.zip \
    && unzip -q $t/p.zip -d $t && cinnamon-install-spice applet $t/pomodoro@gregfreeman.org
  rm -rf $t
fi

echo "==> Setinha da bandeja (igual ao Windows): esconde CopyQ, Toolbox, Pomodoro etc."
if [ ! -d ~/.local/share/cinnamon/applets/hideable-applets@cardsurf ]; then
  t=$(mktemp -d)
  curl -fsSL -o $t/h.zip https://cinnamon-spices.linuxmint.com/files/applets/hideable-applets@cardsurf.zip \
    && unzip -q $t/h.zip -d $t && cinnamon-install-spice applet $t/hideable-applets@cardsurf
  rm -rf $t
fi
mkdir -p ~/.config/cinnamon/spices/hideable-applets@cardsurf ~/.local/share/cinnamon/applets/hideable-applets@cardsurf/values
cp $C/cinnamon/setinha/hideable-applets@cardsurf.json ~/.config/cinnamon/spices/hideable-applets@cardsurf/
cp $C/cinnamon/setinha/last_values.csv ~/.local/share/cinnamon/applets/hideable-applets@cardsurf/values/

echo "==> Saída de som: um clique (ou Super+Ctrl+V) troca entre o fone e a caixa"
# Applet que eu fiz, fica nas duas barras do lado do volume (paineis.txt)
mkdir -p ~/.local/share/cinnamon/applets
cp -r $C/cinnamon/saida-de-som/saida-de-som@arrualuiz ~/.local/share/cinnamon/applets/

echo "==> Sino de notificações: número em destaque e Não perturbe que guarda (Super+Ctrl+N)"
# Também é meu, fica entre o relógio e o mostrar área de trabalho (paineis.txt)
cp -r $C/cinnamon/notificacoes/notificacoes@arrualuiz ~/.local/share/cinnamon/applets/

echo "==> Barras de tarefas: uma por monitor, botões separados por janela, volume nas duas"
d=~/.config/cinnamon/spices/grouped-window-list@cinnamon.org
mkdir -p $d
cp $C/cinnamon/16.json $C/cinnamon/17.json $d/
while IFS='=' read -r k v; do gsettings set org.cinnamon "$k" "$v"; done < $C/cinnamon/paineis.txt

echo "==> Relógio em duas linhas (hora em cima, data embaixo) nos dois monitores"
d=~/.config/cinnamon/spices/calendar@cinnamon.org
mkdir -p $d
cp $C/cinnamon/relogio/13.json $C/cinnamon/relogio/20.json $d/

echo "==> Atalhos de teclado (Print, Shift+Print, Super+V, Super+., Super+Y, Super+Tab, Ctrl+Alt+P, teclas de mídia)"
# Scripts dos atalhos (ex.: smile-auto-fechar no Win+.)
mkdir -p ~/.local/bin && cp $C/bin/* ~/.local/bin/ && chmod +x ~/.local/bin/*
dconf load /org/cinnamon/desktop/keybindings/ < $C/cinnamon/atalhos.dconf
# o Super+. era do seletor de emoji do ibus; fica só o Super+;
gsettings set org.freedesktop.ibus.panel.emoji hotkey "['<Super>semicolon']" 2>/dev/null || true

echo "==> mpv como player de vídeo padrão"
mkdir -p ~/.var/app/io.mpv.Mpv/config/mpv
cp $C/mpv/mpv.conf ~/.var/app/io.mpv.Mpv/config/mpv/
xdg-mime default io.mpv.Mpv.desktop video/x-matroska video/mp4 video/x-msvideo video/webm video/quicktime \
  video/mpeg video/x-flv video/x-ms-wmv video/mp2t video/x-m4v video/3gpp

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

echo "==> Vigia de temperatura (processador e placa de vídeo)"
mkdir -p ~/.config/systemd/user
cp $C/systemd/vigia-temperatura.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable vigia-temperatura.service
systemctl --user restart vigia-temperatura.service

echo "==> Aviso no celular quando o PC liga ou acorda (falta rodar: avisa-pc-ligou --configurar)"
cp $C/systemd/avisa-pc-ligou.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable avisa-pc-ligou.service
systemctl --user restart avisa-pc-ligou.service

echo
echo "Pronto! Faça logout e login (ou reinicie) para tudo aparecer certinho."
