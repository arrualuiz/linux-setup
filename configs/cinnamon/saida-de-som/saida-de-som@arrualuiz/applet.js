// Troca a saída de som entre o fone e a caixa com um clique (ou Super+Ctrl+V).
// O PipeWire já leva junto o que está tocando quando a saída padrão muda.
const Applet = imports.ui.applet;
const PopupMenu = imports.ui.popupMenu;
const Settings = imports.ui.settings;
const Main = imports.ui.main;
const Util = imports.misc.util;
const Cvc = imports.gi.Cvc;
const Gio = imports.gi.Gio;
const St = imports.gi.St;

const ICONE_FONE = "xsi-audio-headphones-symbolic";
const ICONE_CAIXA = "xsi-audio-speakers-symbolic";
const ICONE_OUTRA = "xsi-audio-card-symbolic";

class SaidaDeSom extends Applet.IconApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this.setAllowedLayout(Applet.AllowedLayout.BOTH);

        this.settings = new Settings.AppletSettings(this, metadata.uuid, instanceId);
        this.settings.bind("fone", "fone", () => this._atualizar());
        this.settings.bind("caixa", "caixa", () => this._atualizar());
        this.settings.bind("atalho", "atalho", () => this._registrarAtalho());

        // Botão direito: lista de todas as saídas, pra escolher outra (ex.: o monitor)
        this._listaSaidas = new PopupMenu.PopupMenuSection();
        this._applet_context_menu.addMenuItem(this._listaSaidas, 0);
        this._applet_context_menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem(), 1);
        let configuracoes = new PopupMenu.PopupIconMenuItem("Configurações de som", "xsi-audio-volume-high", St.IconType.SYMBOLIC);
        configuracoes.connect("activate", () => Util.spawnCommandLine("cinnamon-settings sound"));
        this._applet_context_menu.addMenuItem(configuracoes, 2);

        this._control = new Cvc.MixerControl({ name: "Saída de som" });
        this._sinais = ["state-changed", "default-sink-changed", "stream-added", "stream-removed"]
            .map(sinal => this._control.connect(sinal, () => this._atualizar()));
        this._control.open();

        this._registrarAtalho();
        this._atualizar();
    }

    on_applet_clicked() {
        this._alternar();
    }

    on_applet_removed_from_panel() {
        Main.keybindingManager.removeXletHotKey(this, "trocar-saida");
        this._sinais.forEach(id => this._control.disconnect(id));
        this._control.close();
        this.settings.finalize();
    }

    _registrarAtalho() {
        Main.keybindingManager.addXletHotKey(this, "trocar-saida", this.atalho, () => this._alternar());
    }

    _pronto() {
        return this._control.get_state() === Cvc.MixerControlState.READY;
    }

    _saidas() {
        return this._pronto() ? this._control.get_sinks() : [];
    }

    _icone(saida) {
        if (!saida) return ICONE_OUTRA;
        if (saida.get_description() === this.fone) return ICONE_FONE;
        if (saida.get_description() === this.caixa) return ICONE_CAIXA;
        return ICONE_OUTRA;
    }

    _alternar() {
        if (!this._pronto()) return;
        let saidas = this._saidas();
        let atual = this._control.get_default_sink();
        let fone = saidas.find(s => s.get_description() === this.fone);
        let caixa = saidas.find(s => s.get_description() === this.caixa);

        // Do fone vai pra caixa; de qualquer outra (caixa, monitor) vai pro fone
        let destino = (atual && fone && atual.get_id() === fone.get_id()) ? caixa : fone;
        if (!destino) destino = fone || caixa;

        if (!destino || (atual && destino.get_id() === atual.get_id())) {
            let falta = fone ? this.caixa : this.fone;
            this._avisar(this._icone(atual), `${falta} não está conectado`);
            return;
        }
        this._escolher(destino);
    }

    _escolher(saida) {
        this._control.set_default_sink(saida);
        this._avisar(this._icone(saida), saida.get_description());
    }

    _avisar(icone, texto) {
        Main.osdWindowManager.show(Main.layoutManager.currentMonitor.index,
            new Gio.ThemedIcon({ name: icone }), texto, null);
    }

    _atualizar() {
        let atual = this._pronto() ? this._control.get_default_sink() : null;
        this.set_applet_icon_symbolic_name(this._icone(atual));

        if (atual) {
            let outra = atual.get_description() === this.fone ? this.caixa : this.fone;
            this.set_applet_tooltip(`Som saindo: ${atual.get_description()}\nClique pra trocar pra ${outra} (Super+Ctrl+V)`);
        } else {
            this.set_applet_tooltip("Saída de som");
        }

        this._listaSaidas.removeAll();
        for (let saida of this._saidas()) {
            let item = new PopupMenu.PopupMenuItem(saida.get_description());
            item.setShowDot(atual !== null && saida.get_id() === atual.get_id());
            item.connect("activate", () => this._escolher(saida));
            this._listaSaidas.addMenuItem(item);
        }
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new SaidaDeSom(metadata, orientation, panelHeight, instanceId);
}
