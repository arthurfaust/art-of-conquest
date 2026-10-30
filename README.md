# Art of Conquest

Jogo de tabuleiro digital de **estratégia e dedução por turnos**. Você comanda o exército **Azul** contra o exército **Vermelho**, controlado pelo computador, em um tabuleiro de 8 x 8 casas. As peças inimigas começam escondidas: você sabe quais unidades o inimigo tem (duas de cada nível), mas não sabe onde cada uma está. Para vencer, capture a bandeira inimiga ou elimine todas as tropas adversárias. A proposta do jogo é treinar raciocínio lógico e probabilidade: cada peça revelada ou eliminada muda as chances do que ainda está escondido.

Projeto de Aprendizagem Colaborativa Extensionista IV — Engenharia de Software, 4º semestre, Turma B.
Integrantes: Arthur Faust Locatelli.

📄 **GDD (Game Design Document):** [`docs/GDD-Art-of-Conquest-Atualizado.pdf`](docs/GDD-Art-of-Conquest-Atualizado.pdf) (também em [.docx](docs/GDD-Art-of-Conquest-Atualizado.docx)).

---

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

No menu principal, clique em **Jogar**. Para fechar o jogo, clique em **Sair**.

### Controles

O jogo é controlado **só com o mouse (botão esquerdo)**:

| Ação | O que faz |
|---|---|
| Clicar em uma casa azul (fase de posicionamento) | Coloca a próxima unidade naquela casa |
| Clicar em uma peça sua | Seleciona a peça. Ela ganha um brilho e as casas para onde pode andar ficam azuis |
| Clicar na mesma peça de novo | Cancela a seleção |
| Clicar em outra peça sua | Troca a seleção |
| Clicar em uma casa destacada | Move a peça selecionada para essa casa |
| Botão **Jogar novamente** | Aparece no fim da partida e começa um novo jogo |

Os cliques são ignorados enquanto há animações, combates ou enquanto o computador está jogando.

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

1. **Posicionamento:** as peças vermelhas são posicionadas automaticamente. As duas primeiras fileiras (parte de cima do tabuleiro) ficam azuis. Clique em 8 casas para colocar suas unidades. Elas entram sempre nesta ordem: Agente, Agente, Fuzileiro, Fuzileiro, Lançador, Lançador, Atirador, Atirador. A mensagem na parte de baixo da tela mostra o nível da próxima peça. A casa da bandeira não pode ser ocupada.
2. **Seu turno:** selecione uma peça e mova-a **uma casa** para cima, para baixo, para a esquerda ou para a direita (sem diagonal). A peça só pode ir para casas vazias.
3. **Turno do computador:** a mensagem muda para *"Pensando... (VERMELHO)"* e uma peça vermelha se move.
4. Os turnos se alternam até alguém vencer.

### Regras de combate

O combate acontece **automaticamente** quando a peça que acabou de se mover termina **ao lado** (em cima, embaixo, à esquerda ou à direita) de uma peça inimiga:

- **Duelo (1 inimigo ao lado):** as duas peças são reveladas. Vence o **maior nível**, e a peça perdedora é eliminada. Se os níveis forem **iguais, as duas são eliminadas**.
- **Cerco (2 ou mais inimigos ao lado):** todas as peças envolvidas são reveladas e **a peça que se moveu é eliminada**, sem comparar níveis. Cuidado ao avançar entre duas peças inimigas!

As peças eliminadas aparecem nos **cemitérios** na parte de baixo da tela: **AZUIS** à esquerda e **VERMELHAS** à direita, cada um com um contador. Use os cemitérios para deduzir quais níveis inimigos ainda estão escondidos.

### Objetivo e condições de vitória e derrota

| Resultado | Condição |
|---|---|
| **Vitória** | Mover uma peça sua até a **bandeira vermelha** (parte de baixo do tabuleiro, coluna 5) **ou** eliminar todas as peças vermelhas |
| **Derrota** | Uma peça vermelha chegar à **bandeira azul** (parte de cima, coluna 5) **ou** todas as suas peças serem eliminadas |

Ao fim da partida, a mensagem mostra o vencedor e aparece o botão **Jogar novamente**. Não há sistema de progressão entre partidas: cada partida começa do zero.

### Dicas

- Use os Agentes (nível 1) para descobrir quem são as peças inimigas: ao perder, eles revelam o inimigo para o resto da partida.
- Guarde os Atiradores para inimigos já revelados ou para quando restarem poucas peças fortes no exército vermelho.
- Duas de cada nível no início: se os dois Atiradores vermelhos já estão no cemitério, nenhuma peça escondida vence seu Lançador.

## 6. Limitações conhecidas e funcionalidades não implementadas

- **Sem tutorial dentro do jogo:** este README é o guia de uso.
- **Só um modo de jogo:** 1 jogador contra o computador. Não há multijogador local nem online.
- **IA simples:** o computador escolhe uma jogada aleatória entre as possíveis, dando preferência a avançar. Ele não usa as peças reveladas nem evita cercos.
- **Probabilidades não aparecem na tela:** o cálculo de chances (vitória/empate/derrota e espaço amostral) já existe no código (`main.gd`), mas ainda não é exibido na interface.
- **Habilidades especiais das unidades** (previstas no GDD) não foram implementadas. Todo duelo é decidido só pelo nível.
- **General (nível 5):** a arte existe, mas a unidade não participa da partida.
- **Sem volta ao menu:** dentro da partida não há botão para voltar ao menu. Para sair, feche a janela.
- **Sem opções de volume, pausa ou salvamento.**
- **Bandeira azul:** o jogador pode mover uma peça para a casa da própria bandeira (o computador não pode fazer isso com a dele).
- **Janela fixa de 512 x 640:** a interface escala ao redimensionar, mas foi pensada para esse tamanho.
- **Executável:** a versão atual é executada pela Godot. Ainda não há um `.exe` pronto para download.

## 7. Estrutura do projeto

```
art-of-conquest/
├── project.godot             # Configuração do projeto (abrir este arquivo na Godot)
├── scenes/
│   ├── menu.tscn             # Menu principal (cena inicial)
│   ├── main.tscn             # Partida: tabuleiro e HUD
│   └── piece.tscn            # Peça do tabuleiro
├── scripts/
│   ├── menu.gd               # Botões Jogar e Sair
│   ├── main.gd               # Turnos, combate, IA, vitória e probabilidades
│   ├── piece.gd              # Aparência, revelação e seleção da peça
│   └── audio_manager.gd      # Música de fundo global (autoload)
├── assets/
│   ├── images/               # Sprites das unidades, tabuleiro, bandeiras e ícone
│   └── sounds/               # Música tema e efeitos sonoros
├── docs/                     # GDD atualizado (.pdf e .docx)
├── icon.svg                  # Ícone do projeto na Godot
├── default_bus_layout.tres   # Configuração dos canais de áudio
└── export_presets.cfg        # Configuração de exportação para Windows
```
