# Produção de mídia

Ferramentas usadas para produzir o trailer e o vídeo de apresentação da entrega final. Nada aqui faz parte do jogo: a pasta `producao/` fica fora do executável (filtro de exclusão do preset de exportação), e os vídeos gerados vão para `build/`, que o Git ignora.

| Pasta | O que tem | Resultado |
|---|---|---|
| [`trailer/`](trailer/README.md) | Cena da Godot com a linha do tempo do trailer, efeitos sintetizados e instruções de gravação | `build/trailer/ArtOfConquest-Trailer.mp4` |
| [`video-apresentacao/`](video-apresentacao/README.md) | Gravador automático das cenas de jogo, montagem com a narração e a pasta da narração (fora do Git) | `build/video/apresentacao-final.mp4` |

Os roteiros (falas de cada take do vídeo e storyboard do trailer) ficam só no computador, em `docs/`, fora do repositório.
