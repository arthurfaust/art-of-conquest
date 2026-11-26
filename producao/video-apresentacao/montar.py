"""Monta o vídeo de apresentação a partir das gravações do jogo e da narração.

Etapas:
  1. Recorta cada take das gravações brutas (build/video/brutos) pelas marcas de tempo.
  2. Monta os comparativos N2 x versão final e o encerramento.
  3. Para cada take com narração em producao/video-apresentacao/narracao/Txx.(wav|mp3|m4a|ogg), mistura a voz
     com o som do jogo mais baixo e estende o último quadro se a fala for mais longa.
  4. Junta tudo em build/video/apresentacao-final.mp4.

Uso:
  python producao/video-apresentacao/montar.py            # clipes + vídeo final (takes sem narração entram com o som do jogo)
  python producao/video-apresentacao/montar.py --clipes   # só os clipes de referência para gravar a narração
  python producao/video-apresentacao/montar.py --refazer  # recorta os clipes de novo (por padrão, reaproveita os existentes)
"""
import json
import os
import re
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRUTOS = os.path.join(RAIZ, "build", "video", "brutos")
CLIPES = os.path.join(RAIZ, "build", "video", "clipes")
FINAIS = os.path.join(RAIZ, "build", "video", "takes")
NARRACAO = os.path.join(RAIZ, "producao", "video-apresentacao", "narracao")
SAIDA = os.path.join(RAIZ, "build", "video", "apresentacao-final.mp4")
CAPA = os.path.join(RAIZ, "assets", "images", "capa_art_of_conquest.png")
FONTE = "C\\:/Windows/Fonts/segoeuib.ttf"
FUNDO = "0x0a0d10"
VOLUME_JOGO_COM_VOZ = 0.22   # som do jogo por baixo da narração (cerca de -13 dB)
VOZ_TRATADA = os.path.join(RAIZ, "build", "video", "voz_tratada")
LIMIAR_FALA = -40.0          # dBFS: acima disso é fala; o ruído de fundo fica perto de -50
ALVO_VOZ_LUFS = -16          # volume final da narração (ganho fixo, sem compressão das pausas)

# Take, gravação, marca inicial, marca final, deslocamentos (s) no início e no fim
TAKES = [
    ("T01", "intro", "T01", "T02", 0, 0),
    ("T02", "intro", "T02", "fim", 0, 0),
    ("T03", "n2", "N2_menu", "fim", 0, 0),
    ("T04", "tutorial", "T04", "T05", 0, 0),
    ("T05", "tutorial", "T05", "fim", 0, 0),
    ("T06", "partida", "T06", "T07", 0, 0),
    ("T07", "partida", "T07", "T08", 0, 0),
    ("T08", "partida", "T08", "T09", 0, 0),
    ("T09", "partida", "T09", "T10", 0, 0),
    ("T10", "partida", "T10", "fim", 0, 0),
]

# Comparativos: (take, título, esquerda N2 [marca, deslocamento, duração], direita final [gravação, marca, deslocamento])
COMPARATIVOS = [
    ("T11a", "Início: entender o que fazer", ("N2_menu", 0, 14), ("intro", "T02", -5)),
    ("T11b", "Posicionamento: onde clicar", ("N2_posicionamento", 0, 13), ("partida", "T06", 3)),
    ("T11c", "Durante a partida: leitura e identificação", ("N2_partida", 0, 12), ("partida", "T08", 0)),
    ("T11d", "Fim da partida", ("N2_fim", 0, 10), ("partida", "fim", -11)),
]


def ffmpeg_exe():
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        return "ffmpeg"


FFMPEG = ffmpeg_exe()
CODEC = ["-c:v", "libx264", "-crf", "20", "-preset", "medium", "-pix_fmt", "yuv420p", "-r", "30",
         "-color_range", "tv", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2"]


def rodar(args):
    subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y"] + args, check=True)


def duracao(caminho):
    saida = subprocess.run([FFMPEG, "-hide_banner", "-i", caminho], capture_output=True, text=True).stderr
    h, m, s = re.search(r"Duration: (\d+):(\d+):([\d.]+)", saida).groups()
    return int(h) * 3600 + int(m) * 60 + float(s)


def marcas(gravacao):
    with open(os.path.join(BRUTOS, gravacao + ".json"), encoding="utf8") as arquivo:
        return {m["nome"]: m["t"] for m in json.load(arquivo)}


def enquadrar(altura=1080):
    """Escala para a altura do quadro e centraliza em 1920x1080 com fundo escuro."""
    return ("scale=-2:%d:in_range=full:out_range=tv:flags=lanczos,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=%s,setsar=1,format=yuv420p" % (altura, FUNDO))


def recortar_take(nome, gravacao, inicio, fim, desl_ini, desl_fim):
    m = marcas(gravacao)
    t0 = m[inicio] + desl_ini
    t1 = m[fim] + desl_fim
    destino = os.path.join(CLIPES, nome + ".mp4")
    rodar(["-ss", "%.3f" % t0, "-to", "%.3f" % t1, "-i", os.path.join(BRUTOS, gravacao + ".avi"),
           "-vf", enquadrar(), "-af", "aresample=48000"] + CODEC + [destino])
    return destino


def texto(nome, conteudo):
    caminho = os.path.join(CLIPES, nome + ".txt")
    with open(caminho, "w", encoding="utf8") as arquivo:
        arquivo.write(conteudo)
    return caminho.replace("\\", "/").replace(":", "\\:")


def comparativo(nome, titulo, esquerda, direita):
    marca_n2, desl_n2, dur = esquerda
    gravacao, marca_final, desl_final = direita
    t_n2 = marcas("n2")[marca_n2] + desl_n2
    t_final = marcas(gravacao)[marca_final] + desl_final
    destino = os.path.join(CLIPES, nome + ".mp4")
    rotulo = "drawtext=fontfile='%s':textfile='%s':fontcolor=%s:fontsize=34:x=%s:y=%d"
    filtro = ";".join([
        "[0:v]scale=-2:820:in_range=full:out_range=tv:flags=lanczos[esq]",
        "[1:v]scale=1000:-2:in_range=full:out_range=tv:flags=lanczos[dir]",
        "color=c=%s:s=1920x1080:r=30:d=%.2f[fundo]" % (FUNDO, dur),
        "[fundo][esq]overlay=x=(880-w)/2+20:y=200[a]",
        "[a][dir]overlay=x=900:y=200+(820-h)/2[b]",
        "[b]" + ",".join([
            rotulo % (FONTE, texto(nome + "_titulo", titulo), "white", "(w-text_w)/2", 60),
            rotulo % (FONTE, texto(nome + "_esq", "N2 · antes"), "0xff8c7d", "(880-text_w)/2+20", 140),
            rotulo % (FONTE, texto(nome + "_dir", "Versão final · depois"), "0x78c2ff", "900+(1000-text_w)/2", 140),
        ]) + ",setsar=1,format=yuv420p[v]",
        "[1:a]volume=0.8,aresample=48000[aud]",
    ])
    rodar(["-ss", "%.3f" % t_n2, "-t", "%.2f" % dur, "-i", os.path.join(BRUTOS, "n2.avi"),
           "-ss", "%.3f" % t_final, "-t", "%.2f" % dur, "-i", os.path.join(BRUTOS, gravacao + ".avi"),
           "-filter_complex", filtro, "-map", "[v]", "-map", "[aud]", "-shortest"] + CODEC + [destino])
    return destino


def encerramento(nome="T12", dur=35.0):
    destino = os.path.join(CLIPES, nome + ".mp4")
    linhas = [
        ("Art of Conquest · versão final 1.0", 44, "white", 790),
        ("Código, GDD e README: github.com/arthurfaust/art-of-conquest", 32, "0xdfbf7a", 860),
        ("Executável para Windows: página Releases do repositório", 32, "0xd4dde2", 910),
        ("Trailer: link na entrega", 32, "0xd4dde2", 960),
    ]
    textos = ",".join("drawtext=fontfile='%s':textfile='%s':fontcolor=%s:fontsize=%d:x=(w-text_w)/2:y=%d:alpha='min(1,max(0,(t-%.1f)/0.8))'" % (
        FONTE, texto("%s_%d" % (nome, i), t), cor, tamanho, y, 1.0 + i * 0.6) for i, (t, tamanho, cor, y) in enumerate(linhas))
    filtro = ("[0:v]scale=-2:740,zoompan=z='min(1.0+on/3000,1.06)':d=1:s=888x740:fps=30[capa];"
              "color=c=%s:s=1920x1080:r=30:d=%.1f[fundo];[fundo][capa]overlay=x=(W-w)/2:y=20[a];"
              "[a]%s,fade=t=in:st=0:d=1,fade=t=out:st=%.1f:d=1.5,setsar=1,format=yuv420p[v]" % (FUNDO, dur, textos, dur - 1.5))
    rodar(["-loop", "1", "-framerate", "30", "-t", "%.1f" % dur, "-i", CAPA,
           "-f", "lavfi", "-t", "%.1f" % dur, "-i", "anullsrc=r=48000:cl=stereo",
           "-filter_complex", filtro, "-map", "[v]", "-map", "1:a"] + CODEC + [destino])
    return destino


def narracao_de(nome):
    for extensao in ("wav", "mp3", "m4a", "ogg", "flac"):
        caminho = os.path.join(NARRACAO, "%s.%s" % (nome, extensao))
        if os.path.exists(caminho):
            return caminho
    return None


def tratar_voz(nome, voz):
    """Limpa a narração sem mudar o tempo das falas.

    1. Filtro passa-alta (tira ronco grave) e reparo de picos estourados.
    2. Gate: tudo que não é fala vira silêncio absoluto. Trechos acima de LIMIAR_FALA
       viram fala; sons curtos isolados (cliques do mouse) são descartados.
    3. Ganho fixo (loudnorm linear em duas passagens), que não amplifica o ruído nas pausas.
    """
    import wave
    import numpy as np

    os.makedirs(VOZ_TRATADA, exist_ok=True)
    bruto = os.path.join(VOZ_TRATADA, nome + "_bruto.wav")
    limpo = os.path.join(VOZ_TRATADA, nome + "_gate.wav")
    final = os.path.join(VOZ_TRATADA, nome + ".wav")
    rodar(["-i", voz, "-af", "highpass=f=80,adeclip", "-ac", "1", "-ar", "48000", "-c:a", "pcm_s16le", bruto])

    with wave.open(bruto) as arquivo:
        taxa = arquivo.getframerate()
        amostras = np.frombuffer(arquivo.readframes(arquivo.getnframes()), np.int16).astype(np.float32)
    janela = int(taxa * 0.02)
    n = len(amostras) // janela
    rms = np.sqrt(((amostras[:n * janela].reshape(n, janela) / 32768.0) ** 2).mean(1))
    fala = 20 * np.log10(rms + 1e-9) > LIMIAR_FALA

    # Agrupa trechos de fala, une os que estão próximos e descarta os curtos demais (cliques).
    trechos = []
    i = 0
    while i < n:
        if fala[i]:
            j = i
            while j < n and fala[j]:
                j += 1
            trechos.append([i, j])
            i = j
        else:
            i += 1
    unidos = []
    for inicio, fim in trechos:
        if unidos and (inicio - unidos[-1][1]) * 0.02 < 0.35:
            unidos[-1][1] = fim
        else:
            unidos.append([inicio, fim])
    unidos = [t for t in unidos if (t[1] - t[0]) * 0.02 >= 0.15]

    envelope = np.zeros(len(amostras), np.float32)
    rampa = int(taxa * 0.03)
    for inicio, fim in unidos:
        a = max(0, inicio * janela - int(taxa * 0.12))
        b = min(len(amostras), fim * janela + int(taxa * 0.25))
        envelope[a:b] = 1.0
    # Suaviza as bordas do gate para não gerar estalos.
    kernel = np.ones(rampa, np.float32) / rampa
    envelope = np.convolve(envelope, kernel, mode="same")
    saida = (amostras * envelope).clip(-32768, 32767).astype(np.int16)
    with wave.open(limpo, "wb") as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(taxa)
        arquivo.writeframes(saida.tobytes())

    # Ganho fixo: mede a fala e aplica o loudnorm em modo linear.
    medida = subprocess.run([FFMPEG, "-hide_banner", "-i", limpo, "-af",
                             "loudnorm=I=%d:TP=-2:LRA=11:print_format=json" % ALVO_VOZ_LUFS, "-f", "null", "-"],
                            capture_output=True, text=True).stderr
    dados = json.loads(medida[medida.rindex("{"):medida.rindex("}") + 1])
    filtro = ("loudnorm=I=%d:TP=-2:LRA=11:measured_I=%s:measured_TP=%s:measured_LRA=%s:"
              "measured_thresh=%s:offset=%s:linear=true" % (
                  ALVO_VOZ_LUFS, dados["input_i"], dados["input_tp"], dados["input_lra"],
                  dados["input_thresh"], dados["target_offset"]))
    rodar(["-i", limpo, "-af", filtro + ",aresample=48000", "-c:a", "pcm_s16le", final])
    os.remove(bruto)
    os.remove(limpo)
    return final


def aplicar_narracao(nome, clipe):
    voz = narracao_de(nome)
    destino = os.path.join(FINAIS, nome + ".mp4")
    if not voz:
        rodar(["-i", clipe, "-c", "copy", destino])
        return destino, False
    voz = tratar_voz(nome, voz)
    d_clipe = duracao(clipe)
    d_voz = duracao(voz)
    total = max(d_clipe, d_voz + 1.0)
    filtro = ("[0:v]tpad=stop_mode=clone:stop_duration=%.2f[v];"
              "[0:a]volume=%.2f,apad[jogo];"
              "[1:a]adelay=300|300,apad[voz];"
              "[jogo][voz]amix=inputs=2:duration=longest:normalize=0,atrim=0:%.2f,"
              "alimiter=limit=0.89:level=false[a]" % (max(0.0, total - d_clipe), VOLUME_JOGO_COM_VOZ, total))
    rodar(["-i", clipe, "-i", voz, "-filter_complex", filtro, "-map", "[v]", "-map", "[a]",
           "-t", "%.2f" % total] + CODEC + [destino])
    return destino, True


def gerar(nome, funcao, *args):
    destino = os.path.join(CLIPES, nome + ".mp4")
    if os.path.exists(destino) and "--refazer" not in sys.argv:
        return destino
    print("gerando", nome)
    return funcao(*args)


def main():
    so_clipes = "--clipes" in sys.argv
    os.makedirs(CLIPES, exist_ok=True)
    os.makedirs(FINAIS, exist_ok=True)
    ordem = []
    for take in TAKES:
        ordem.append((take[0], gerar(take[0], recortar_take, *take)))
    for item in COMPARATIVOS:
        ordem.append((item[0], gerar(item[0], comparativo, *item)))
    ordem.append(("T12", gerar("T12", encerramento)))
    if so_clipes:
        print("Clipes prontos em", CLIPES)
        return
    lista = os.path.join(FINAIS, "lista.txt")
    com_voz = []
    with open(lista, "w", encoding="utf8") as arquivo:
        for nome, clipe in ordem:
            final, tem_voz = aplicar_narracao(nome, clipe)
            if tem_voz:
                com_voz.append(nome)
            arquivo.write("file '%s'\n" % final.replace("\\", "/"))
    rodar(["-f", "concat", "-safe", "0", "-i", lista, "-c", "copy", "-movflags", "+faststart", SAIDA])
    print("Takes com narração:", ", ".join(com_voz) or "nenhum")
    print("Vídeo final: %s (%.0f s)" % (SAIDA, duracao(SAIDA)))


if __name__ == "__main__":
    main()
