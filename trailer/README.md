# Trailer — Art of Conquest

Trailer narrativo de cerca de 1 minuto, montado na própria Godot com os assets do jogo e gravado com o **Movie Maker** (vídeo e áudio juntos). O roteiro, o storyboard e os prompts alternativos para o Google Flow estão em [`docs/trailer-roteiro-e-prompts.md`](../docs/trailer-roteiro-e-prompts.md).

## História

Na noite em que a trégua acaba, o Agente Infiltrado, o soldado mais fraco do exército Azul, descobre que os blindados inimigos são lonas escondendo tropas. Ele atravessa a terra de ninguém para revelar quem está do outro lado.

| Tempo | Cena | Texto na tela |
|---|---|---|
| 0–10 s | O campo: trincheiras ao anoitecer, fumaça, explosões e as duas bandeiras | "A trégua durou até o anoitecer." |
| 10–20 s | O pelotão: fichas das unidades; o Agente em destaque | "O mais fraco do pelotão." |
| 20–30 s | As lonas: uma lona levanta e mostra um soldado por um instante | "Do outro lado, ninguém sabe quem espera sob as lonas." |
| 30–40 s | A decisão: mapa do tabuleiro, alvo na bandeira vermelha; o agente dá um passo à frente | "Alguém precisa descobrir." |
| 40–52 s | A travessia: avanço casa a casa, sinalizador, revelação de um Atirador e eliminação do agente | "Ele não voltou. Mas agora todos sabem quem estava ali." |
| 52–62 s | Título com a capa do jogo | "Cada peça revelada muda as chances." |

## Arquivos

- `trailer.tscn` / `trailer.gd`: cena e linha do tempo (cada evento acontece em um segundo fixo).
- `gerar_sons.py`: sintetiza os sons ambientes (vento, explosão distante, sinalizador, rajada e batimentos) em `sons/`. Não usa arquivos de terceiros.
- Trilha e efeitos de combate: os do próprio jogo (`assets/sounds/`).

A pasta `trailer/` fica fora do executável do jogo (filtro de exclusão do preset de exportação).

## Como gravar de novo

Dentro da pasta do projeto (ajuste o caminho da Godot):

```powershell
python trailer/gerar_sons.py
& 'C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe' --path . res://trailer/trailer.tscn --resolution 1920x1080 --write-movie build/trailer/trailer.avi --fixed-fps 30 --quit-after 1890
```

O Movie Maker grava um AVI (MJPEG + PCM). Para converter em MP4 (H.264 + AAC), por exemplo com o ffmpeg:

```powershell
ffmpeg -i build/trailer/trailer.avi -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -c:a aac -b:a 192k build/trailer/ArtOfConquest-Trailer.mp4
```

Para ajustar o tempo de uma cena ou um texto, altere `_timeline()` em `trailer.gd`.
