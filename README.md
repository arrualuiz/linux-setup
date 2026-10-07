# Meu Linux

Tudo o que instalei, configurei e consertei depois que troquei o Windows 10 pelo **Linux Mint 22.3 Cinnamon** (out/2026), num PC com Xeon de X99.
Serve de guia caso eu formate ou troque de PC, e de diário dos problemas que já resolvi.

---

## 🖥️ Meu hardware (e o que aprendi sobre ele)

| Peça | Observação |
|---|---|
| Xeon E5-2620 v3 · Huananzhi X99-8M-F · 16 GB RAM | Nome do PC: `arruadev`. Ajustado para desempenho máximo (ver [Desempenho](#-desempenho)). |
| SSD Kingston A400 240 GB | O Linux foi instalado num **notebook** e o SSD veio para este PC. No Linux isso funciona normal (ele detecta o hardware a cada boot); só sobraram pacotes de notebook, já removidos. |
| **GeForce GT 420** | Usa o driver livre **nouveau**. **Não instalar driver NVIDIA**: a placa (Fermi) não tem driver proprietário que funcione nos kernels novos. ⚠️ **Com aceleração de vídeo ligada no Chrome, o PC inteiro congela** (ver [Problemas resolvidos](#-problemas-que-já-resolvi)). Upgrade pensado: RX 580 (AMD funciona de fábrica no Linux). |
| Monitores | HDMI-1 1920x1080 (principal) + VGA-1 1440x900 |
| Som | Caixa de som = placa **C-Media CMI8738** (PCI). Precisa do parâmetro de boot `iommu=pt` (ver [Problemas resolvidos](#-problemas-que-já-resolvi)). O som **onboard Realtek não funciona** no Linux (defeito da placa-mãe, não adianta insistir). Headset HyperX Cloud Stinger Core 7.1 USB. A webcam tem microfone. |

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
6. **Ajustes do sistema** (parâmetros de boot, nome do PC, swap, remoção de sobras de notebook):
   ```bash
   sudo bash ~/dev/linux-setup/ajustar-sistema.sh
   ```
7. **Passos manuais** (ver a seção abaixo).
8. **Aplicar as configurações** (barras de tarefas, atalhos, ícones, lançadores, energia; com a GT 420, desliga a aceleração do Chrome e do VS Code). Rodar **com o Chrome fechado**:
   ```bash
   bash ~/dev/linux-setup/aplicar-configuracoes.sh
   ```
9. **Reiniciar o PC.** O grupo do Docker, o nome do PC e os parâmetros de boot só passam a valer depois de reiniciar.

---

## ✋ Passos manuais (não dá pra automatizar)

- **GitHub CLI:** rodar `gh auth login` num **terminal normal**, porque ele é interativo. Escolher GitHub.com → HTTPS → login pelo navegador. Conta: `arrualuiz`.
- **JetBrains Toolbox:** abrir e instalar **IntelliJ**, **PyCharm** e **Android Studio**. Depois fixar eles na barra (botão direito → fixar).
- **Chrome Pessoal:** entrar com `luizarrua16@gmail.com`.
- **Chrome PUC:** abrir pelo ícone "Chrome PUC" (ou **Ctrl+Alt+P**) e entrar com **`dev.luizarrua@gmail.com`**. Esse Chrome é uma instância separada (`~/.config/chrome-puc`), por isso fica num botão próprio na barra.
- **Google Agenda:** bloquear as notificações no Chrome Pessoal em `chrome://settings/content/notifications`.
- **Android Studio:** ao criar um emulador (AVD), em *Emulated Performance → Graphics* escolher **Software**, enquanto a placa for a GT 420.
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
- **Ícones da área de trabalho** só no monitor principal, e **livres pra arrastar** ("Organizar automaticamente" desligado, mas encaixando na grade). Fica em `~/.config/nemo/desktop-metadata`. Pra ligar/desligar na mão: botão direito na área de trabalho.
- **Correção da barra (Cinnamon 6.x):** havia um bug em que app fixado, ao abrir, aparecia só como ícone com o traço azul, sem o nome. Corrigi numa cópia do applet em `~/.local/share/cinnamon/applets/grouped-window-list@cinnamon.org/` (que tem prioridade sobre a do sistema). A mudança está em `configs/cinnamon/correcao-barra/appGroup.patch`. Para reaplicar: copiar `/usr/share/cinnamon/applets/grouped-window-list@cinnamon.org` para essa pasta, aplicar o patch e **reiniciar o Cinnamon** (Ctrl+Alt+Esc), porque só recarregar o applet não basta. ⚠️ Essa cópia não recebe as atualizações do Cinnamon. Se a barra der problema depois de uma atualização, apagar a pasta e reiniciar o Cinnamon.
- **Apps fixados no monitor 1:** Terminal, Chrome Pessoal, Chrome PUC, Jupyter Lab, VS Code, IntelliJ, PyCharm, Android Studio, DBeaver.

---

## ⚡ Desempenho

| Ajuste | Onde | O que faz |
|---|---|---|
| `cpufreq.default_governor=performance` | boot (GRUB) | Processador sempre pronto na frequência máxima, sem esperar "acordar". |
| `mitigations=off` | boot (GRUB) | Desliga as proteções contra falhas do tipo Spectre/Meltdown. Num Xeon v3 dá uns 5–15% a mais em compilação, Docker e disco. **Troca segurança por velocidade**: para voltar, tirar o parâmetro de `/etc/default/grub`, rodar `sudo update-grub` e reiniciar. |
| `vm.swappiness=10` | `/etc/sysctl.d/99-desempenho.conf` | Usa a swap só quando a RAM está realmente acabando. |
| Perfil de energia **desempenho** | `powerprofilesctl set performance` | Turbo mais agressivo. |
| Efeitos visuais desligados | Cinnamon | Menos trabalho para a placa de vídeo. |

Os três primeiros ficam em `ajustar-sistema.sh` e os dois últimos em `aplicar-configuracoes.sh`. Para conferir depois de reiniciar:
```bash
cat /proc/cmdline                                           # parâmetros de boot
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor   # performance
powerprofilesctl get                                        # performance
```

### 🎬 Vídeo sem placa de vídeo decente

A GT 420 com nouveau não decodifica vídeo, então o YouTube roda todo no processador. A extensão **enhanced-h264ify** (Chrome Pessoal) bloqueia os formatos pesados (VP8, VP9, AV1) e os vídeos a 60 fps, e o YouTube cai para **H.264 até 1080p 30 fps**, que é o mais leve. Se quiser vídeo a 60 fps, desmarcar "Block 60fps" nas opções da extensão; o Xeon aguenta, só usa mais CPU.

---

## 🩺 Problemas que já resolvi

### PC congelando inteiro, precisando reiniciar no botão (06/10/2026)
- **Sintoma:** a tela travava por completo e só voltava reiniciando. Aconteceu 2 vezes seguidas.
- **Causa:** o Chrome usa a placa de vídeo para desenhar as páginas. Com a GT 420 e o driver nouveau, ele manda comandos que a placa não aguenta, e ela trava. Como ela também desenha a tela toda, o PC inteiro congela. O log mostrava milhares de erros `nouveau ... gr: DATA_ERROR ... chrome[...]` e um `TRAP` logo antes de cada travamento.
- **Solução:** aceleração de hardware **desligada** nos dois Chromes (`chrome://settings/system` → "Usar aceleração gráfica quando disponível") e no VS Code (`"disable-hardware-acceleration": true` em `~/.vscode/argv.json`, que usa o mesmo motor do Chrome). O `aplicar-configuracoes.sh` já faz isso sozinho se detectar a GT 420.
- **Como conferir se voltou a acontecer:**
  ```bash
  journalctl -b -1 -k | grep -c DATA_ERROR   # erros da placa no boot anterior
  ```

### Erros "DMAR" da placa de som (06/10/2026)
- **Sintoma:** milhares de linhas `DMAR: [DMA Read NO_PASID] Request device [07:00.0] ... PTE Read access is not set` no log (4.524 num boot só). Pode causar estalos ou cortes no som.
- **Causa:** o kernel liga a proteção de memória (IOMMU) no modo "Translated". A placa de som PCI antiga (C-Media) lê um pouquinho além do buffer dela, e a proteção bloqueia.
- **Solução:** parâmetro de boot `iommu=pt` (os dispositivos do próprio PC acessam a memória direto; a proteção continua disponível para máquinas virtuais).

### SSD veio de um notebook (06/10/2026)
- O PC continuava se chamando `notebook` e tinha pacotes de notebook instalados: applet de placa híbrida NVIDIA, leitor de digital, sensor de rotação, controle térmico de notebook (thermald), driver de vídeo Intel, gerenciador de modem 3G e o verificador do pendrive de instalação (`casper-md5check`, que aparecia como "falhou").
- **Solução:** `ajustar-sistema.sh` troca o nome para `arruadev` e remove essas sobras.

### Barra de tarefas sem o nome dos apps fixados (03/10/2026)
- Ver [Aparência e barra de tarefas](#-aparência-e-barra-de-tarefas).

### Som onboard sem saída (02/10/2026)
- O codec Realtek ALC662 da placa-mãe Huananzhi tem o pino da saída ligado como entrada. É defeito de hardware, não tem conserto por software. Solução: usar a placa C-Media PCI.

---

## 🔜 Quando a RX 580 chegar

1. Trocar a placa e ligar o PC. **Não precisa instalar driver nenhum**: o driver da AMD (`amdgpu`) já vem no kernel e o firmware dela já está instalado.
2. Religar a aceleração de hardware nos **dois** Chromes (`chrome://settings/system`) e no VS Code (comentar a linha `disable-hardware-acceleration` em `~/.vscode/argv.json`).
3. No Android Studio, voltar o *Graphics* dos emuladores para **Hardware** ou **Automatic**.
4. Conferir com `glxinfo -B | grep renderer` (deve aparecer AMD/Radeon).
5. Atualizar a tabela de hardware deste README.

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
- A memória fica em `~/.claude/projects/-home-arrua/memory/` e **não vai para este repositório** (ele é público e a memória tem dados pessoais). Numa reinstalação, copiar essa pasta junto com o backup pessoal.

---

## 🗂️ O que tem nesta pasta

| Arquivo | Para quê |
|---|---|
| `instalar-dev.sh` | Programas via apt (precisa de `sudo`) |
| `instalar-usuario.sh` | Flatpaks, Node, Jupyter, Toolbox, Git (sem senha) |
| `ajustar-sistema.sh` | Boot (GRUB), nome do PC, swap, remoção de sobras de notebook (precisa de `sudo`) |
| `aplicar-configuracoes.sh` | Barras, atalhos, ícones, lançadores, som, energia, aceleração de vídeo |
| `configs/cinnamon/` | Barras de tarefas (16/17.json), painéis, atalhos (`atalhos.dconf`) |
| `configs/aplicativos/` + `configs/icones/` | Lançadores do Chrome Pessoal/PUC e do Jupyter |
| `configs/wireplumber/` | Nomes amigáveis do som (só serve com o mesmo hardware) |
| `configs/autostart/` | CopyQ abrindo junto com o sistema |
