# Cubo Mágico — Digital Magic

App de iPhone que guia por voz a resolução do cubo Bluetooth **Giiker i3S** (também i3 / Mi Smart), feito para o palco: a voz sai no Ray-Ban Meta (ou em qualquer fone Bluetooth).

## Rotinas
Uma rotina é uma sequência de etapas, que podem ser combinadas na ordem que você quiser:

- **Resolver**: deixa o cubo resolvido.
- **Igualar ao outro cubo (2 cubos)**: deixa o cubo que você pegou igual ao outro cubo, misturado pela plateia.
- **Padrão**: monta um padrão, que pode ser pronto (xadrez, superflip, cubo no cubo…) ou um seu, gravado direto do cubo (por exemplo, uma previsão).

Exemplo: *Igualar → Resolver*.

## Como cada etapa começa
1. A etapa espera ninguém mexer nos cubos por **X segundos**. O padrão é 5 s; isso marca o fim da mistura.
2. Depois disso, o **primeiro giro que você der** escolhe o cubo, e o app começa a falar.
3. Se você errar um giro, ele recalcula na hora.

Um toque na haste do óculos (play/pause) **repete** a instrução. Durante a espera, o mesmo toque **pula a espera**.

## Instalar
A cada envio para a branch `main`, o GitHub Actions faz três coisas:
1. Testa o motor.
2. Compila o app.
3. Publica o `CuboMagico.ipa` na Release **ultima-versao**.

O resultado da compilação fica na branch `log`.

## Arquivos
- `CuboMagico/engine.txt`: motor das rotinas (JavaScript, roda no JavaScriptCore).
- `CuboMagico/cube.txt`: matemática do cubo e leitura do Giiker.
- `CuboMagico/min2phase.txt`: solver Kociemba de 2 fases (do cstimer, licença GPLv3).
- `testes/`: testes do motor com cubos simulados (`node t_engine.js`).
