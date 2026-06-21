# Changelog

## v1.0.2 - 2026-06-21

- Corrigido `installer\INSTALAR-PC-BLACKBOX.bat` apos reorganizacao da pasta fonte.
- Instalador agora procura `install.ps1` na raiz do projeto e falha claramente se nao encontrar.
- Adicionado modo gamer para temperatura: durante jogo/carga de jogo, alertas de temperatura viram log silencioso em vez de popup/beep.
- Adicionados limites emergenciais separados para CPU/GPU; acima deles o alerta visual continua aparecendo por seguranca.
- Adicionado log silencioso `logs\alerts\suppressed-temperature-alerts.jsonl`.
- Adicionado script `installer\PUBLICAR-GITHUB.ps1` para criar repositorio novo no GitHub via GitHub CLI.

## v1.0.1 - 2026-06-21

- Corrigido fechamento do olhinho visual quando o menu `Sair do olhinho` era usado.
- Adicionado `installer\FECHAR-OLHINHO-PC-BLACKBOX.bat` para encerrar somente a interface visual sem parar o agente.
- Adicionado arquivo-sinal `logs\state\status-icon-exit.flag` para evitar instancias presas.

## v1.0.0 - 2026-06-21

- Primeira versao com acabamento de produto local.
- Adicionado dashboard visual com olhinho animado na bandeja do Windows.
- Adicionado olho piscando e pupila em movimento no icone de status.
- Adicionados icones `.ico` para o olhinho, instalador/reparador e desinstalador.
- Instalador agora funciona como instalacao, reparo e upgrade por cima.
- Instalador preserva logs, relatorios e estado existente em `C:\PC-Blackbox`.
- Layout instalado mais organizado com `app`, `assets`, `shortcuts`, `logs`, `reports`, `config`, `modules` e `docs`.
- Mantida compatibilidade com `src` para upgrades vindos das versoes anteriores.
- README atualizado para explicar o problema especifico que a ferramenta investiga.
- Adicionada documentacao de escopo, limites e uso seguro.
- Projeto fonte reorganizado para raiz limpa: `installer`, `src/app`, `src/modules`, `src/config`, `assets` e `docs`.
- Removidos logs e relatorios gerados da pasta do projeto fonte.
- Scripts operacionais manuais movidos para `installer`.
