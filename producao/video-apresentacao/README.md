# Vídeo de apresentação — gravação e montagem

O roteiro com as falas de cada take fica só no computador (`docs/roteiro-video-apresentacao.md`, fora do repositório). Esta pasta tem as ferramentas que gravam as imagens do jogo e juntam a narração.

| Arquivo | Função |
|---|---|
| `gravador.gd` | Joga sozinho com um cursor visível (cliques e teclas de verdade) enquanto o Movie Maker da Godot grava. Salva as marcas de tempo de cada take em JSON. |
| `montar.py` | Recorta os takes, monta os comparativos N2 × versão final e o encerramento, mistura a narração e gera o vídeo final. |
| `narracao/` | Onde você salva a sua voz: `T01.wav`, `T02.wav`... (também `.mp3`, `.m4a`, `.ogg` e `.flac`). |

A pasta `producao/` não entra no executável do jogo. As gravações de narração ficam só no seu computador: o `.gitignore` exclui `producao/video-apresentacao/narracao/`. As gravações e os vídeos gerados ficam em `build/video/`, que o Git ignora.

## Fluxo de trabalho

1. **Grave a voz de cada take** assistindo ao clipe em `build/video/clipes/Txx.mp4` e salve em `producao/video-apresentacao/narracao/Txx.wav`.
2. **Monte o vídeo:**
   ```bash
   python producao/video-apresentacao/montar.py
   ```
   Resultado: `build/video/apresentacao-final.mp4`. Os takes ficam separados em `build/video/takes/`.

Antes de misturar, o `montar.py` trata cada narração sem mudar o tempo das falas. O resultado fica em `build/video/voz_tratada/`, e os seus arquivos em `producao/video-apresentacao/narracao/` não são alterados:

- **Fora da fala, silêncio total:** o que fica abaixo de −40 dB (`LIMIAR_FALA`) e os sons curtos e isolados, como cliques do mouse, viram silêncio absoluto.
- **Ganho fixo:** a voz vai para −16 LUFS (`ALVO_VOZ_LUFS`), sem normalização dinâmica, que aumentaria o ruído nas pausas.
- **Limitador:** só evita picos na mistura final.

As gravações da primeira versão estão em `producao/video-apresentacao/narracao/originais/`.

O `montar.py` usa o ffmpeg. Se ele não estiver no PATH, instale o pacote que já traz o ffmpeg:
```bash
pip install imageio-ffmpeg
```

## Regravar as imagens do jogo

Os takes vêm de quatro gravações em `build/video/brutos/`: `intro`, `tutorial`, `partida` e `n2`. Para gravar em 1,5x (1248 x 1056), crie um `override.cfg` temporário na raiz do projeto:

```ini
[display]

window/size/window_width_override=1248
window/size/window_height_override=1056
```

Depois rode cada roteiro (ajuste o caminho da Godot) e **apague o `override.cfg` ao terminar**:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe' --path . --write-movie build/video/brutos/partida.avi --fixed-fps 30 -s res://producao/video-apresentacao/gravador.gd -- roteiro=partida marcas=build/video/brutos/partida.json semente=37
```

- **Roteiros:** `intro`, `tutorial` e `partida`.
- **Partida:** a semente 37 gera a partida do roteiro (vitória azul em 20 turnos). Se mudar a semente, revise as falas dos takes T07 a T10.
- **`roteiro=busca`:** joga 40 sementes em alta velocidade, sem gravar, e imprime um resumo de cada partida.

**Versão N2:** extraia o commit avaliado no Dia do Analista numa pasta à parte, copie o gravador para ela e grave com o roteiro `n2` (janela de 768 x 960 no `override.cfg`):

```bash
mkdir ../aoc-n2 && git archive 4c80012 | tar -x -C ../aoc-n2 && mkdir ../aoc-n2/video && cp producao/video-apresentacao/gravador.gd ../aoc-n2/video/
```

Depois de mudar as gravações, rode `python producao/video-apresentacao/montar.py --refazer` para recortar os clipes de novo.
