# Trailer cinematográfico — Art of Conquest

Vídeo separado da apresentação jogada, com cerca de **1 minuto**. Mostra quem é o personagem, em que mundo ele vive e o que dá início à jornada.

**Versão pronta:** o trailer foi montado na própria Godot com os assets do jogo e gravado com o Movie Maker (1920x1080, 63 s). Cena, sons e instruções para gravar de novo estão em [`trailer/`](../trailer/README.md). Os prompts abaixo servem para gerar, no Google Flow, versões mais cinematográficas das mesmas cenas e trocá-las na montagem (CapCut ou DaVinci Resolve).

## 1. A história em uma frase

> Na noite em que a trégua acaba, o Agente Infiltrado — o soldado mais fraco do exército Azul — descobre que os blindados do inimigo são lonas escondendo tropas e se oferece para atravessar a terra de ninguém e revelar quem está do outro lado.

- **Protagonista:** o Agente Infiltrado (nível 1). Não vence ninguém, mas sua coragem revela o inimigo, exatamente como no jogo.
- **Mundo:** um campo de trincheiras ao anoitecer, entre duas nações fictícias, Azul e Vermelha.
- **Acontecimento que muda tudo:** uma lona levanta com o vento e mostra uma bota, não um tanque.
- **Primeira decisão:** ele dá o primeiro passo para fora da trincheira.
- **Ligação com o jogo:** peças escondidas sob tanques, revelação no combate, batimento cardíaco e tiro (os mesmos sons do jogo), bandeiras e grade do tabuleiro.

## 2. Imagens de referência (anexar no Flow)

Todas estão em `assets/images/`:

| Arquivo | Uso |
|---|---|
| `1.Agente Infiltrado.png` | Referência do protagonista em **todas** as cenas em que ele aparece |
| `Default.png` | O "blindado" que esconde as peças vermelhas (cenas 3 e 5) |
| `tabuleiro_completo.png` | Campo de trincheiras visto de cima (cenas 1 e 6) |
| `bandeira_azul.png` / `bandeira_vermelha.png` | Bandeiras das duas nações (peça ao Flow para não gerar texto nelas) |
| `capa_art_of_conquest.png` | Iluminação, paleta e clima da cena final |
| `4.Atirador de Elite.png` | Personagem secundário (comandante) na cena 4 |

## 3. Storyboard — 6 cenas de 10 segundos

Selecione **10 segundos** quando o modelo permitir. Se o clipe sair com 8 segundos, use os 2 restantes na edição para segurar o plano ou inserir o texto.

| Tempo | Cena | Quadro final (abre a próxima cena) | Texto na edição |
|---|---|---|---|
| 00:00–00:10 | 1. A trégua acaba | O agente encostado na parede da trincheira, à esquerda, olhando para a direita | "A trégua durou até o anoitecer." |
| 00:10–00:20 | 2. O mais fraco do pelotão | O agente espia por cima do parapeito, voltado para a direita | — |
| 00:20–00:30 | 3. As lonas | Close na lona levantada: uma bota aparece embaixo do "tanque" | "Do outro lado, ninguém sabe quem espera sob as lonas." |
| 00:30–00:40 | 4. A decisão | O agente com um pé no degrau da trincheira, pronto para sair | "Alguém precisa descobrir." |
| 00:40–00:50 | 5. A travessia | O agente agachado ao lado de uma lona; ele a puxa e um soldado vermelho é revelado | — |
| 00:50–01:00 | 6. Art of Conquest | Plano aberto do campo com as duas bandeiras e a grade do tabuleiro surgindo | Título **ART OF CONQUEST** + "Cada peça revelada muda as chances." |

## 4. Prompt-base (colar antes de cada cena)

```text
Crie um plano cinematográfico horizontal, 16:9, em pixel art moderna de alta definição no estilo de jogos táticos 16-bits, com contornos escuros bem definidos e muitos detalhes. A história acontece em um campo de batalha fictício de trincheiras ao anoitecer: terra lamacenta, sacos de areia, arame farpado, crateras, fumaça de artilharia e focos de incêndio no horizonte. Use tons de verde-oliva, marrom-lama e azul-marinho escuro, com luz fria azul-ciano de um lado do campo e luz quente vermelho-alaranjada do outro. Separe primeiro plano e fundo em camadas com movimento de paralaxe.

Quando o protagonista aparecer, preserve a aparência da referência: soldado com balaclava verde-escura cobrindo todo o rosto, capacete e óculos táticos, uniforme de camuflagem digital verde, colete tático, mochila grande nas costas e uma pequena faixa azul no braço esquerdo. Ele não carrega arma nas mãos. Mantenha as proporções e as cores em todas as cenas e o sentido geral do movimento da esquerda para a direita.

Conte a história pelos gestos e reações. Sem narração, diálogos ou texto gerado na imagem; bandeiras sem letras, sem emblemas reais ou símbolos políticos. Sem sangue ou violência gráfica. Clima de tensão silenciosa, movimentos lentos e iluminação baixa. Se houver geração de áudio, priorize os efeitos descritos na cena; a trilha e os textos em português serão adicionados na edição.
```

## 5. Prompts por cena

### Cena 1 — A trégua acaba · 00:00–00:10

**Objetivo:** apresentar o mundo e o conflito.

```text
Abra com um plano aéreo lento sobre o campo de trincheiras ao entardecer, inspirado na imagem de referência do tabuleiro. À esquerda, uma bandeira azul rasgada tremula sobre a linha de trincheiras; ao longe, à direita, uma bandeira vermelha. A fumaça cruza o campo e o sol some atrás das nuvens. A câmera desce até dentro da trincheira azul. Ouça vento, uma explosão distante e abafada, e depois silêncio. Nos segundos finais, o protagonista aparece encostado na parede de sacos de areia, à esquerda, e vira a cabeça para a direita. Termine nesse enquadramento.
```

### Cena 2 — O mais fraco do pelotão · 00:10–00:20

**Objetivo:** apresentar o protagonista pela forma como age.

```text
Comece com o protagonista encostado na trincheira, à esquerda, olhando para a direita. Ao fundo, soldados maiores e mais armados verificam rifles e lançadores sem olhar para ele. Ele ajusta as alças da mochila, aperta a faixa azul no braço, respira fundo e sobe dois degraus para espiar por cima do parapeito. Ouça passos na lama, o tilintar de equipamento e um sinalizador sendo disparado ao longe. Termine com o protagonista espiando por cima dos sacos de areia, voltado para a direita, com a luz do sinalizador iluminando os óculos.
```

### Cena 3 — As lonas · 00:20–00:30

**Objetivo:** mostrar o acontecimento que muda tudo.

```text
Comece pelo ponto de vista do protagonista, olhando sobre o parapeito para a terra de ninguém. Do outro lado, uma fileira de blindados camuflados, parecidos com a referência do tanque, está parada sob a luz vermelha das trincheiras inimigas. Um vento forte levanta a ponta da lona de um deles e, por um instante, aparece uma bota de soldado no chão, onde deveriam estar as esteiras. A lona cai de novo. Corte para o rosto coberto do protagonista, que recua alguns centímetros. Ouça o vento e o tecido batendo, seguido de um silêncio tenso. Termine em close na lona, de novo imóvel.
```

### Cena 4 — A decisão · 00:30–00:40

**Objetivo:** mostrar o personagem escolhendo agir.

```text
Comece dentro da trincheira azul, à noite. Um comandante ajoelhado, com rifle de precisão, como na referência do atirador de elite, aponta para um mapa riscado em quadrados sobre uma caixa de munição; no mapa há um alfinete vermelho sobre a bandeira inimiga. Os soldados em volta desviam o olhar. O protagonista dá um passo à frente e levanta a mão. O comandante o observa por um momento e assente. Ouça um batimento cardíaco grave começando, lento. Termine com o protagonista apoiando um pé no degrau da trincheira, pronto para sair, voltado para a direita.
```

### Cena 5 — A travessia · 00:40–00:50

**Objetivo:** mostrar o primeiro risco da jornada e a revelação.

```text
Comece com o protagonista saindo da trincheira e rastejando pela terra de ninguém, da esquerda para a direita. O chão tem marcas sutis de uma grade quadriculada, como um tabuleiro, e ele avança casa a casa. Um sinalizador ilumina o campo e ele congela, colado ao chão. O batimento cardíaco acelera. Ele chega agachado ao lado de uma das lonas, segura a borda e puxa. Sob ela não há tanque: há um soldado inimigo com braçadeira vermelha, que se vira surpreso. Ouça o som metálico de uma arma sendo engatilhada. Termine com os dois frente a frente, iluminados pela luz do sinalizador.
```

### Cena 6 — Art of Conquest · 00:50–01:00

**Objetivo:** encerrar com o título e a promessa do jogo.

```text
Corte para um plano aéreo que se afasta rapidamente do ponto da revelação. Em várias posições do campo, outras lonas tremulam, todas iguais, escondendo o que está embaixo. Uma grade de tabuleiro 8 por 8, em linhas finas azul-ciano, surge suavemente sobre o terreno; a bandeira azul fica na borda de baixo e a vermelha na borda de cima. A fumaça se abre e a luz quente do horizonte ilumina o campo. Ouça o batimento parar de repente, um único tiro ao longe e a trilha subir. Deixe a câmera estabilizar nos segundos finais, com espaço livre no terço superior para o título.
```

## 6. Montagem

1. **Ordem:** junte os 6 clipes na ordem do storyboard. Confira se o agente mantém a aparência e se o movimento segue da esquerda para a direita.
2. **Trilha:** use `assets/sounds/musica_tema.mp3` (trilha do jogo), começando baixa e abafada (filtro passa-baixa ou volume reduzido). Ela sobe na cena 6.
3. **Efeitos do próprio jogo:** `som_combate1.mp3` (engatilhar) no fim da cena 5 e `som_combate2.mp3` (tiro) na cena 6. Se o Flow não gerar o batimento, grave a tela da pausa do jogo durante um combate ou use um efeito de batimento livre de direitos.
4. **Textos em português:** os da tabela do storyboard, em fonte branca ou dourada, por pelo menos 2,5 segundos cada.
5. **Título:** "ART OF CONQUEST" nos últimos 3–4 segundos. Pode usar a própria capa (`capa_art_of_conquest.png`) com um corte para ela.
6. **Exportação:** 1080p, 16:9, MP4.

## 7. Teste com quem não conhece o jogo

Mostre o trailer e pergunte: **"Quem é o personagem, o que aconteceu e o que ele vai fazer agora?"**

Respostas esperadas:
- *Quem:* um soldado azul pequeno, sem arma (o agente).
- *O que aconteceu:* descobriu que os tanques inimigos escondem soldados.
- *O que vai fazer:* atravessar e revelar quem está sob as lonas, até a bandeira vermelha.

Se alguma resposta ficar confusa, refaça a cena correspondente (2, 3 ou 5).
