"""Sintetiza os sons ambientes do trailer (sem arquivos de terceiros).

Uso: python producao/trailer/gerar_sons.py
Gera WAVs em producao/trailer/sons/: vento, explosão distante, sinalizador e batimentos.
"""
import os
import wave
import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sons")
rng = np.random.default_rng(7)


def lowpass(signal, alpha):
    out = np.empty_like(signal)
    acc = 0.0
    for i, value in enumerate(signal):
        acc += alpha * (value - acc)
        out[i] = acc
    return out


def save(name, signal):
    signal = signal / (np.max(np.abs(signal)) + 1e-9) * 0.9
    data = (signal * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())


def wind(seconds=24.0):
    n = int(RATE * seconds)
    noise = lowpass(rng.standard_normal(n), 0.02)
    t = np.arange(n) / RATE
    gusts = 0.55 + 0.45 * np.sin(2 * np.pi * 0.11 * t) * np.sin(2 * np.pi * 0.037 * t + 1.0)
    fade = np.minimum(1.0, np.minimum(t / 2.0, (seconds - t) / 2.0))
    return noise * gusts * fade


def boom(seconds=3.0):
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    rumble = lowpass(rng.standard_normal(n), 0.008) * np.exp(-t * 1.6)
    thump = np.sin(2 * np.pi * (45 - 15 * t) * t) * np.exp(-t * 4.0)
    attack = np.minimum(1.0, t / 0.02)
    return (rumble * 3.0 + thump) * attack


def flare(seconds=2.2):
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    pitch = 600 + 900 * np.minimum(t / 1.2, 1.0)
    whistle = np.sin(2 * np.pi * np.cumsum(pitch) / RATE) * np.exp(-((t - 0.7) ** 2) / 0.35) * 0.35
    hiss = lowpass(rng.standard_normal(n), 0.3) * np.exp(-np.maximum(t - 1.2, 0) * 1.5) * np.minimum(1, t / 1.2) * 0.6
    pop = np.where(t > 1.2, np.sin(2 * np.pi * 90 * (t - 1.2)) * np.exp(-(t - 1.2) * 18), 0) * 0.8
    return whistle + hiss + pop


def heartbeat(seconds, period):
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    phase = np.mod(t, period)
    signal = np.zeros(n)
    for start, gain in [(0.0, 1.0), (0.26 * min(1.0, period / 0.8), 0.7)]:
        dt = phase - start
        mask = (dt >= 0) & (dt < 0.22)
        signal[mask] += np.sin(2 * np.pi * (60 - dt[mask] * 60) * dt[mask]) * np.exp(-dt[mask] * 20) * gain
    return signal


def gust(seconds=1.6):
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    envelope = np.sin(np.pi * t / seconds) ** 2
    return lowpass(rng.standard_normal(n), 0.12) * envelope


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("vento.wav", wind())
    save("explosao_distante.wav", boom())
    save("sinalizador.wav", flare())
    save("batimento_lento.wav", heartbeat(10.0, 1.0))
    save("batimento_rapido.wav", heartbeat(8.0, 0.55))
    save("rajada_lona.wav", gust())
    print("sons gerados em", OUT)
