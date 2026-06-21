# Como interpretar

## Evidencia, suspeita e hipotese

- Evidencia: algo registrado em log, amostra ou evento.
- Suspeita: interpretacao baseada em padrao conhecido.
- Hipotese: explicacao provavel, mas nao definitiva.

## Confianca

- 80-100%: evidencia forte, como WHEA 18 ou BugCheck com dump.
- 55-79%: evidencia media, como Display 4101, disk errors ou Kernel-Power com contexto.
- abaixo de 55%: dados insuficientes.

## Risco

- baixo: observar.
- medio: investigar e coletar mais dados.
- alto: salvar trabalho, fazer backup e testar componente.
- critico: risco de queda, BSOD ou perda de dados.

## Relatorio parcial vs pos-boot

O parcial e salvo quando o Windows ainda esta vivo e detecta alerta. O pos-boot e gerado depois que o PC liga novamente, cruzando o que havia antes com os eventos novos.
