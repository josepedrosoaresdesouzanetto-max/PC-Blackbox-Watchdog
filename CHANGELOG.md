# Changelog

## v1.0.2 - 2026-06-21

- Corrigido `installer\INSTALAR-PC-BLACKBOX.bat` após reorganização da pasta fonte.
- Instalador agora procura `install.ps1` na raiz do projeto e falha claramente se não encontrar.
- Adicionado modo gamer para temperatura: durante jogo/carga de jogo, alertas de temperatura viram log silencioso em vez de popup/beep.
- Adicionados limites emergenciais separados para CPU/GPU; acima deles o alerta visual continua aparecendo por segurança.
- Adicionado log silencioso `logs\alerts\suppressed-temperature-alerts.jsonl`.
- Adicionado script `installer\PUBLICAR-GITHUB.ps1` para criar repositório novo no GitHub via GitHub CLI.

## v1.0.1 - 2026-06-21

- Corrigido fechamento do olhinho visual quando o menu `Sair do olhinho` era usado.
- Adicionado `installer\FECHAR-OLHINHO-PC-BLACKBOX.bat` para encerrar somente a interface visual sem parar o agente.
- Adicionado arquivo-sinal `logs\state\status-icon-exit.flag` para evitar instâncias presas.

## v1.0.0 - 2026-06-21

- Primeira versão com acabamento de produto local.
- Adicionado dashboard visual com olhinho animado na bandeja do Windows.
- Adicionado olho piscando e pupila em movimento no ícone de status.
- Adicionados ícones `.ico` para o olhinho, instalador/reparador e desinstalador.
- Instalador agora funciona como instalação, reparo e upgrade por cima.
- Instalador preserva logs, relatórios e estado existente em `C:\PC-Blackbox`.
- Layout instalado mais organizado com `app`, `assets`, `shortcuts`, `logs`, `reports`, `config`, `modules` e `docs`.
- Mantida compatibilidade com `src` para upgrades vindos das versões anteriores.
- README atualizado para explicar o problema específico que a ferramenta investiga.
- Adicionada documentação de escopo, limites e uso seguro.
- Projeto fonte reorganizado para raiz limpa: `installer`, `src/app`, `src/modules`, `src/config`, `assets` e `docs`.
- Removidos logs e relatórios gerados da pasta do projeto fonte.
- Scripts operacionais manuais movidos para `installer`.
