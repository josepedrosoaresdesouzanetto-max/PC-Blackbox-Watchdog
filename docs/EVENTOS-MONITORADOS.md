# Eventos monitorados

## System

- Kernel-Power 41: desligamento incorreto anterior.
- EventLog 6008: desligamento inesperado.
- EventLog 6005/6006/6009: servico de eventos iniciou/parou/versao do Windows.
- Kernel-General 12/13: inicio/desligamento do sistema.
- BugCheck 1001: tela azul registrada.
- volmgr 161/162: falha ou problema ao gerar dump.
- WHEA-Logger 1/17/18/19/46/47: erros de hardware ou barramento.
- Display 4101: driver de video parou e se recuperou.
- Disk 7/11/51/153: erros de disco ou I/O.
- Ntfs 55: corrupcao/erro de sistema de arquivos.
- storahci/stornvme 129: reset/timeouts de controlador.
- Service Control Manager: falhas de servicos criticas quando aparecem nos filtros do Windows.
- Kernel-Boot e Kernel-Processor-Power: relevantes para boot/CPU/energia quando aparecem perto da falha.

## Application

- Application Error 1000: crash de aplicativo.
- Windows Error Reporting 1001: relatorio de erro/falha.
- Application Hang 1002: aplicativo travado.

## Mensagens de video

Tambem sao procurados padroes como `nvlddmkm`, `amdkmdag`, `amdwddmg`, `igdkmdn64`, `dxgkrnl`, `LiveKernelEvent`, `TDR` e `Display driver stopped responding`.
