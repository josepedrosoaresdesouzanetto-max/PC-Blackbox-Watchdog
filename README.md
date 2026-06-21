# PC-Blackbox-Watchdog v1.0

PC-Blackbox-Watchdog e uma caixa-preta local para Windows 10 e Windows 11, criada para um problema bem especifico: investigar PCs com desligamento inesperado, reinicio seco, travamento, tela azul, LiveKernelEvent, WHEA, falha de GPU, falha de disco, superaquecimento ou perda de energia.

Ele e somente diagnostico. Nao altera BIOS, drivers, TPM, Secure Boot, BitLocker, DCOM, servicos criticos, overclock nem reinicia o computador sozinho.

Ele nao e antivirus, otimizador, atualizador de driver nem ferramenta de reparo automatico. A ideia e guardar evidencias antes e depois de uma falha para facilitar o diagnostico.

## O que ha na v1.0

- Agente continuo com heartbeat.
- Relatorio pos-boot.
- Alertas urgentes em arquivo antes de tentar pop-up.
- Olhinho visual animado na bandeja do Windows.
- Dashboard local com status, tarefas e atalhos para relatorios.
- Modo gamer: temperatura alta durante jogo pode ser registrada sem popup/beep.
- Instalador com modo upgrade/reparo, preservando logs e relatorios.
- Icones `.ico` para olhinho, instalador/reparador e desinstalador.
- Estrutura instalada mais organizada.

## Limitacao importante

Nenhum programa consegue garantir aviso antes de um desligamento seco instantaneo causado por fonte, tomada, cabo, placa-mae ou queda eletrica. Se o Windows perde energia de uma vez, pode nao haver tempo de registrar nada.

O sistema salva evidencias em tres camadas:

1. **Logs continuos antes da falha**: amostras JSONL em `C:\PC-Blackbox\logs\samples`, com flush apos escritas importantes.
2. **Relatorio parcial antes da falha**: em alerta alto/critico, salva primeiro `C:\PC-Blackbox\reports\ALERTA-CRITICO-YYYY-MM-DD-HH-mm.txt`; so depois tenta pop-up/beep.
3. **Relatorio completo pos-boot**: ao ligar/logar novamente, o Analyzer cruza logs antes da queda com eventos do Windows apos o boot.

O diagnostico aponta causa provavel com base em evidencias; nao afirma certeza absoluta.

## Como instalar

Abra PowerShell como Administrador na pasta do projeto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

Ou use o instalador automatico:

```text
installer\INSTALAR-PC-BLACKBOX.bat
```

Clique duas vezes nele. Ele vai pedir permissao de Administrador via UAC e chamar o `install.ps1` automaticamente.

O instalador cria ou atualiza `C:\PC-Blackbox`, copia scripts/modulos/docs/assets e cria tarefas agendadas:

- `PC-Blackbox-Agent`: agente continuo.
- `PC-Blackbox-PostBoot-Analyzer`: analise alguns minutos apos logon.
- `PC-Blackbox-Notifier`: notificador no usuario logado para pop-up/beep.

O instalador tambem cria um atalho em Inicializar para o olhinho visual da bandeja do Windows, indicando se o heartbeat esta recente. Em upgrade/reparo, logs, relatorios e estado existente sao preservados.

## Layout instalado

```text
C:\PC-Blackbox
├─ app          scripts principais da v1.0
├─ assets       icones do olho
├─ config       configuracao
├─ docs         documentacao
├─ modules      modulos PowerShell
├─ shortcuts    atalhos com icone
├─ logs         logs e heartbeat em uso
├─ reports      relatorios
├─ data         area reservada para dados estruturados futuros
└─ src          compatibilidade com versoes anteriores
```

## Como desinstalar

```powershell
C:\PC-Blackbox\uninstall.ps1
```

Ele remove tarefas agendadas. Logs so sao apagados se voce digitar explicitamente `APAGAR`.

Tambem existe:

```text
installer\DESINSTALAR-PC-BLACKBOX.bat
```

## Como verificar se esta rodando

Use:

```text
installer\VERIFICAR-SE-ESTA-RODANDO.bat
```

Ele mostra as tarefas agendadas, o heartbeat e os ultimos logs de amostras.

Tambem existe o olhinho visual:

```text
installer\ABRIR-OLHINHO-PC-BLACKBOX.bat
```

O olho fica verde quando o heartbeat esta recente, amarelo quando esta atrasado e vermelho quando esta ausente ou velho demais. Dois cliques no icone abrem o painel.

Para fechar apenas o olhinho visual sem parar o agente:

```text
installer\FECHAR-OLHINHO-PC-BLACKBOX.bat
```

## Modo gamer e temperatura

Por padrao, o PC-Blackbox evita ficar mostrando popup/beep de temperatura enquanto detecta processos comuns de jogos ou launchers. A temperatura ainda e registrada em:

```text
C:\PC-Blackbox\logs\alerts\suppressed-temperature-alerts.jsonl
```

Se a temperatura passar do limite emergencial configurado, o alerta visual aparece mesmo durante jogo. Isso evita incomodo em uso normal de jogo, mas ainda protege contra risco real.

## Diagnostico manual

```powershell
C:\PC-Blackbox\run-once-diagnostic.ps1
```

Gera relatorio dos ultimos 7 dias mesmo sem desligamento recente.

No projeto fonte, os scripts operacionais ficam em `installer\`.

## Onde ficam os arquivos

- Logs continuos: `C:\PC-Blackbox\logs\samples`
- Eventos capturados: `C:\PC-Blackbox\logs\events`
- Alertas JSONL: `C:\PC-Blackbox\logs\alerts\urgent-alerts.jsonl`
- Ultimo alerta urgente: `C:\PC-Blackbox\ALERTA-URGENTE.txt`
- Estado/heartbeat: `C:\PC-Blackbox\logs\state`
- Relatorio parcial: `C:\PC-Blackbox\reports\ALERTA-CRITICO-*.txt`
- Relatorio simples: `C:\PC-Blackbox\reports\RELATORIO-SIMPLES-*.txt`
- Relatorio tecnico: `C:\PC-Blackbox\reports\RELATORIO-TECNICO-*.json`
- Relatorio HTML: `C:\PC-Blackbox\reports\RELATORIO-*.html`

## Como interpretar eventos

- **Kernel-Power 41**: prova que o Windows nao encerrou corretamente. Nao prova sozinho que a fonte esta ruim.
- **EventLog 6008**: confirma desligamento inesperado.
- **WHEA**: pode indicar instabilidade de hardware, CPU, RAM, PCIe, placa-mae ou energia.
- **BugCheck 1001**: indica tela azul registrada; analise profunda exige dump/WinDbg.
- **LiveKernelEvent / Display 4101 / TDR**: possivel GPU, driver de video ou instabilidade sob carga.
- **Disk/Ntfs/stornvme/storahci**: possivel disco, cabo, controladora, driver ou sistema de arquivos.

## Alertas urgentes

Eventos criticos geram escrita imediata em arquivo, relatorio parcial e so depois aviso visual. Se a tarefa estiver como SYSTEM, pop-up pode nao aparecer; por isso existe o Notifier no usuario logado.

## Seguranca

O projeto nao envia dados para internet e nao usa dependencias externas obrigatorias. HWiNFO/LibreHardwareMonitor/BurntToast sao apenas ideias opcionais; o projeto funciona sem eles.

## Publicar no GitHub

O projeto ja e um repositorio Git local. Para criar um repositorio novo no GitHub e fazer push, instale o GitHub CLI, faca login e rode:

```powershell
winget install --id GitHub.cli
gh auth login
.\installer\PUBLICAR-GITHUB.ps1
```

Por padrao o script cria o repositorio como privado. Para publico:

```powershell
.\installer\PUBLICAR-GITHUB.ps1 -Public
```
