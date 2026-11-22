# sword

Os programas da Minezada escritos em [Sword](https://swordlang.com). As Actions compilam e rodam sozinhas; para
mexer, é preciso o compilador (`shield`) e o `clang`:

```sh
git clone https://github.com/swordlang/sword ~/sword && make -C ~/sword
cd sword && mkdir -p bin
for p in mc hist; do ~/sword/shield test $p; done
for p in status historico; do ~/sword/shield $p -o bin/$p; done
```

| Programa | O que faz | Quem roda |
|---|---|---|
| `status <endereço> [porta] [--json] [--selo arquivo.svg]` | a consulta da lista de Multijogador: ligado, jogadores, versão, ping | Action **Status do servidor**, a cada 10 min |
| `historico <historico.txt> <saída.json> [dias]` | horas ligado e pico de jogadores por dia (horário de Brasília) | a mesma Action, depois da consulta |

`status` sai com 0 quando o servidor respondeu, 1 quando não respondeu e 2 para comando errado. O endereço do playit
usa registro SRV, então precisa da porta escrita.

| Pasta | O que tem |
|---|---|
| `mc/` | protocolo de status: handshake, pedido, JSON da resposta, ping |
| `hist/` | calendário e soma do histórico por dia |
