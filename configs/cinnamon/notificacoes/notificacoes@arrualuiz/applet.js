// Sino de notificações com o número em destaque e um modo Não perturbe que guarda
// em vez de apagar. Baseado no notifications@cinnamon.org: o "Desativar notificações"
// do Cinnamon joga fora o que chega com ele ligado, então nada somava no sino.
const Applet = imports.ui.applet;
const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const MessageTray = imports.ui.messageTray;
const Settings = imports.ui.settings;
const Util = imports.misc.util;
const Mainloop = imports.mainloop;
const Gio = imports.gi.Gio;
const St = imports.gi.St;

const Urgency = MessageTray.Urgency;
const NotificationDestroyedReason = MessageTray.NotificationDestroyedReason;
const PANEL_EDIT_MODE_KEY = "panel-edit-mode";

const ICONE = "xsi-notifications-symbolic";
const ICONE_SILENCIO = "xsi-notifications-disabled-symbolic";
const COR_SINO = "color: #ffc23d;";
const COR_URGENTE = "color: #ff4d4d;";
const ESTILO_NUMERO = "background-color: #e01b24; color: #ffffff; font-weight: bold;" +
    " border-radius: 9px; padding: 0 6px; margin-left: 2px; min-width: 8px; text-align: center;";

class Notificacoes extends Applet.TextIconApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this.setAllowedLayout(Applet.AllowedLayout.BOTH);

        this.settings = new Settings.AppletSettings(this, metadata.uuid, instanceId);
        this.settings.bind("naoPerturbe", "naoPerturbe", () => this._mudouSilencio());
        this.settings.bind("ignorarPassageiras", "ignorarPassageiras");
        this.settings.bind("maisNovasPrimeiro", "maisNovasPrimeiro", () => this._atualizar());
        this.settings.bind("atalhoAbrir", "atalhoAbrir", () => this._registrarAtalhos());
        this.settings.bind("atalhoLimpar", "atalhoLimpar", () => this._registrarAtalhos());
        this.settings.bind("atalhoNaoPerturbe", "atalhoNaoPerturbe", () => this._registrarAtalhos());
        this._registrarAtalhos();

        this._orientation = orientation;
        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.notificacoes = [];    // da mais velha pra mais nova
        this._piscando = false;

        this._sinalBandeja = Main.messageTray.connect("notify-applet-update", (bandeja, n) => this._chegou(n));
        this._sinalEdicao = global.settings.connect("changed::" + PANEL_EDIT_MODE_KEY, () => this._atualizar());
        this._interceptarBandeja();
    }

    // Com o Não perturbe ligado, a notificação pula o balão e vem direto pra lista
    _interceptarBandeja() {
        let bandeja = Main.messageTray;
        let mostrar = bandeja._showNotification;
        bandeja._showNotification = () => {
            if (!this.naoPerturbe) return mostrar.call(bandeja);
            let n = bandeja._notificationQueue.shift();
            bandeja.emit("notify-applet-update", n);
            bandeja._updateState();
        };
    }

    _registrarAtalhos() {
        Main.keybindingManager.addXletHotKey(this, "abrir", this.atalhoAbrir, () => this._abrir());
        Main.keybindingManager.addXletHotKey(this, "limpar", this.atalhoLimpar, () => this._limpar());
        Main.keybindingManager.addXletHotKey(this, "nao-perturbe", this.atalhoNaoPerturbe, () => this._alternarSilencio());
    }

    on_applet_added_to_panel() {
        this.on_orientation_changed(this._orientation);
        MessageTray.extensionsHandlingNotifications++;
    }

    on_applet_removed_from_panel() {
        ["abrir", "limpar", "nao-perturbe"].forEach(nome => Main.keybindingManager.removeXletHotKey(this, nome));
        Main.messageTray.disconnect(this._sinalBandeja);
        global.settings.disconnect(this._sinalEdicao);
        delete Main.messageTray._showNotification;    // volta o do Cinnamon
        MessageTray.extensionsHandlingNotifications--;
        if (MessageTray.extensionsHandlingNotifications === 0)
            this._limpar();
        this.settings.finalize();
    }

    on_orientation_changed(orientation) {
        this._orientation = orientation;
        if (this.menu)
            this.menu.destroy();
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);
        this._montarMenu();
    }

    on_applet_clicked() {
        this._abrir();
    }

    // Clique do meio liga/desliga o Não perturbe
    on_applet_middle_clicked() {
        this._alternarSilencio();
    }

    _montarMenu() {
        this._titulo = new PopupMenu.PopupMenuItem("");
        this._titulo.actor.reactive = false;
        this._titulo.label.add_style_class_name("popup-subtitle-menu-item");

        this._chave = new PopupMenu.PopupSwitchMenuItem("Não perturbe (só guardar aqui)", this.naoPerturbe);
        this._chave.connect("toggled", (item, ligado) => {
            this.naoPerturbe = ligado;
            this._mudouSilencio();
        });

        this._limparItem = new PopupMenu.PopupIconMenuItem("Limpar notificações", "xsi-edit-clear-all-symbolic", St.IconType.SYMBOLIC);
        this._limparItem.connect("activate", () => this._limpar());

        let caixa = new St.BoxLayout({ name: "traycontainer", vertical: true });
        this._lista = new St.BoxLayout({ vertical: true });
        this._rolagem = new St.ScrollView({ x_fill: true, y_fill: true, y_align: St.Align.START, style_class: "vfade" });
        caixa.add(this._rolagem);
        this._rolagem.add_actor(this._lista);
        this._rolagem.set_policy(St.PolicyType.NEVER, St.PolicyType.AUTOMATIC);
        this._rolagem.set_clip_to_allocation(true);
        let barra = this._rolagem.get_vscroll_bar();
        barra.connect("scroll-start", () => { this.menu.passEvents = true; });
        barra.connect("scroll-stop", () => { this.menu.passEvents = false; });

        // Na barra de baixo a lista fica em cima e os botões perto do sino
        let partes = [this._titulo, caixa, new PopupMenu.PopupSeparatorMenuItem(), this._limparItem, this._chave];
        if (this._orientation != St.Side.BOTTOM)
            partes.reverse();
        for (let parte of partes) {
            if (parte === caixa) this.menu.addActor(caixa);
            else this.menu.addMenuItem(parte);
        }
        this.menu.addSettingsAction("Configurações de notificação", "notifications");

        // Notificações que já estavam guardadas voltam pra lista nova
        for (let n of this.notificacoes) {
            n.actor.unparent();
            this._lista.add(n.actor);
            n.actor._parent_container = this._lista;
        }
        this._atualizar();
    }

    _chegou(n) {
        if (this.ignorarPassageiras && n.isTransient) {
            n.destroy();
            return;
        }

        n.actor.unparent();
        if (this.notificacoes.indexOf(n) != -1) {    // a mesma notificação, atualizada
            if (n._destroyed) {
                this.notificacoes.splice(this.notificacoes.indexOf(n), 1);
            } else {
                n._inNotificationBin = true;
                global.reparentActor(n.actor, this._lista);
                n._timeLabel.show();
            }
            this._atualizar();
            return;
        } else if (n._destroyed) {
            return;
        }

        n._inNotificationBin = true;
        this.notificacoes.push(n);
        this._lista.add(n.actor);
        n.actor._parent_container = this._lista;
        n.actor.add_style_class_name("notification-applet-padding");
        n.connect("scrolling-changed", (notif, rolando) => { this.menu.passEvents = rolando; });
        n.connect("destroy", () => {
            let i = this.notificacoes.indexOf(n);
            if (i != -1)
                this.notificacoes.splice(i, 1);
            this._atualizar();
        });
        n._timeLabel.show();
        this._atualizar();
    }

    _abrir() {
        for (let n of this.notificacoes)
            n._timeLabel.clutter_text.set_markup(quando(n._timestamp));
        this.menu.toggle();
    }

    _alternarSilencio() {
        this.naoPerturbe = !this.naoPerturbe;
        this._mudouSilencio();
        Main.osdWindowManager.show(Main.layoutManager.currentMonitor.index,
            new Gio.ThemedIcon({ name: this.naoPerturbe ? ICONE_SILENCIO : ICONE }),
            this.naoPerturbe ? "Não perturbe ligado" : "Notificações na tela", null);
    }

    // Ao ligar, o balão que estiver na tela já vai pro sino (os urgentes não somem sozinhos)
    _mudouSilencio() {
        let bandeja = Main.messageTray;
        if (this.naoPerturbe && bandeja._notificationState == MessageTray.State.SHOWN)
            bandeja._hideNotification();
        this._atualizar();
    }

    _limpar() {
        for (let n of this.notificacoes.slice().reverse()) {
            this._lista.remove_actor(n.actor);
            n.destroy(NotificationDestroyedReason.DISMISSED);
        }
        this.notificacoes = [];
        this._atualizar();
    }

    _atualizar() {
        if (!this.menu || !this._lista) return;
        let total = this.notificacoes.length;
        let urgente = this.notificacoes.some(n => n.urgency == Urgency.CRITICAL);

        this.set_applet_icon_symbolic_name(this.naoPerturbe ? ICONE_SILENCIO : ICONE);
        this._applet_icon.set_style(total == 0 ? null : (urgente ? COR_URGENTE : COR_SINO));
        this.set_applet_label(total > 0 ? (total > 99 ? "99+" : total.toString()) : "");
        this._applet_label.set_style(total > 0 ? ESTILO_NUMERO : null);
        this.actor.show();    // sempre na barra, mesmo vazio

        let estado = this.naoPerturbe ? "Não perturbe ligado: nada aparece na tela\n" : "";
        this.set_applet_tooltip(`${estado}${contagem(total)}\nClique do meio (ou Super+Ctrl+N): Não perturbe`);
        this._titulo.label.set_text(contagem(total));
        this._limparItem.actor.visible = total > 0;
        this._chave.setToggleState(this.naoPerturbe);

        this._ordenar();
        this._lista.queue_relayout();

        if (urgente && !this._piscando) {
            this._piscando = true;
            this._piscar();
        } else if (!urgente) {
            this._piscando = false;
            this._applet_icon.opacity = 255;
        }
    }

    _ordenar() {
        let ordem = this.notificacoes.slice();
        if (this.maisNovasPrimeiro)
            ordem.reverse();
        for (let filho of this._lista.get_children())
            this._lista.remove_child(filho);
        for (let n of ordem)
            this._lista.add_child(n.actor);
    }

    _piscar() {
        if (!this._piscando) return false;
        this._applet_icon.opacity = this._applet_icon.opacity == 255 ? 90 : 255;
        Mainloop.timeout_add_seconds(1, () => this._piscar());
        return false;
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new Notificacoes(metadata, orientation, panelHeight, instanceId);
}

function contagem(total) {
    if (total == 0) return "Nenhuma notificação";
    return total == 1 ? "1 notificação" : `${total} notificações`;
}

function quando(hora) {
    let segundos = Math.floor((Date.now() - hora.getTime()) / 1000);
    let texto = hora.toLocaleFormat("%d/%m, %H:%M");
    if (segundos <= 15) return `${texto} (agora)`;
    if (segundos < 60) return `${texto} (há ${segundos} s)`;
    if (segundos < 3600) return `${texto} (há ${Math.floor(segundos / 60)} min)`;
    return texto;
}
