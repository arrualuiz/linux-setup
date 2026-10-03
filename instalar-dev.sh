#!/usr/bin/env bash
# Instala ferramentas de programação a partir dos repositórios oficiais.
# Rodar com: sudo bash ~/dev/linux-setup/instalar-dev.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Rode com sudo: sudo bash $0"; exit 1
fi
USUARIO="${SUDO_USER:-arrua}"
KEYS=/etc/apt/keyrings
install -d -m 0755 "$KEYS"

echo "==> Pacotes básicos"
apt-get update
apt-get install -y ca-certificates curl gnupg apt-transport-https \
  git build-essential python3-pip python3-venv pipx openjdk-21-jdk

echo "==> Repositório do VS Code (Microsoft)"
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o "$KEYS/packages.microsoft.gpg"
echo "deb [arch=amd64 signed-by=$KEYS/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
# evita que o pacote do VS Code crie um repositório duplicado
echo "code code/add-microsoft-repo boolean false" | debconf-set-selections

echo "==> Repositório do Sublime Text"
curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg -o "$KEYS/sublimehq-pub.asc"
echo "deb [signed-by=$KEYS/sublimehq-pub.asc] https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list

echo "==> Repositório do GitHub CLI"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$KEYS/githubcli-archive-keyring.gpg"
chmod go+r "$KEYS/githubcli-archive-keyring.gpg"
echo "deb [arch=amd64 signed-by=$KEYS/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

echo "==> Repositório do Docker (base Ubuntu noble)"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$KEYS/docker.asc"
chmod a+r "$KEYS/docker.asc"
. /etc/os-release
echo "deb [arch=amd64 signed-by=$KEYS/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" > /etc/apt/sources.list.d/docker.list

echo "==> Repositório do DBeaver"
curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor --yes -o "$KEYS/dbeaver.gpg"
echo "deb [signed-by=$KEYS/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" > /etc/apt/sources.list.d/dbeaver.list

echo "==> Instalando programas"
apt-get update
apt-get install -y code sublime-text gh dbeaver-ce \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Permitindo usar Docker sem sudo e o emulador Android (KVM)"
usermod -aG docker,kvm "$USUARIO"

echo
echo "Tudo instalado! Faça logout e login de novo para o Docker funcionar sem sudo."
