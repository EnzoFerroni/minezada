# sword

Os programas da Minezada escritos em [Sword](https://swordlang.com). As Actions compilam e rodam sozinhas; para
mexer, é preciso o compilador (`shield`), o `clang` e a libz (já vem no Mac; no Linux, `zlib1g-dev`):

```sh
git clone https://github.com/swordlang/sword ~/sword && make -C ~/sword
cd sword && mkdir -p bin
for p in mc estat hist mundo nbt png zlib poi; do ~/sword/shield test $p; done
for p in status historico mapa placar estado pontos calor mortes conquistas estruturas; do ~/sword/shield $p -o bin/$p; done
testdata/conferir.sh
```

| Programa | O que faz | Quem roda |
|---|---|---|
| `status <endereço> [porta] [--json] [--selo arquivo.svg]` | a consulta da lista de Multijogador: ligado, jogadores, versão, ping | Action **Status do servidor**, a cada 10 min |
| `historico <historico.txt> <saída.json> [dias]` | horas ligado e pico de jogadores por dia (horário de Brasília) | a mesma Action, depois da consulta |
| `mapa <pasta da dimensão> <saída.png> [saída.json] [--teto Y]` | o mundo visto de cima, um pixel por bloco, com relevo; o JSON diz a coordenada do canto. `world`, `world/DIM-1` (Nether, com `--teto 118`) ou `world/DIM1` (End) | Action da página |
| `placar <pasta do servidor> <saída.json> [--posicoes]` | as estatísticas de cada jogador (`world/stats`), com o nick tirado da whitelist, e como saiu do jogo (`world/playerdata`: vida, fome, nível, dimensão; a posição só com `--posicoes`) | Action da página |
| `estado <pasta do mundo> <saída.json>` | dia do mundo, hora do jogo, fase da lua, chuva, spawn e se o dragão caiu (`level.dat`) | Action da página |
| `calor <pasta da dimensão> <saída.json>` | quanto tempo cada chunk teve gente por perto (o `InhabitedTime` do jogo), os de pelo menos um minuto | Action da página, só com `MOSTRAR_POSICOES` |
| `conquistas <pasta do servidor> <saída.json>` | quem fez cada conquista e quando, sem as receitas, as técnicas dos mods e a raiz de cada aba; o nome de cada uma em português fica na página | Action da página |
| `estruturas <pasta da dimensão> <saída.json>` | as estruturas (templos, bastiões, navios, masmorras, as dos mods) que começam nos chunks já explorados; quais aparecem no mapa, com nome e ícone, a página decide | Action da página |
| `mortes <pasta do mundo> <saída.json>` | onde e quando cada um morreu, dos arquivos que o mod Corpse grava em `deaths/` (a causa ele não guarda) | Action da página, só com `MOSTRAR_POSICOES` |
| `pontos <pasta da dimensão> <saída.json> [--portais]` | as vilas (pelo sino) e, com `--portais`, os portais do Nether acesos, do arquivo de pontos de interesse (`poi/`); camas ficam de fora | Action da página |

`status` sai com 0 quando o servidor respondeu, 1 quando não respondeu e 2 para comando errado. O endereço do playit
usa registro SRV, então precisa da porta escrita.

O `mapa` desenha cada região (`r.X.Z.mca`) ao mesmo tempo, uma por núcleo, e a imagem sai igual byte a byte com
qualquer número de núcleos. Só entram chunks completos; os da borda, que o jogo gerou pela metade, ficam de fora.
Blocos de mod ganham cor pelo nome (`leaves`, `log`, `stone`...), e o que não dá para adivinhar fica cinza. Grama,
folhas e água têm a cor do bioma em que estão, como no jogo; os biomas de mod entram pelo nome (`snowy`, `swamp`,
`desert`...). No Nether o bloco de cima é o teto de bedrock: com `--teto` cada coluna é lida dali para baixo, passa
pela pedra até o primeiro ar e desenha o chão abaixo dele.

| Pasta | O que tem |
|---|---|
| `mc/` | protocolo de status: handshake, pedido, JSON da resposta, ping |
| `zlib/` | a libz: descomprime os chunks e o `level.dat`, comprime o PNG |
| `nbt/` | leitor do NBT, o formato binário do mundo |
| `mundo/` | desenha uma região; `cores.sword` tem a cor de cada bloco; `leitor.sword` abre os chunks de uma região, `calor.sword` lê o tempo de gente por perto de cada chunk e `estruturas.sword` onde cada estrutura começa |
| `png/` | grava a imagem |
| `estat/` | resume o arquivo de estatísticas de um jogador e acha o nick de cada UUID na whitelist |
| `hist/` | calendário e soma do histórico por dia; lê a hora com fuso das conquistas |
| `poi/` | lê os pontos de interesse (sinos, portais) e junta os blocos de um portal num ponto só |
| `testdata/` | um servidor de mentira (um jogador, no Nether) e o que `estado`, `placar`, `pontos`, `calor`, `mortes`, `conquistas` e `estruturas` têm que tirar dele; `conferir.sh` compara |
