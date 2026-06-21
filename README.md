# PC-Blackbox-Watchdog v1.0

PC-Blackbox-Watchdog é uma caixa-preta local para Windows 10 e Windows 11, criada para um problema bem específico: investigar PCs com desligamento inesperado, reinício seco, travamento, tela azul, LiveKernelEvent, WHEA, falha de GPU, falha de disco, superaquecimento ou perda de energia.

Ele é somente diagnóstico. Não altera BIOS, drivers, TPM, Secure Boot, BitLocker, DCOM, serviços críticos, overclock nem reinicia o computador sozinho.

Ele não é antivírus, otimizador, atualizador de driver nem ferramenta de reparo automático. A ideia é guardar evidências antes e depois de uma falha para facilitar o diagnóstico.

## O que há na v1.0

- Agente contínuo com heartbeat.
- Relatório pós-boot.
- Alertas urgentes em arquivo antes de tentar pop-up.
- Olhinho visual animado na bandeja do Windows.
- Dashboard local com status, tarefas e atalhos para relatórios.
- Modo gamer: temperatura alta durante jogo pode ser registrada sem popup/beep.
- Instalador com modo upgrade/reparo, preservando logs e relatórios.
- Ícones `.ico` para olhinho, instalador/reparador e desinstalador.
- Estrutura instalada mais organizada.

## Limitação Importante

Nenhum programa consegue garantir aviso antes de um desligamento seco instantâneo causado por fonte, tomada, cabo, placa-mãe ou queda elétrica. Se o Windows perde energia de uma vez, pode não haver tempo de registrar nada.

O sistema salva evidências em três camadas:

1. **Logs contínuos antes da falha**: amostras JSONL em `C:\PC-Blackbox\logs\samples`, com flush após escritas importantes.
2. **Relatório parcial antes da falha**: em alerta alto/crítico, salva primeiro `C:\PC-Blackbox\reports\ALERTA-CRITICO-YYYY-MM-DD-HH-mm.txt`; só depois tenta pop-up/beep.
3. **Relatório completo pós-boot**: ao ligar/logar novamente, o Analyzer cruza logs antes da queda com eventos do Windows após o boot.

O diagnóstico aponta causa provável com base em evidências; não afirma certeza absoluta.

## Como instalar

Abra PowerShell como Administrador na pasta do projeto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

Ou use o instalador automático:

```text
installer\INSTALAR-PC-BLACKBOX.bat
```

Clique duas vezes nele. Ele vai pedir permissão de Administrador via UAC e chamar o `install.ps1` automaticamente.

O instalador cria ou atualiza `C:\PC-Blackbox`, copia scripts/módulos/docs/assets e cria tarefas agendadas:

- `PC-Blackbox-Agent`: agente contínuo.
- `PC-Blackbox-PostBoot-Analyzer`: análise alguns minutos após logon.
- `PC-Blackbox-Notifier`: notificador no usuário logado para pop-up/beep.

O instalador também cria um atalho em Inicializar para o olhinho visual da bandeja do Windows, indicando se o heartbeat está recente. Em upgrade/reparo, logs, relatórios e estado existente são preservados.

## Layout instalado

```text
C:\PC-Blackbox
|- app          scripts principais da v1.0
|- assets       ícones do olho
|- config       configuração
|- docs         documentação
|- modules      módulos PowerShell
|- shortcuts    atalhos com ícone
|- logs         logs e heartbeat em uso
|- reports      relatórios
|- data         área reservada para dados estruturados futuros
`- src          compatibilidade com versões anteriores
```

## Como desinstalar

```powershell
C:\PC-Blackbox\uninstall.ps1
```

Ele remove tarefas agendadas. Logs só são apagados se você digitar explicitamente `APAGAR`.

Também existe:

```text
installer\DESINSTALAR-PC-BLACKBOX.bat
```

## Como verificar se está rodando

Use:

```text
installer\VERIFICAR-SE-ESTA-RODANDO.bat
```

Ele mostra as tarefas agendadas, o heartbeat e os últimos logs de amostras.

Também existe o olhinho visual:

```text
installer\ABRIR-OLHINHO-PC-BLACKBOX.bat
```

O olho fica verde quando o heartbeat está recente, amarelo quando está atrasado e vermelho quando está ausente ou velho demais. Dois cliques no ícone abrem o painel.

Para fechar apenas o olhinho visual sem parar o agente:

```text
installer\FECHAR-OLHINHO-PC-BLACKBOX.bat
```

## Modo gamer e temperatura

Por padrão, o PC-Blackbox evita ficar mostrando popup/beep de temperatura enquanto detecta processos comuns de jogos ou launchers. A temperatura ainda é registrada em:

```text
C:\PC-Blackbox\logs\alerts\suppressed-temperature-alerts.jsonl
```

Se a temperatura passar do limite emergencial configurado, o alerta visual aparece mesmo durante jogo. Isso evita incômodo em uso normal de jogo, mas ainda protege contra risco real.

## Diagnóstico manual

```powershell
C:\PC-Blackbox\run-once-diagnostic.ps1
```

Gera relatório dos últimos 7 dias mesmo sem desligamento recente.

No projeto fonte, os scripts operacionais ficam em `installer\`.

## Onde ficam os arquivos

- Logs contínuos: `C:\PC-Blackbox\logs\samples`
- Eventos capturados: `C:\PC-Blackbox\logs\events`
- Alertas JSONL: `C:\PC-Blackbox\logs\alerts\urgent-alerts.jsonl`
- Último alerta urgente: `C:\PC-Blackbox\ALERTA-URGENTE.txt`
- Estado/heartbeat: `C:\PC-Blackbox\logs\state`
- Relatório parcial: `C:\PC-Blackbox\reports\ALERTA-CRITICO-*.txt`
- Relatório simples: `C:\PC-Blackbox\reports\RELATORIO-SIMPLES-*.txt`
- Relatório técnico: `C:\PC-Blackbox\reports\RELATORIO-TECNICO-*.json`
- Relatório HTML: `C:\PC-Blackbox\reports\RELATORIO-*.html`

## Como interpretar eventos

- **Kernel-Power 41**: prova que o Windows não encerrou corretamente. Não prova sozinho que a fonte está ruim.
- **EventLog 6008**: confirma desligamento inesperado.
- **WHEA**: pode indicar instabilidade de hardware, CPU, RAM, PCIe, placa-mãe ou energia.
- **BugCheck 1001**: indica tela azul registrada; análise profunda exige dump/WinDbg.
- **LiveKernelEvent / Display 4101 / TDR**: possível GPU, driver de vídeo ou instabilidade sob carga.
- **Disk/Ntfs/stornvme/storahci**: possível disco, cabo, controladora, driver ou sistema de arquivos.

## Alertas urgentes

Eventos críticos geram escrita imediata em arquivo, relatório parcial e só depois aviso visual. Se a tarefa estiver como SYSTEM, pop-up pode não aparecer; por isso existe o Notifier no usuário logado.

## Segurança

O projeto não envia dados para a internet e não usa dependências externas obrigatórias. HWiNFO/LibreHardwareMonitor/BurntToast são apenas ideias opcionais; o projeto funciona sem eles.

## Publicar no GitHub

O projeto já é um repositório Git local. Para criar um repositório novo no GitHub e fazer push, instale o GitHub CLI, faça login e rode:

```powershell
winget install --id GitHub.cli
gh auth login
.\installer\PUBLICAR-GITHUB.ps1
```

Por padrão o script cria o repositório como privado. Para público:

```powershell
.\installer\PUBLICAR-GITHUB.ps1 -Public
```
