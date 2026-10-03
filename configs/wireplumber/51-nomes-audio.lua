-- Nomes amigáveis para as saídas de som
rule_caixa = {
  matches = { { { "node.name", "equals", "alsa_output.pci-0000_07_00.0.analog-stereo" } } },
  apply_properties = {
    ["node.description"] = "Caixa de som",
    ["node.nick"] = "Caixa de som",
    ["priority.session"] = 2000,
    ["priority.driver"] = 2000,
  },
}
rule_fone = {
  matches = { { { "node.name", "matches", "alsa_output.usb-Kingston_HyperX*" } } },
  apply_properties = {
    ["node.description"] = "Fone HyperX",
    ["node.nick"] = "Fone HyperX",
  },
}
rule_mic = {
  matches = { { { "node.name", "matches", "alsa_input.usb-Kingston_HyperX*" } } },
  apply_properties = { ["node.description"] = "Microfone HyperX" },
}
rule_hdmi = {
  matches = { { { "node.name", "matches", "alsa_output.pci-0000_03_00.1.*" } } },
  apply_properties = { ["node.description"] = "Monitor (HDMI)" },
}
table.insert(alsa_monitor.rules, rule_caixa)
table.insert(alsa_monitor.rules, rule_fone)
table.insert(alsa_monitor.rules, rule_mic)
table.insert(alsa_monitor.rules, rule_hdmi)
