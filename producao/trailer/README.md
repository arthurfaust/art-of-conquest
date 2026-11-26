# Trailer — Art of Conquest

Trailer narrativo de cerca de 1 minuto, montado na própria Godot com os assets do jogo e gravado com o **Movie Maker** (vídeo e áudio juntos). A história e os textos de cada cena estão na tabela abaixo.

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
- `gerar_sons.py`: sintetiza os efeitos (explosão distante, sinalizador, rajada e batimentos) em `sons/`. Não usa arquivos de terceiros. O `vento.wav` também é gerado, mas saiu do trailer.
- Trilha e efeitos de combate: os do próprio jogo (`assets/sounds/`). A trilha fica em destaque do início ao fim, sem filtro.

A pasta `producao/` fica fora do executável do jogo (filtro de exclusão do preset de exportação).

## Como gravar de novo

Dentro da pasta do projeto (ajuste o caminho da Godot):

1. Gere os efeitos (só é preciso uma vez):
   ```powershell
   python producao/trailer/gerar_sons.py
   ```
2. Crie um `override.cfg` temporário na raiz do projeto. Ele faz o Movie Maker gravar em 1080p; o `--resolution` não tem efeito na gravação:
   ```ini
   [display]

   window/size/viewport_width=1920
   window/size/viewport_height=1080
   ```
3. Grave:
   ```powershell
   & 'C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe' --path . res://producao/trailer/trailer.tscn --write-movie build/trailer/v1_bruto.avi --fixed-fps 30 --quit-after 1890
   ```
4. **Apague o `override.cfg`.** Se ele ficar, o jogo também abre em 1920 x 1080. O `.gitignore` já o exclui do Git.
5. Converta para MP4, com faixa de cor padrão e volume final por ganho fixo e limitador:
   ```powershell
   ffmpeg -i build/trailer/v1_bruto.avi -vf "scale=in_range=full:out_range=tv,format=yuv420p" -c:v libx264 -crf 18 -preset slow -af "volume=-0.6dB,alimiter=limit=0.74:level=false" -c:a aac -b:a 224k -movflags +faststart build/trailer/ArtOfConquest-Trailer.mp4
   ```

Para ajustar o tempo de uma cena ou um texto, altere `_timeline()` em `trailer.gd`.
