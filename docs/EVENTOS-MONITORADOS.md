# Eventos monitorados

## System

- Kernel-Power 41: desligamento incorreto anterior.
- EventLog 6008: desligamento inesperado.
- EventLog 6005/6006/6009: serviço de eventos iniciou/parou/versão do Windows.
- Kernel-General 12/13: inicio/desligamento do sistema.
- BugCheck 1001: tela azul registrada.
- volmgr 161/162: falha ou problema ao gerar dump.
- WHEA-Logger 1/17/18/19/46/47: erros de hardware ou barramento.
- Display 4101: driver de vídeo parou e se recuperou.
- Disk 7/11/51/153: erros de disco ou I/O.
- Ntfs 55: corrupção/erro de sistema de arquivos.
- storahci/stornvme 129: reset/timeouts de controlador.
- Service Control Manager: falhas de serviços críticas quando aparecem nos filtros do Windows.
- Kernel-Boot e Kernel-Processor-Power: relevantes para boot/CPU/energia quando aparecem perto da falha.

## Application

- Application Error 1000: crash de aplicativo.
- Windows Error Reporting 1001: relatório de erro/falha.
- Application Hang 1002: aplicativo travado.

## Mensagens de vídeo

Também são procurados padrões como `nvlddmkm`, `amdkmdag`, `amdwddmg`, `igdkmdn64`, `dxgkrnl`, `LiveKernelEvent`, `TDR` e `Display driver stopped responding`.
