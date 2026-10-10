#!/usr/bin/env bash
# Instala o que NÃO precisa de senha (fica tudo na pasta do usuário).
# Rodar DEPOIS do instalar-dev.sh, com: bash ~/dev/linux-setup/instalar-usuario.sh
set -euo pipefail

echo "==> Flathub (loja de apps Flatpak) para o usuário"
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "==> Apps Flatpak"
# Postman | Flameshot (print) | NormCap (OCR) | CopyQ (Win+V) | Smile (Win+.) | Spotify
flatpak install --user -y --noninteractive flathub \
  com.getpostman.Postman \
  org.flameshot.Flameshot \
  com.github.dynobo.normcap \
  com.github.hluk.copyq \
  it.mijorus.smile \
  com.spotify.Client

echo "==> NormCap: OCR em português + inglês"
T=~/.var/app/com.github.dynobo.normcap/config/normcap/tessdata
mkdir -p "$T"
cp ~/.local/share/flatpak/app/com.github.dynobo.normcap/current/active/files/share/tessdata/eng.traineddata "$T/"
curl -fsSL -o "$T/por.traineddata" https://github.com/tesseract-ocr/tessdata_fast/raw/main/por.traineddata

echo "==> Node.js (via nvm, versão LTS)"
v=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | python3 -c 'import json,sys;print(json.load(sys.stdin)["tag_name"])')
curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$v/install.sh" | bash
export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
nvm install --lts

echo "==> Jupyter (via pipx)"
pipx install --include-deps jupyter
pipx ensurepath

echo "==> JetBrains Toolbox (instala IntelliJ, PyCharm e Android Studio)"
TMP=$(mktemp -d)
curl -fsSL -o "$TMP/toolbox.tar.gz" "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
mkdir -p ~/.local/opt/jetbrains-toolbox
tar -xzf "$TMP/toolbox.tar.gz" -C ~/.local/opt/jetbrains-toolbox --strip-components=1
rm -rf "$TMP"
(nohup ~/.local/opt/jetbrains-toolbox/bin/jetbrains-toolbox >/dev/null 2>&1 &)

echo "==> Git"
git config --global user.name "arrualuiz"
git config --global user.email "luizarrua16@gmail.com"
git config --global init.defaultBranch main

echo
echo "Pronto! Próximos passos manuais (ver README.md):"
echo "  - No Toolbox, instalar IntelliJ, PyCharm e Android Studio"
echo "  - gh auth login (num terminal normal)"
echo "  - bash ~/dev/linux-setup/aplicar-configuracoes.sh"
