# Roteiro — vídeo de apresentação jogada (mínimo de 10 minutos)

Formato: gravação de tela jogando e comentando, no estilo de uma live gravada. Câmera opcional.
Exibição: 03/12, aula no estilo cinema. Duração-alvo: **11 a 12 minutos** (margem acima do mínimo de 10).

## Antes de gravar

- **Versão:** use o executável final (`ArtOfConquest.exe`) ou rode pela Godot com F5.
- **Janela:** a janela tem 832 x 704. Grave em 1080p e maximize a janela do jogo (a interface escala sem distorcer) ou use o recorte de janela do OBS com zoom.
- **Áudio do jogo:** em **Menu (Esc) → Música**, deixe em **30–40%** e **Efeitos em 70–80%**. Os volumes ficam salvos.
- **Microfone:** grave 20 segundos de teste com o jogo tocando e ouça com fone. A voz precisa ficar claramente acima da trilha, inclusive nos combates.
- **Briefing:** ele aparece só na primeira partida de cada sessão. Abra o jogo do zero na hora de gravar, para mostrá-lo.
- **Antes e depois:** para mostrar a versão avaliada no Dia do Analista, abra a versão anterior numa pasta separada e grave 1–2 minutos dela antes da gravação principal:
  ```bash
  git worktree add ../aoc-versao-n2 4c80012
  ```
  Abra `../aoc-versao-n2/project.godot` na Godot e rode com F5. Também servem as telas do GDD da N3. Ao terminar, remova a pasta com `git worktree remove ../aoc-versao-n2`.

## Linha do tempo

| Tempo | Bloco | O que mostrar na tela | O que falar (resumo) |
|---|---|---|---|
| 00:00–00:45 | Abertura | Menu principal com a capa | Grupo, integrante(s), turma B, disciplina PAC, nome do jogo: Art of Conquest. |
| 00:45–02:00 | Proposta e história | Clicar em **Jogar** → briefing *Operação Bandeira Vermelha* | Jogo de estratégia e dedução por turnos. Ler o primeiro parágrafo do briefing. Objetivo: tomar a bandeira vermelha ou eliminar o exército inimigo. Pilares: estratégia, probabilidade e memória. |
| 02:00–04:00 | Primeira vez: aprender os controles | Voltar ao menu → **Tutorial**. Fazer os passos 1 a 8 (posicionar, selecionar, mover, turno da IA, card de cálculo, primeira pergunta) | Quem joga pela primeira vez aprende jogando: casa dourada indica o clique, o painel diz o que fazer, erro mostra dica. Responder errado uma pergunta para mostrar a explicação. |
| 04:00–04:45 | Regras no tutorial | Avançar até o duelo, o empate e o cerco (pode acelerar na edição) | Duelo: maior nível vence. Empate: os dois saem. Cerco: quem se moveu entre 2 inimigos perde. |
| 04:45–09:15 | Desafio representativo: partida completa | **Jogar** → posicionar as 8 peças → jogar até o fim | Ver detalhes abaixo. |
| 09:15–11:15 | O que mudou com as devolutivas | Alternar trechos da versão anterior e da final | Ver a tabela de antes e depois. |
| 11:15–12:00 | Encerramento | Tela de resultado → Menu → página do GitHub e Releases | Executável, repositório, GDD e trailer. Agradecer. |

## Partida completa (04:45–09:15): roteiro de fala

1. **Posicionamento:** "As casas azuis com borda clara mostram onde posicionar. As peças entram sempre na mesma ordem, do nível 1 ao 4. Coloco os Atiradores atrás, protegendo a bandeira."
2. **Leitura da tela:** "À direita, o status diz de quem é a vez. Embaixo ficam os cemitérios. O painel de probabilidades mostra 8 inimigos desconhecidos e 2.520 distribuições possíveis. Cada peça tem um marcador: círculo é meu time, triângulo é o inimigo."
3. **Primeira decisão:** selecionar um Agente (N1), abrir **Mostrar cálculo** do cartão azul: "Com o Agente, a chance de vencer uma desconhecida é 0%. Ele serve para revelar: se ele perde, eu descubro o nível de quem está ali."
4. **Primeiro duelo:** encostar numa vermelha oculta. "Ouvi o engatilhar e o batimento: é o suspense antes do resultado." Comentar a revelação e o cemitério.
5. **Atualizar a estratégia:** abrir o cálculo da vermelha. "Uma N4 apareceu. Agora restam 7 desconhecidas e só 1 N4, então meu Lançador ficou mais seguro."
6. **Turno da IA e perigo:** quando uma vermelha se aproximar da bandeira azul: "Percebam que a música subiu: o inimigo está a 3 casas da minha bandeira."
7. **Cerco:** mostrar (ou evitar e explicar) uma casa entre duas vermelhas: "Se eu entrar aqui, perco a peça, mesmo sendo um Atirador."
8. **Pausa:** apertar **Esc** e mostrar Continuar, Reiniciar, Como jogar e os volumes.
9. **Fim:** capturar a bandeira (ou perder) e mostrar a **tela de resultado**: motivo, turnos e baixas.

> Dica: se a partida demorar, corte trechos repetitivos na edição. O importante é que apareçam pelo menos um duelo, uma leitura de probabilidade, o perigo na bandeira e o fim.

## Antes e depois das devolutivas (09:15–11:15)

Ficha técnica do Dia do Analista (29/10/2026):

| Devolutiva | Antes (versão N2) | Depois (versão final) | Como melhorou para quem joga |
|---|---|---|---|
| Melhoria prioritária: "dificuldade para entender o início" | O jogo abria direto no tabuleiro, sem explicação | Tutorial guiado de 25 passos + briefing com objetivo e regras + Como jogar na pausa | Aprende sem ajuda dos criadores |
| Sugestão: "tela de menu e deixar mais intuitivo" | Menu simples com Jogar e Sair; sem volta ao menu | Capa nova, botões Jogar/Tutorial/Sair, menu de pausa com Voltar ao menu | Navegação clara do início ao fim |
| "Música tensa de fundo para dar emoção" | Trilha fixa, sempre igual | Trilha adaptativa + batimento cardíaco no combate e no perigo | Emoção acompanha o momento da partida |
| Leitura e contraste (nota 3) | Casas de posicionamento quase invisíveis sobre o céu | Destaque mais forte com borda clara | Fica claro onde clicar |
| "Há sinais além da cor?" (nota 4) | Times só pela cor da borda | Marcador de forma (círculo / triângulo) | Identificação sem depender da cor |
| Enredo e identidade (nota 3) | História só no GDD | Briefing *Operação Bandeira Vermelha* e tela de resultado narrada | Tema e objetivo ligados à história |

**Feedback do professor:** acrescentar aqui as recomendações recebidas e o que foi feito para cada uma.

Sugestão de fala: "A ficha disse que o mais difícil era entender o começo. Antes, era assim [mostrar versão N2]. Agora, quem abre o jogo encontra isto [mostrar menu, tutorial e briefing]."

## Checklist final

- [ ] Grupo, integrante(s) e nome do jogo ditos no começo
- [ ] Proposta, história e objetivo explicados
- [ ] Navegação desde o menu e tutorial mostrados
- [ ] Pelo menos uma partida representativa, com as mecânicas explicadas
- [ ] Antes e depois de cada devolutiva (ficha + professor)
- [ ] Duração ≥ 10 min
- [ ] Voz clara, sem a música encobrindo
