# Escopo do problema específico

O PC-Blackbox-Watchdog foi criado para um caso bem específico: investigar PCs Windows com desligamento inesperado, reinício seco, travamento, tela azul, LiveKernelEvent, WHEA, falha de GPU, falha de disco, alerta térmico ou perda de energia onde o Windows nem sempre consegue explicar a causa.

Ele não é um antivírus, não é otimizador de Windows, não atualiza driver, não altera BIOS e não corrige hardware automaticamente.

## O que ele tenta responder

- O PC desligou sem encerrar corretamente?
- Havia sinal de carga alta, RAM alta, disco cheio ou evento crítico antes da queda?
- O Windows registrou Kernel-Power 41, EventLog 6008, BugCheck, WHEA, Display/TDR ou LiveKernelEvent?
- Existe relatório parcial salvo antes de uma falha?
- O agente de monitoramento estava vivo antes do problema?

## O que ele não consegue provar sozinho

- Que a fonte está ruim.
- Que a placa-mãe está ruim.
- Que a GPU está fisicamente defeituosa.
- Que o driver é definitivamente a causa.
- Que não existe problema elétrico externo.

Kernel-Power 41, por exemplo, prova desligamento inesperado, mas não aponta a causa sozinho.

## Regra de segurança

A ferramenta é defensiva e local. Ela grava evidências para diagnóstico, mas não muda BIOS, TPM, Secure Boot, BitLocker, overclock, drivers, DCOM ou políticas críticas do Windows.
