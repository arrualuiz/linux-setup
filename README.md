# Meu setup Linux Mint

Tudo o que foi instalado e configurado depois que troquei do Windows para o **Linux Mint 22.3 Cinnamon** (out/2026).
Serve de guia caso eu formate ou troque de PC.

---

## 🖥️ Meu hardware (e o que aprendi sobre ele)

| Peça | Observação |
|---|---|
| Xeon E5-2620 v3 · Huananzhi X99-8M-F · 16 GB RAM | — |
| SSD Kingston A400 240 GB | — |
| **GeForce GT 420** | Usa o driver livre **nouveau**. **Não instalar driver NVIDIA**: a placa (Fermi) não tem driver proprietário que funcione nos kernels novos. Upgrade pensado: RX 580 (AMD funciona de fábrica no Linux). |
| Monitores | HDMI-1 1920x1080 (principal) + VGA-1 1440x900 |
| Som | Caixa de som = placa **C-Media CMI8738** (PCI). O som **onboard Realtek não funciona** no Linux (defeito da placa-mãe, não adianta insistir). Headset HyperX Cloud Stinger Core 7.1 USB. A webcam tem microfone. |

---

## 🚀 Reinstalando do zero: ordem dos passos

1. **Instalar o Linux Mint** (Cinnamon) e rodar as atualizações:
   ```bash
   sudo apt update && sudo apt upgrade
   ```
2. **Instalar o Google Chrome**: baixar o `.deb` em google.com/chrome e abrir com dois cliques.
3. **Trazer esta pasta** de volta:
   ```bash
   git clone https://github.com/arrualuiz/linux-setup.git ~/dev/linux-setup
   ```
4. **Programas que precisam de senha** (VS Code, Sublime, Git, GitHub CLI, Docker, DBeaver, Java 21):
   ```bash
   sudo bash ~/dev/linux-setup/instalar-dev.sh
   ```
5. **Programas que não precisam de senha** (Postman, Flameshot, NormCap, CopyQ, Smile, Node, Jupyter, JetBrains Toolbox, config do Git):
   ```bash
   bash ~/dev/linux-setup/instalar-usuario.sh
   ```
6. **Passos manuais** (ver a seção abaixo).
7. **Aplicar as configurações** (barras de tarefas, atalhos, ícones, lançadores):
   ```bash
   bash ~/dev/linux-setup/aplicar-configuracoes.sh
   ```
8. **Reiniciar o PC.** O grupo do Docker só passa a valer depois de reiniciar.

---

## ✋ Passos manuais (não dá pra automatizar)

- **GitHub CLI:** rodar `gh auth login` num **terminal normal**, porque ele é interativo. Escolher GitHub.com → HTTPS → login pelo navegador. Conta: `arrualuiz`.
- **JetBrains Toolbox:** abrir e instalar **IntelliJ**, **PyCharm** e **Android Studio**. Depois fixar eles na barra (botão direito → fixar).
- **Chrome Pessoal:** entrar com `luizarrua16@gmail.com`.
- **Chrome PUC:** abrir pelo ícone "Chrome PUC" (ou **Ctrl+Alt+P**) e entrar com **`dev.luizarrua@gmail.com`**. Esse Chrome é uma instância separada (`~/.config/chrome-puc`), por isso fica num botão próprio na barra.
- **Google Agenda:** bloquear as notificações no Chrome Pessoal em `chrome://settings/content/notifications`.
- **Claude Code:** instalar e logar. No VS Code, instalar a extensão **"Claude Code"**.
- **Meus repositórios:** clonar todos de volta:
  ```bash
  mkdir -p ~/dev/projetos && cd ~/dev/projetos
  gh repo list arrualuiz --limit 300 --json name --jq '.[].name' | xargs -I{} gh repo clone arrualuiz/{}
  ```

---

## ⌨️ Atalhos que configurei (iguais ao Windows)

| Atalho | O que faz | App |
|---|---|---|
| **Print** | Captura de tela (seleciona área, copia/salva/desenha) | Flameshot |
| **Shift + Print** | Copia o **texto** da tela (OCR, pt + en) | NormCap |
| **Super + V** | Histórico da área de transferência | CopyQ |
| **Super + .** | Emojis | Smile |
| **Super + Tab** | Todas as janelas e espaços de trabalho | Expo (do Cinnamon) |
| **Ctrl + Alt + ↓** | Todas as janelas do espaço atual | Scale (do Cinnamon) |
| **Ctrl + Alt + ← / →** | Troca de espaço de trabalho | Cinnamon |
| **Ctrl + Alt + P** | Abre o Chrome da PUC | — |

---

## 🎨 Aparência e barra de tarefas

- **Efeitos visuais desligados**, porque a GT 420 é fraca.
- **Duas barras, uma por monitor**, no estilo Windows 10:
  - Monitor 1: menu + apps fixados + bandeja do sistema + relógio.
  - Monitor 2: menu + só as janelas abertas nele + relógio.
  - Applet "grouped-window-list" (instância 16 no painel 1, 17 no painel 2), altura 46, ícones 36.
  - **Cada janela tem seu botão** (sem agrupar), mostrando o título da janela.
- **Ícones da área de trabalho** só no monitor principal.
- **Apps fixados no monitor 1:** Terminal, Chrome Pessoal, Chrome PUC, Jupyter Lab, VS Code, IntelliJ, PyCharm, Android Studio, DBeaver.

---

## 📁 Minhas pastas

```
~/dev/
├── projetos/            ← repositórios do GitHub (git pull antes, git push depois)
├── faculdade/pucpr/ads/ ← <N>-periodo/<materia>/ com revisao-<materia>.md, PDFs, xlsx...
│   └── instrucoes-revisao.md  ← meu método de revisão Claude + NotebookLM
└── linux-setup/         ← esta pasta
```

- Atalho **"Faculdade"** na área de trabalho → `~/dev/faculdade/pucpr/ads`.
- **Pendente:** trazer o resto do antigo `C:\dev` (~5 GB) do HD externo, sem `node_modules`, e sincronizar a pasta da faculdade com o **Google Drive via rclone**, ignorando `node_modules`, `.venv` etc.

---

## 🤖 Claude Code

- Abrir com `claude` no terminal. As conversas ficam **por pasta**: `claude -c` continua a última e `claude -r` lista as antigas.
- Para coisas do sistema, abrir na pasta pessoal (`~`). É lá que fica a memória sobre este PC.
- A pasta `configs/claude-memoria/` tem uma cópia dessa memória. Numa instalação nova, copiar o conteúdo para `~/.claude/projects/-home-arrua/memory/`.

---

## 🗂️ O que tem nesta pasta

| Arquivo | Para quê |
|---|---|
| `instalar-dev.sh` | Programas via apt (precisa de `sudo`) |
| `instalar-usuario.sh` | Flatpaks, Node, Jupyter, Toolbox, Git (sem senha) |
| `aplicar-configuracoes.sh` | Barras, atalhos, ícones, lançadores, som |
| `configs/cinnamon/` | Barras de tarefas (16/17.json), painéis, atalhos (`atalhos.dconf`) |
| `configs/aplicativos/` + `configs/icones/` | Lançadores do Chrome Pessoal/PUC e do Jupyter |
| `configs/wireplumber/` | Nomes amigáveis do som (só serve com o mesmo hardware) |
| `configs/autostart/` | CopyQ abrindo junto com o sistema |
| `configs/claude-memoria/` | Cópia da memória do Claude sobre este PC |
