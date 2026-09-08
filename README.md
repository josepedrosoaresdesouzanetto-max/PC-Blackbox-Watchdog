# PC Blackbox Watchdog

Ferramenta local para coletar, organizar e correlacionar evidências de desligamentos inesperados, travamentos, telas azuis e sinais de instabilidade no Windows.

- **Versão atual:** 1.0.2
- **Plataforma:** Windows 10 e Windows 11
- **Tecnologia:** Windows PowerShell

## Visão geral

Falhas abruptas costumam deixar evidências distribuídas entre logs do Windows, registros de confiabilidade, dumps e amostras do sistema. O PC Blackbox Watchdog reúne esses sinais antes e depois de uma ocorrência e gera relatórios locais para apoiar a investigação.

O projeto é somente diagnóstico: não altera BIOS, drivers, TPM, Secure Boot, BitLocker, DCOM, serviços críticos ou overclock. Também não reinicia o computador e não envia dados pela internet.

## Problema

Um evento como `Kernel-Power 41` confirma que o Windows não foi encerrado corretamente, mas não identifica a causa sozinho. Para avaliar hipóteses de energia, hardware, driver, temperatura ou sistema, é necessário observar sinais próximos no tempo e preservar o contexto anterior à falha.

O projeto procura responder:

- quais eventos críticos ocorreram perto da falha;
- quais eram os últimos sinais coletados antes do desligamento;
- se existem registros WHEA, BugCheck, LiveKernelEvent, Display, disco ou NTFS;
- se há metadados de dump ou registros de confiabilidade relacionados;
- quais hipóteses são compatíveis com as evidências disponíveis.

## Fontes e sinais analisados

- Windows Event Log, incluindo Kernel-Power, EventLog, WHEA, BugCheck, Display, Disk e NTFS;
- registros `Win32_ReliabilityRecords`;
- uso de CPU, memória, disco e espaço livre via CIM/WMI;
- temperatura quando o Windows disponibiliza o sensor;
- metadados de minidumps;
- heartbeat, alertas e amostras JSONL produzidos pelo próprio agente.

## O que a ferramenta entrega

- agente contínuo com heartbeat e amostragem configurável;
- coleta de eventos com fallback por consulta periódica;
- escrita imediata de alertas e relatórios parciais antes da notificação;
- correlação pós-boot entre eventos, amostras, dumps e confiabilidade;
- classificação de severidade e hipótese acompanhada de evidências;
- relatórios em texto, JSON e HTML;
- painel local e ícone de status na bandeja do Windows;
- modo gamer para registrar alertas de temperatura sem pop-ups durante jogos, respeitando limites emergenciais.

## Arquitetura

```text
coleta contínua
    |
    +-- amostras e heartbeat em JSON/JSONL
    +-- eventos monitorados
    +-- alertas e relatório parcial
    |
reinício ou execução manual
    |
    +-- correlação com Event Log, Reliability Records e dumps
    +-- classificação de evidências
    `-- relatórios TXT, JSON e HTML
```

Os scripts em `src/app/` coordenam a execução. Os módulos em `src/modules/` separam coleta, eventos, energia, hardware, estado, alertas e relatórios. Os limites e intervalos ficam centralizados em `src/config/config.json`.

## Metodologia de diagnóstico

1. Coleta amostras do sistema e mantém um heartbeat local.
2. Monitora eventos relevantes e classifica sua severidade.
3. Em alerta alto ou crítico, salva os dados antes de tentar exibir a notificação.
4. Após o próximo logon, cruza o contexto anterior com os eventos registrados pelo Windows.
5. Gera uma hipótese acompanhada das evidências encontradas e das limitações da leitura.

A regra central é separar **evidência**, **suspeita** e **hipótese**. Consulte [Como interpretar](docs/COMO-INTERPRETAR.md) para entender essa distinção.

## Como instalar

Pré-requisitos:

- Windows 10 ou Windows 11;
- Windows PowerShell;
- conta com permissão de Administrador para criar as tarefas agendadas.

Clone o repositório e abra o PowerShell como Administrador na pasta do projeto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

Também é possível executar:

```text
installer\INSTALAR-PC-BLACKBOX.bat
```

O instalador cria ou atualiza `C:\PC-Blackbox`, preserva logs e relatórios em upgrades e configura três tarefas:

- `PC-Blackbox-Agent`;
- `PC-Blackbox-PostBoot-Analyzer`;
- `PC-Blackbox-Notifier`.

## Como verificar e executar manualmente

Verificar tarefas, heartbeat e amostras recentes:

```text
installer\VERIFICAR-SE-ESTA-RODANDO.bat
```

Gerar um diagnóstico dos últimos sete dias:

```powershell
C:\PC-Blackbox\run-once-diagnostic.ps1
```

Abrir o indicador visual:

```text
installer\ABRIR-OLHINHO-PC-BLACKBOX.bat
```

O guia operacional completo está em [Como usar](docs/COMO-USAR.md).

## Saídas geradas

| Saída | Local padrão |
| --- | --- |
| Amostras contínuas | `C:\PC-Blackbox\logs\samples` |
| Eventos capturados | `C:\PC-Blackbox\logs\events` |
| Alertas em JSONL | `C:\PC-Blackbox\logs\alerts` |
| Estado e heartbeat | `C:\PC-Blackbox\logs\state` |
| Relatórios parciais e pós-boot | `C:\PC-Blackbox\reports` |

Os relatórios incluem uma versão simples em texto, uma saída técnica em JSON e uma visualização local em HTML.

## Estrutura do repositório

```text
PC-Blackbox-Watchdog/
|-- assets/              ícones da aplicação
|-- docs/                uso, escopo, eventos e limitações
|-- installer/           atalhos operacionais e desinstalador
|-- src/
|   |-- app/             agente, analisador, notificador e painel
|   |-- config/          parâmetros de coleta e alerta
|   `-- modules/         coleta, correlação, estado e relatórios
|-- install.ps1
|-- CHANGELOG.md
|-- LICENSE
|-- README.md
`-- VERSION
```

## Limitações

- Um desligamento seco instantâneo pode interromper o sistema antes de qualquer nova gravação.
- `Kernel-Power 41` e `EventLog 6008` confirmam encerramento incorreto, mas não apontam a causa isoladamente.
- Sensores de temperatura podem não estar disponíveis por CIM/WMI em determinados equipamentos.
- A inspeção de dumps é limitada a metadados; análise profunda exige WinDbg.
- As pontuações internas de confiança são heurísticas e não representam probabilidade estatística validada.
- A ferramenta não substitui diagnóstico técnico de hardware nem executa reparos.

Leia [Limitações reais](docs/LIMITACOES.md) e [Escopo do problema](docs/ESCOPO-PROBLEMA-ESPECIFICO.md) antes de interpretar um relatório.

## Desinstalação

```powershell
C:\PC-Blackbox\uninstall.ps1
```

O desinstalador remove as tarefas agendadas. Logs e relatórios só são apagados quando o usuário confirma explicitamente essa opção.

## Documentação

- [Como usar](docs/COMO-USAR.md)
- [Como interpretar](docs/COMO-INTERPRETAR.md)
- [Eventos monitorados](docs/EVENTOS-MONITORADOS.md)
- [Escopo do problema](docs/ESCOPO-PROBLEMA-ESPECIFICO.md)
- [Limitações reais](docs/LIMITACOES.md)
- [Histórico de versões](CHANGELOG.md)
