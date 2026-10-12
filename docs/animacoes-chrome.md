# Animações no Chrome (sistema sem animações)

O sistema fica com as animações **desligadas** (preferência pessoal):

```
gsettings set org.gnome.desktop.interface enable-animations false
```

Com isso, o Chrome informa aos sites `prefers-reduced-motion: reduce`, e as
animações dos sites que eu faço não aparecem.

## DevTools não resolve

Em DevTools → Rendering → *Emulate CSS prefers-reduced-motion* só existem
**No emulation** (segue o sistema, ou seja, "reduce") e **reduce**.
Não há opção para forçar animações ligadas.

## Ligar só no Chrome (para testar)

Fechar todas as janelas do Chrome e abrir pelo terminal:

```
google-chrome --force-prefers-no-reduced-motion
```

O resto do sistema continua sem animações.

## Alternativa: ligar no sistema só durante o teste

```
gsettings set org.gnome.desktop.interface enable-animations true    # liga para testar
gsettings set org.gnome.desktop.interface enable-animations false   # desliga depois
```

Essa chave vale para o sistema inteiro (todos os apps GTK), por isso só usar
temporariamente.
