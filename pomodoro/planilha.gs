// Recebe os pomodoros do PC (pomodoro/registrar.py) e grava na aba "Pomodoros".
// Vai colado no Apps Script da planilha (Extensões → Apps Script).
// O TOKEN tem que ser igual ao de ~/.config/pomodoro/planilha.json no PC.
const TOKEN = 'COLE_O_TOKEN_AQUI';
const COLUNAS = ['id', 'Início', 'Fim', 'Minutos', 'Foco', 'App', 'Janela', 'Pausa depois'];

function doPost(e) {
  const dados = JSON.parse(e.postData.contents);
  if (dados.token !== TOKEN) return responder({ ok: false, erro: 'token inválido' });
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    const aba = configurar();
    const ultima = aba.getLastRow();
    const ids = new Set(ultima > 1 ? aba.getRange(2, 1, ultima - 1, 1).getValues().flat() : []);
    const novas = (dados.linhas || [])
      .filter((l) => !ids.has(l.id))
      .map((l) => [l.id, new Date(l.inicio), new Date(l.fim), l.minutos, l.foco, l.app, l.janela, l.pausa]);
    if (novas.length) aba.getRange(ultima + 1, 1, novas.length, COLUNAS.length).setValues(novas);
    return responder({ ok: true, gravadas: novas.length });
  } finally {
    lock.releaseLock();
  }
}

// Cria as abas "Pomodoros" e "Resumo" se ainda não existirem.
// Rode uma vez pelo editor (botão ▶ Executar) para dar a autorização.
function configurar() {
  const planilha = SpreadsheetApp.getActive();
  let aba = planilha.getSheetByName('Pomodoros');
  if (!aba) {
    const primeira = planilha.getSheets()[0];
    aba = primeira.getLastRow() === 0 ? primeira.setName('Pomodoros') : planilha.insertSheet('Pomodoros', 0);
    aba.getRange(1, 1, 1, COLUNAS.length).setValues([COLUNAS]).setFontWeight('bold');
    aba.setFrozenRows(1);
    aba.getRange('B:C').setNumberFormat('dd/mm/yyyy hh:mm');
    aba.hideColumns(1);
  }
  if (!planilha.getSheetByName('Resumo')) criarResumo(planilha);
  return aba;
}

function criarResumo(planilha) {
  const r = planilha.insertSheet('Resumo');
  // Colunas do intervalo Pomodoros!B:H → B Início, D Minutos, E Foco, F App
  const consulta = (sql) => `=QUERY(Pomodoros!B2:H, "${sql}", 0)`;
  const blocos = [
    ['A1', 'Por dia', "select toDate(B), count(B), sum(D) where B is not null group by toDate(B) order by toDate(B) desc label toDate(B) 'Dia', count(B) 'Pomodoros', sum(D) 'Minutos'"],
    ['E1', 'Por foco', "select E, count(B), sum(D) where B is not null group by E order by count(B) desc label E 'Foco', count(B) 'Pomodoros', sum(D) 'Minutos'"],
    ['I1', 'Por app', "select F, count(B), sum(D) where B is not null group by F order by count(B) desc label F 'App', count(B) 'Pomodoros', sum(D) 'Minutos'"],
    ['M1', 'Por hora do dia', "select hour(B), count(B) where B is not null group by hour(B) order by hour(B) label hour(B) 'Hora', count(B) 'Pomodoros'"],
  ];
  for (const [celula, titulo, sql] of blocos) {
    const c = r.getRange(celula);
    c.setValue(titulo).setFontWeight('bold');
    c.offset(1, 0).setFormula(consulta(sql));
  }
  r.getRange('A:A').setNumberFormat('dd/mm/yyyy');
}

function responder(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
