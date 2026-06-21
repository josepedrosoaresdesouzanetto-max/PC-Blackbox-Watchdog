# Escopo do problema especifico

O PC-Blackbox-Watchdog foi criado para um caso bem especifico: investigar PCs Windows com desligamento inesperado, reinicio seco, travamento, tela azul, LiveKernelEvent, WHEA, falha de GPU, falha de disco, alerta termico ou perda de energia onde o Windows nem sempre consegue explicar a causa.

Ele nao e um antivirus, nao e otimizador de Windows, nao atualiza driver, nao altera BIOS e nao corrige hardware automaticamente.

## O que ele tenta responder

- O PC desligou sem encerrar corretamente?
- Havia sinal de carga alta, RAM alta, disco cheio ou evento critico antes da queda?
- O Windows registrou Kernel-Power 41, EventLog 6008, BugCheck, WHEA, Display/TDR ou LiveKernelEvent?
- Existe relatorio parcial salvo antes de uma falha?
- O agente de monitoramento estava vivo antes do problema?

## O que ele nao consegue provar sozinho

- Que a fonte esta ruim.
- Que a placa-mae esta ruim.
- Que a GPU esta fisicamente defeituosa.
- Que o driver e definitivamente a causa.
- Que nao existe problema eletrico externo.

Kernel-Power 41, por exemplo, prova desligamento inesperado, mas nao aponta a causa sozinho.

## Regra de seguranca

A ferramenta e defensiva e local. Ela grava evidencias para diagnostico, mas nao muda BIOS, TPM, Secure Boot, BitLocker, overclock, drivers, DCOM ou politicas criticas do Windows.

