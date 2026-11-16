# Backup na nuvem (OneDrive, criptografado)

Quase tudo deste PC está no GitHub. O que **só existe aqui** (dados do financeiro, senhas e backups do STIGPR, material do casamento, a faculdade, o backup do Windows, `~/Documentos` e a memória do Claude em `~/.claude`) sobe todo dia para o meu OneDrive, criptografado.

## Por que não o app do OneDrive

O app sincroniza a pasta inteira nos dois sentidos. Com `node_modules`, `.venv` e afins, ele passaria o dia subindo centenas de milhares de arquivos (e apagar algo aqui apagaria lá). O `rclone` faz o contrário:

- só **sobe** (este PC manda, a nuvem guarda);
- só as pastas que eu escolhi: `~/dev`, `~/Documentos` e `~/.claude`;
- sem o que se refaz sozinho (`filtros.txt`: `node_modules`, `.venv`, `build`, `dist`, caches...). Em 15/11/2026 isso dava uns **20 GB** (o OneDrive tem 120 GB);
- **criptografado** (`rclone crypt`): na nuvem os nomes e o conteúdo ficam ilegíveis, então senha e `.env` não ficam expostos nem para a Microsoft;
- o que eu mudar ou apagar aqui não some lá: a versão anterior vai para `versoes-antigas/<data>`.

## Instalar (uma vez)

1. **rclone** (o do `apt` é de 2022; o OneDrive pede um mais novo):
   ```bash
   cd /tmp && wget https://downloads.rclone.org/rclone-current-linux-amd64.deb && sudo apt install ./rclone-current-linux-amd64.deb
   ```
2. **Ligar ao OneDrive** (abre o navegador para entrar na conta Microsoft):
   ```bash
   rclone config create onedrive onedrive
   ```
   Se ele perguntar o tipo, escolher **OneDrive Personal**.
3. **A camada criptografada**, num terminal normal, porque ele pede a senha na tela:
   ```bash
   rclone config
   ```
   `n` (novo) → nome `nuvem-cripto` → tipo `crypt` → remote `onedrive:backup-pc` → criptografar nomes: `standard` → criptografar pastas: `true` → senha: `y` e digitar a minha → segunda senha (salt): `g` (gerar) e anotar também.
   **Anotar as duas senhas fora do PC** (junto da senha da mala de fuga). Sem elas, o backup não abre.
4. **Testar sem mandar nada**, e depois a primeira cópia (demora: são uns 20 GB):
   ```bash
   ~/dev/linux-setup/backup-nuvem/backup-nuvem.sh --dry-run
   ~/dev/linux-setup/backup-nuvem/backup-nuvem.sh
   ```
5. **Todo dia às 13h** (ou no boot, se o PC estava desligado):
   ```bash
   mkdir -p ~/.config/systemd/user
   ln -sf ~/dev/linux-setup/backup-nuvem/backup-nuvem.{service,timer} ~/.config/systemd/user/
   systemctl --user daemon-reload && systemctl --user enable --now backup-nuvem.timer
   ```

## Conferir e recuperar

- Último backup: `tail ~/.local/state/backup-nuvem.log`
- O que tem lá: `rclone ls nuvem-cripto:atual/dev | head`
- Trazer uma pasta de volta: `rclone copy nuvem-cripto:atual/dev/projetos/financeiro ~/recuperado/financeiro`
- No Windows (ou em outro PC): instalar o rclone, refazer os passos 2 e 3 com **as mesmas senhas** e usar `rclone copy`.

## O que não entra

- Os volumes do Docker do WordPress local do STIGPR (ficam fora da pasta pessoal): para esses, a mala de fuga (`plano-de-fuga-windows` no `rascunhos-e-anotacoes`) exporta o banco.
- `~/Downloads`, `~/Imagens`, `~/Vídeos` e a Área de trabalho: o que importa delas vai para `~/dev` ou `~/Documentos`.
