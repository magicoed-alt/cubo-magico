# Cubo Mágico — Digital Magic

App de iPhone que guia por voz a resolução do cubo Bluetooth **Giiker i3S** (também i3 / Mi Smart), feito para o palco: a voz sai no Ray-Ban Meta (ou em qualquer fone Bluetooth).

## Rotinas
Uma rotina é uma sequência de etapas, que podem ser combinadas na ordem que você quiser:

- **Resolver**: deixa o cubo resolvido.
- **Igualar ao outro cubo (2 cubos)**: deixa o cubo que você pegou igual ao outro cubo, misturado pela plateia.
- **Padrão**: monta um padrão, que pode ser pronto (xadrez, superflip, cubo no cubo…) ou um seu, gravado direto do cubo (por exemplo, uma previsão).

Exemplo: *Igualar → Resolver*.

## Como cada etapa começa (olhos fechados)
1. A etapa espera ninguém mexer nos cubos por **7 s**, que marca o fim da mistura.
2. O app fala **"cima frente"**: gire a face de cima do cubo que você pegou. Esse giro mostra ao app qual cubo é o seu e qual face está em cima.
3. O app fala **"direita frente"**: gire a face da direita. Se você girar cima ou baixo de novo, ele corrige ("não, direita frente").
4. A partir daí as instruções são por posição: cima, baixo, direita, esquerda, **frente** (face virada para você) e **trás** (face virada para a plateia).
   - **frente** = sentido horário olhando para a face
   - **reverso** = anti-horário
   - **duplo** = duas vezes (180°)
5. Se você errar um giro, ele fala "corrige, …" e recalcula.

Não vire o cubo na mão durante a solução. Se virar, use **Reorientar** (na tela, ou o comando de próxima faixa do óculos): o app pede "cima frente" e "direita frente" de novo.

O toque na haste do óculos (play/pause) **repete** a instrução. Durante a espera, o mesmo toque **pula a espera**.

Antes de cada etapa o app fala o nome dela ("solve the cube", "matching cubes" ou o nome falado que você escrever, ex.: "prediction"). No último giro a fala começa com **"now turn"** ("agora gire") e, no fim, ele diz **"the cube is solved"** ("o cubo está resolvido"). A instrução atual aparece grande no topo da tela do Show, para ler olhando o celular.

## Idioma
Em Ajustes → Idioma: **Português** ou **English** (padrão do CubeSmith: top/bottom/front/back/left/right, forward/reverse/double, com *Invert LEFT / BOTTOM / BACK* ligados). Inverter faz a face falar o sentido como se você olhasse a face oposta: "left forward" gira no mesmo sentido que "right forward".

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
