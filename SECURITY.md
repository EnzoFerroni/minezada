# Segurança

Os comandos de jogar e hospedar baixam e rodam scripts deste repositório no computador de quem usa.
Por isso, falha de segurança aqui é tratada com prioridade.

## Como avisar

Não abra issue pública. Use **Security > Report a vulnerability** neste repositório
(relato privado do GitHub). Só o dono vê o relato.

Ajuda contar: o arquivo ou comando, o que um atacante consegue fazer e como reproduzir.

## O que vale

- Scripts (`jogar`, `hospedar`, `iniciar`, `minezada`, `desinstalar`, `logs`) e workflows do GitHub Actions.
- Download sem conferência de hash, segredo exposto no repositório ou nos logs do CI.

Mods de terceiros ficam de fora: avise o autor do mod.

## Resposta

Primeira resposta em até 7 dias. Corrigido o problema, o relato vira um aviso público em Security Advisories.
