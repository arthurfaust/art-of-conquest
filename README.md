# Art of Conquest

Jogo de tabuleiro digital de **estratégia e dedução por turnos**. Você comanda o exército **Azul** contra o exército **Vermelho**, controlado pelo computador, em um tabuleiro de 8 x 8 casas. As peças inimigas começam escondidas: você sabe quais unidades o inimigo tem (duas de cada nível), mas não sabe onde cada uma está. Para vencer, capture a bandeira inimiga ou elimine todas as tropas adversárias. A proposta do jogo é treinar raciocínio lógico e probabilidade: cada peça revelada ou eliminada muda as chances do que ainda está escondido.

Projeto de Aprendizagem Colaborativa Extensionista IV — Engenharia de Software, 4º semestre, Turma B.
Integrantes: Arthur Faust Locatelli.

📄 **GDD (Game Design Document):** [`docs/GDD-Art-of-Conquest-Atualizado.pdf`](docs/GDD-Art-of-Conquest-Atualizado.pdf) (também em [.docx](docs/GDD-Art-of-Conquest-Atualizado.docx)). A seção *Ajustes da Entrega Final* do GDD lista o que mudou a partir das devolutivas.

---

## 0. Jogar sem instalar nada (executável para Windows)

1. Na página do repositório, abra **Releases** e baixe `ArtOfConquest-v1.0-Windows.zip`.
2. Extraia o `.zip` e dê dois cliques em **`ArtOfConquest.exe`**.
3. Se o Windows mostrar *"O Windows protegeu o computador"*, clique em **Mais informações → Executar assim mesmo** (o executável não tem assinatura digital).
4. No menu, escolha **Tutorial** na primeira vez ou **Jogar**.

Requisito: Windows 10 ou 11 (64 bits). As seções 1 a 4 abaixo são para quem quer abrir o **código-fonte** na Godot.

## 1. Requisitos

| Item | Versão / detalhe |
|---|---|
| Sistema operacional | Windows 10 ou 11 (64 bits). A Godot também roda em Linux e macOS, mas o projeto só foi testado no Windows. |
| Engine | **Godot Engine 4.7.2 (versão Standard, não a .NET/C#)** |
| Git | Opcional, só para clonar o repositório |
| Hardware | Qualquer PC com placa de vídeo compatível com DirectX 12 ou Vulkan |

Não há outras dependências: o projeto usa só GDScript e os recursos que já vêm na Godot.

## 2. Como baixar o projeto

**Opção A — com Git:**

```bash
git clone https://github.com/arthurfaust/art-of-conquest.git
```

**Opção B — sem Git:** na página do repositório no GitHub, clique em **Code → Download ZIP** e extraia o arquivo em uma pasta qualquer.

## 3. Como instalar a Godot

1. Acesse <https://godotengine.org/download/archive/> e baixe a **Godot 4.7.2 stable — Standard — Windows 64-bit**.
2. Extraia o `.zip`. Ele contém `Godot_v4.7.2-stable_win64.exe` e `Godot_v4.7.2-stable_win64_console.exe`. Mantenha os dois arquivos **na mesma pasta**.
3. Não é preciso instalar nada: a Godot roda direto do executável.

> Use a versão 4.7.x. Versões mais antigas (4.0 a 4.6) podem não abrir o projeto, e versões mais novas podem pedir para converter os arquivos.

## 4. Como executar o jogo

1. Abra `Godot_v4.7.2-stable_win64.exe`.
2. No **Gerenciador de Projetos**, clique em **Importar** (*Import*).
3. Selecione o arquivo **`project.godot`**, que fica na pasta do projeto baixada no passo 2, e confirme em **Importar e Editar** (*Import & Edit*).
4. Na primeira abertura, a Godot importa as imagens e os sons. Isso leva alguns segundos.
5. Com o editor aberto, pressione **F5** ou clique no botão **▶ Executar Projeto** (*Run Project*), no canto superior direito.
6. A janela do jogo abre no **menu principal**.

**Alternativa por linha de comando** (sem abrir o editor), executada de dentro da pasta do projeto:

```bash
"C:\caminho\para\Godot_v4.7.2-stable_win64.exe" --path .
```

## 5. Como jogar

### Iniciar uma partida

No menu principal, clique em **Jogar**. Para aprender praticando, escolha **Tutorial**. Para fechar o jogo, clique em **Sair**.

Na primeira partida, aparece o **briefing da missão** (*Operação Bandeira Vermelha*), com a história, o objetivo e um resumo das regras. Clique em **Começar missão** para posicionar seu exército ou em **Fazer o tutorial**. O briefing pode ser revisto a qualquer momento em **Menu → Como jogar**.

### Tutorial interativo

O tutorial usa cenários preparados e orientações no alto à direita. Clique nas **casas douradas** para posicionar, selecionar e mover suas peças. Abra os cards de cálculo quando solicitado e feche-os para prosseguir. Cinco perguntas verificam a compreensão das probabilidades, do empate e do cerco; uma resposta errada mostra uma explicação e permite tentar novamente.

Você pratica posicionamento, alternância de turnos, movimento, duelo, revelação dos inimigos, atualização das probabilidades, empate, cerco e captura da bandeira. O turno vermelho é demonstrado em uma etapa; nos demais exercícios, a IA fica suspensa para permitir o treino. Cada novo cenário repõe os exércitos e as informações conhecidas.

Use **Sair** no painel de instruções para retornar ao menu. Ao concluir, escolha **Jogar partida**, **Repetir tutorial** ou **Voltar ao menu**. Na partida normal, a IA joga a cada turno e os movimentos são livres dentro das regras.

### Controles

O jogo é controlado **só com o mouse (botão esquerdo)**:

| Ação | O que faz |
|---|---|
| Clicar em uma casa azul (fase de posicionamento) | Coloca a próxima unidade naquela casa |
| Clicar em uma peça sua | Seleciona a peça. Ela ganha um brilho e as casas para onde pode andar ficam azuis |
| Clicar na mesma peça de novo | Cancela a seleção |
| Clicar em outra peça sua | Troca a seleção |
| Clicar em uma casa destacada | Move a peça selecionada para essa casa |
| Botão **Menu** (canto do cartão de status) ou tecla **Esc** | Pausa a partida: Continuar, Reiniciar partida, Como jogar, volume de Música e Efeitos e Voltar ao menu |
| **Esc** com a pausa aberta | Retoma a partida |
| Botão **Jogar novamente** | Aparece no fim da partida e começa um novo jogo |

Os cliques são ignorados enquanto há animações, combates ou enquanto o computador está jogando.

Cada peça tem uma borda colorida e um **marcador de forma** no canto: **círculo** para o Azul e **triângulo** para o Vermelho, para identificar os times sem depender só da cor.

### Unidades

Cada exército tem **8 unidades**, duas de cada nível:

| Nível | Unidade | Vence | Empata com |
|---|---|---|---|
| 4 | Atirador de Elite | níveis 1, 2 e 3 | outro Atirador |
| 3 | Lançador de Mísseis | níveis 1 e 2 | outro Lançador |
| 2 | Fuzileiro | nível 1 | outro Fuzileiro |
| 1 | Agente Infiltrado | ninguém | outro Agente |

As peças vermelhas aparecem como um **tanque genérico** até entrarem em combate. Depois disso, ficam reveladas até o fim da partida.

### Passo a passo de uma partida

1. **Posicionamento:** as peças vermelhas são posicionadas automaticamente. As duas primeiras fileiras (parte de cima do tabuleiro) ficam azuis. Clique em 8 casas para colocar suas unidades. Elas entram sempre nesta ordem: Agente, Agente, Fuzileiro, Fuzileiro, Lançador, Lançador, Atirador, Atirador. O cartão de status no alto à direita mostra o nível da próxima peça e o progresso do posicionamento. A casa da bandeira não pode ser ocupada.
2. **Seu turno:** selecione uma peça e mova-a **uma casa** para cima, para baixo, para a esquerda ou para a direita (sem diagonal). A peça só pode ir para casas vazias.
3. **Turno do computador:** o cartão de status fica vermelho e mostra *"Vermelho pensando..."* enquanto uma peça vermelha se move.
4. Os turnos se alternam até alguém vencer.

### Regras de combate

O combate acontece **automaticamente** quando a peça que acabou de se mover termina **ao lado** (em cima, embaixo, à esquerda ou à direita) de uma peça inimiga:

- **Duelo (1 inimigo ao lado):** as duas peças são reveladas. Vence o **maior nível**, e a peça perdedora é eliminada. Se os níveis forem **iguais, as duas são eliminadas**.
- **Cerco (2 ou mais inimigos ao lado):** todas as peças envolvidas são reveladas e **a peça que se moveu é eliminada**, sem comparar níveis. Cuidado ao avançar entre duas peças inimigas!

As peças eliminadas aparecem nos **cemitérios** abaixo do tabuleiro: **BAIXAS AZUIS** à esquerda e **BAIXAS VERMELHAS** à direita. Cada cartão tem oito espaços, contador e o nível das unidades eliminadas. O cartão de status, no alto da coluna direita, mostra a fase da partida e identifica o turno por texto e cor. Use os cemitérios para deduzir quais níveis inimigos ainda estão escondidos.

### Objetivo e condições de vitória e derrota

| Resultado | Condição |
|---|---|
| **Vitória** | Mover uma peça sua até a **bandeira vermelha** (parte de baixo do tabuleiro, coluna 5) **ou** eliminar todas as peças vermelhas |
| **Derrota** | Uma peça vermelha chegar à **bandeira azul** (parte de cima, coluna 5) **ou** todas as suas peças serem eliminadas |

Ao fim da partida, a **tela de resultado** mostra **VITÓRIA** ou **DERROTA**, o motivo, os turnos jogados e as baixas de cada lado, com os botões **Jogar novamente**, **Ver o tabuleiro** e **Voltar ao menu**. Não há sistema de progressão entre partidas: cada partida começa do zero.

### Música e volume

A trilha reage à partida: fica abafada no menu, abre na batalha e fica mais intensa quando uma peça vermelha chega a até 3 casas da sua bandeira. No suspense de cada combate, entra um **batimento cardíaco**. Os volumes de **Música** e **Efeitos** são ajustados em **Menu** (Esc) e ficam salvos para as próximas vezes. Ao gravar a tela com comentários, reduza a música para cerca de 30–40%.

### Dicas

- Use os Agentes (nível 1) para descobrir quem são as peças inimigas: ao perder, eles revelam o inimigo para o resto da partida.
- Guarde os Atiradores para inimigos já revelados ou para quando restarem poucas peças fortes no exército vermelho.
- Duas de cada nível no início: se os dois Atiradores vermelhos já estão no cemitério, nenhuma peça escondida vence seu Lançador.

### Painel de probabilidades

O painel à direita tem contadores de unidades desconhecidas e espaço amostral no topo. O cartão vermelho mostra a quantidade restante, uma barra e o percentual de cada nível. O cartão azul destaca as chances de vitória, empate e derrota da peça selecionada. Cada botão de cálculo fica abaixo das probabilidades correspondentes. As informações são atualizadas durante as revelações e eliminações.

Com uma peça azul selecionada, clique no botão **Mostrar cálculo** do cartão azul para abrir o card com a quantidade favorável, o total de possibilidades, a fração e o percentual de cada resultado do duelo. Por exemplo: `Empate: 2/6 = 33,33%`. O denominador conta as unidades vermelhas ainda desconhecidas. Feche pelo botão **Fechar** ou pela tecla **Esc**.

O botão **Mostrar cálculo** do cartão vermelho abre o cálculo de cada nível da vermelha desconhecida: por exemplo, `Nível 1: 2/8 = 25%`. Ele pode ser usado sem selecionar uma peça azul. O numerador indica quantas unidades daquele nível ainda são desconhecidas; o denominador é o total de unidades desconhecidas. Esses valores são atualizados com as revelações e eliminações.

Essas chances não representam uma previsão de cerco nem de combate contra uma peça já revelada. Quando todas as vermelhas são conhecidas, o painel informa que não há inimigos desconhecidos para estimar. Para conferir também na aba Saída da Godot, ative **Debug Probabilities** no Inspector do nó Main.

## 6. Limitações conhecidas e funcionalidades não implementadas

- **Só um modo de jogo:** 1 jogador contra o computador. Não há multijogador local nem online.
- **IA simples:** o computador escolhe uma jogada aleatória entre as possíveis, dando preferência a avançar. Ele não usa as peças reveladas nem evita cercos.
- **Habilidades especiais das unidades** (previstas no GDD) não foram implementadas. Todo duelo é decidido só pelo nível.
- **General (nível 5):** a arte existe, mas a unidade não participa da partida.
- **Sem salvamento de partida:** fechar o jogo encerra a partida em andamento (só os volumes ficam salvos).
- **Bandeira azul:** o jogador pode mover uma peça para a casa da própria bandeira (o computador não pode fazer isso com a dele).
- **Janela de 832 x 704:** a interface escala ao redimensionar, mas foi pensada para esse tamanho, com o status e as probabilidades à direita e os cemitérios abaixo do tabuleiro.
- **Plataforma:** há executável apenas para Windows 64 bits; não há versão Web, Linux ou macOS pronta.
- **Executável sem assinatura digital:** o Windows SmartScreen pode pedir confirmação na primeira execução.

## 7. Testes automatizados

O script `tests/probability_validation.gd` verifica os casos extremos, as 81 combinações válidas de quantidades conhecidas por nível e a integração com o HUD. Execute no PowerShell, dentro da pasta do projeto, ajustando o caminho da Godot se necessário:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script tests/probability_validation.gd
```

O resultado esperado é `PROBABILITY_VALIDATION_OK`, com código de saída zero. Para testar a apresentação visual, execute o jogo com F5, selecione peças de níveis diferentes, confira os números após combates e reinicie a partida.

O script `tests/tutorial_validation.gd` percorre o tutorial completo, verifica cliques e respostas incorretos, cards, combates, informações conhecidas, vitória, reinício e retorno ao menu. Execute com o mesmo comando, substituindo o caminho do script; o resultado esperado é `TUTORIAL_VALIDATION_OK`.

O script `tests/match_flow_validation.gd` verifica os ajustes da entrega final: briefing, bloqueio do tabuleiro, pausa por Esc e pelo botão Menu, volumes, climas da música, batimento, tela de resultado, reinício, volta ao menu e tutorial sem briefing. O resultado esperado é `MATCH_FLOW_VALIDATION_OK`.

## 8. Como gerar o executável

1. Na Godot, abra **Editor → Gerenciar Modelos de Exportação** (*Manage Export Templates*) e baixe os modelos da versão 4.7.2.
2. Abra **Projeto → Exportar**, selecione o preset **Windows Desktop** e clique em **Exportar Projeto**. O arquivo é gerado em `build/windows/ArtOfConquest.exe`, com os recursos embutidos (um único arquivo).

Por linha de comando, dentro da pasta do projeto:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --export-release "Windows Desktop" build/windows/ArtOfConquest.exe
```

A pasta `build/` não vai para o Git; o executável é publicado na página **Releases** do GitHub.

## 9. Estrutura do projeto

```
art-of-conquest/
├── project.godot             # Configuração do projeto (abrir este arquivo na Godot)
├── scenes/
│   ├── menu.tscn             # Menu principal (cena inicial)
│   ├── main.tscn             # Partida: tabuleiro e HUD
│   ├── tutorial.tscn         # Tutorial que reutiliza a cena da partida
│   └── piece.tscn            # Peça do tabuleiro
├── scripts/
│   ├── menu.gd               # Botões Jogar, Tutorial e Sair
│   ├── main.gd               # Turnos, combate, IA, vitória e integração das probabilidades
│   ├── game_menus.gd         # Briefing da missão, menu de pausa e tela de resultado
│   ├── tutorial.gd           # Etapas guiadas, cenários e perguntas do tutorial
│   ├── probability_manager.gd # Cálculos de probabilidades e espaço amostral
│   ├── piece.gd              # Aparência, revelação e seleção da peça
│   └── audio_manager.gd      # Música adaptativa, batimento e volumes (autoload)
├── tests/                    # Testes automatizados (probabilidades, tutorial e fluxo da partida)
├── assets/
│   ├── images/               # Sprites das unidades, tabuleiro, bandeiras e ícone
│   └── sounds/               # Música tema e efeitos sonoros
├── docs/                     # GDD (.pdf e .docx), documentos de gestão e roteiros do vídeo e do trailer
├── producao/                 # Ferramentas de mídia (fora do jogo): trailer e vídeo de apresentação
├── icon.svg                  # Ícone padrão da Godot (a janela usa o tanque de assets/images)
├── default_bus_layout.tres   # Configuração dos canais de áudio
└── export_presets.cfg        # Configuração de exportação para Windows
```
