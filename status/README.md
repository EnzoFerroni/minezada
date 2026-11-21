# status

Pergunta a um servidor de Minecraft o que a lista de Multijogador mostraria: se está ligado, quantos jogadores,
versão, descrição e ping. É a mesma consulta que o jogo faz antes do login, sem entrar no servidor. A Action
**Status do servidor** roda ele a cada 10 minutos e publica o selo do README.

Escrito em [Sword](https://swordlang.com). Para compilar é preciso o compilador (`shield`) e o `clang`:

```sh
git clone https://github.com/swordlang/sword ~/sword && make -C ~/sword
cd status
~/sword/shield test mc        # testes, com um servidor falso na própria máquina
~/sword/shield . -o status
./status mc.hypixel.net
./status 127.0.0.1 --json --selo status.svg
```

Sai com 0 quando o servidor respondeu, 1 quando não respondeu e 2 para comando errado. `--json` escreve um objeto
só e `--selo` grava a imagem do selo:

```json
{"online":true,"jogadores":2,"max":10,"versao":"1.21.1","motd":"Minezada","ping_ms":31,"nomes":["Enzobullet"]}
```

A porta padrão é a 25565. Endereço com registro SRV (o do playit) precisa da porta escrita: o jogo descobre
sozinho, este programa ainda não.

| Arquivo | O que tem |
|---|---|
| `mc/mc.sword` | o protocolo: handshake, pedido de status, leitura do JSON, ping |
| `mc/mc_test.sword` | testes, incluindo a conversa inteira com um servidor falso |
| `main.sword` | o programa: argumentos, saída em texto ou JSON, o selo |
