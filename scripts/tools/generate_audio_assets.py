#!/usr/bin/env python3
"""Generate the original music and sound effects used by Underwater World."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 22050
OUTPUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "audio"


def write_wav(name: str, samples: list[float]) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT_DIR / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        pcm = bytearray()
        for sample in samples:
            value = max(-1.0, min(1.0, math.tanh(sample)))
            pcm.extend(struct.pack("<h", int(value * 32767)))
        output.writeframes(pcm)


def normalize_peak(samples: list[float], target: float = 0.9) -> list[float]:
    peak = max(abs(sample) for sample in samples)
    if peak == 0.0:
        return samples
    scale = target / peak
    return [sample * scale for sample in samples]


def underwater_ambient() -> list[float]:
    # Keep the harmony calm, but put the arpeggio and melody in the range that
    # laptop speakers reproduce clearly.  The earlier version leaned heavily
    # on 55-150 Hz tones and was easy to mistake for silence.
    duration = 24.0
    total = int(duration * SAMPLE_RATE)
    chords = [
        (130.81, 196.00, 261.63, 329.63),
        (110.00, 164.81, 220.00, 261.63),
        (87.31, 130.81, 174.61, 220.00),
        (98.00, 146.83, 196.00, 246.94),
    ]
    melody = [523.25, 587.33, 659.25, 587.33, 493.88, 523.25, 440.00, 493.88]
    result: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        bar = int(t / 6.0) % len(chords)
        bar_phase = (t % 6.0) / 6.0
        swell = math.sin(math.pi * bar_phase) ** 0.65
        sample = 0.065 * math.sin(2.0 * math.pi * chords[bar][0] * 0.5 * t)
        for tone_index, frequency in enumerate(chords[bar]):
            phase = tone_index * 0.72
            sample += 0.07 * (0.45 + 0.55 * swell) * math.sin(2.0 * math.pi * frequency * t + phase)

        pulse_length = 0.5
        pulse_index = int(t / pulse_length)
        pulse_time = t % pulse_length
        arpeggio_frequency = chords[bar][pulse_index % len(chords)] * 2.0
        pulse_envelope = min(1.0, pulse_time / 0.025) * math.exp(-4.2 * pulse_time)
        sample += 0.18 * pulse_envelope * math.sin(2.0 * math.pi * arpeggio_frequency * t)
        sample += 0.045 * pulse_envelope * math.sin(2.0 * math.pi * arpeggio_frequency * 2.0 * t)

        note_length = 1.5
        note_index = int(t / note_length) % len(melody)
        note_phase = (t % note_length) / note_length
        note_envelope = math.sin(math.pi * note_phase) ** 2
        sample += 0.085 * note_envelope * math.sin(2.0 * math.pi * melody[note_index] * t)

        shimmer = 0.5 + 0.5 * math.sin(2.0 * math.pi * 0.07 * t)
        sample += 0.025 * shimmer * math.sin(2.0 * math.pi * 783.99 * t + 0.7)
        edge_fade = min(1.0, t / 0.18, (duration - t) / 0.18)
        result.append(sample * max(0.0, edge_fade))
    return normalize_peak(result)


def enemy_hit() -> list[float]:
    rng = random.Random(6102)
    duration = 0.24
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        decay = math.exp(-18.0 * t)
        sweep = 155.0 - 250.0 * t
        thump = math.sin(2.0 * math.pi * sweep * t) * decay * 0.75
        crack = (rng.random() * 2.0 - 1.0) * math.exp(-36.0 * t) * 0.5
        result.append(thump + crack)
    return result


def enemy_stomp() -> list[float]:
    duration = 0.32
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        decay = math.exp(-10.0 * t)
        frequency = 210.0 - 320.0 * t
        body = math.sin(2.0 * math.pi * frequency * t) * decay * 0.65
        pop = math.sin(2.0 * math.pi * 520.0 * t) * math.exp(-30.0 * t) * 0.28
        result.append(body + pop)
    return result


def player_hurt() -> list[float]:
    duration = 0.38
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        decay = math.exp(-7.5 * t)
        frequency = 390.0 - 520.0 * t
        pulse = math.sin(2.0 * math.pi * frequency * t)
        pulse += 0.35 * math.sin(2.0 * math.pi * frequency * 1.5 * t)
        result.append(pulse * decay * 0.55)
    return result


def coin_pickup() -> list[float]:
    duration = 0.24
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        second_note = t >= 0.1
        local_time = t - 0.1 if second_note else t
        frequency = 880.0 if second_note else 659.25
        decay = math.exp(-18.0 * local_time)
        tone = math.sin(2.0 * math.pi * frequency * local_time)
        tone += 0.3 * math.sin(2.0 * math.pi * frequency * 2.0 * local_time)
        result.append(tone * decay * 0.48)
    return result


def diamond_pickup() -> list[float]:
    duration = 0.48
    notes = (659.25, 830.61, 987.77, 1318.51)
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        note_index = min(int(t / 0.1), len(notes) - 1)
        local_time = t - note_index * 0.1
        decay = math.exp(-12.0 * max(local_time, 0.0))
        frequency = notes[note_index]
        tone = math.sin(2.0 * math.pi * frequency * local_time)
        tone += 0.24 * math.sin(2.0 * math.pi * frequency * 2.0 * local_time)
        result.append(tone * decay * 0.42)
    return result


def weapon_pickup() -> list[float]:
    duration = 0.42
    notes = (293.66, 440.0, 587.33)
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        note_index = min(int(t / 0.12), len(notes) - 1)
        local_time = t - note_index * 0.12
        frequency = notes[note_index]
        decay = math.exp(-10.0 * max(local_time, 0.0))
        tone = math.sin(2.0 * math.pi * frequency * local_time)
        tone += 0.28 * math.sin(2.0 * math.pi * frequency * 2.0 * local_time)
        result.append(tone * decay * 0.42)
    return result


def sword_swing() -> list[float]:
    rng = random.Random(8801)
    duration = 0.22
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        envelope = math.sin(math.pi * min(t / duration, 1.0)) ** 1.7
        noise = rng.random() * 2.0 - 1.0
        whistle = math.sin(2.0 * math.pi * (980.0 - 2100.0 * t) * t)
        result.append((noise * 0.28 + whistle * 0.24) * envelope)
    return result


def barrel_break() -> list[float]:
    rng = random.Random(4407)
    duration = 0.38
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        decay = math.exp(-9.0 * t)
        thump = math.sin(2.0 * math.pi * (105.0 - 95.0 * t) * t) * 0.55
        splinter = (rng.random() * 2.0 - 1.0) * 0.5
        result.append((thump + splinter) * decay)
    return result


def conch_enter() -> list[float]:
    """A bright rising shell chime for completing a level."""
    duration = 0.85
    notes = ((0.0, 392.0), (0.14, 523.25), (0.28, 659.25), (0.42, 783.99))
    result: list[float] = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        sample = 0.0
        for start, frequency in notes:
            if t < start:
                continue
            local_time = t - start
            attack = min(1.0, local_time / 0.018)
            decay = math.exp(-4.8 * local_time)
            shimmer = 1.0 + 0.004 * math.sin(2.0 * math.pi * 5.0 * local_time)
            sample += math.sin(2.0 * math.pi * frequency * shimmer * local_time) * attack * decay * 0.26
            sample += math.sin(2.0 * math.pi * frequency * 2.0 * local_time) * attack * decay * 0.07
        bubble_frequency = 220.0 + 620.0 * min(t / duration, 1.0)
        bubble = math.sin(2.0 * math.pi * bubble_frequency * t) * math.sin(math.pi * t / duration) ** 2
        result.append(sample + bubble * 0.08)
    return normalize_peak(result, 0.82)


def main() -> None:
    write_wav("underwater_ambient.wav", underwater_ambient())
    write_wav("enemy_hit.wav", enemy_hit())
    write_wav("enemy_stomp.wav", enemy_stomp())
    write_wav("player_hurt.wav", player_hurt())
    write_wav("coin_pickup.wav", coin_pickup())
    write_wav("diamond_pickup.wav", diamond_pickup())
    write_wav("weapon_pickup.wav", weapon_pickup())
    write_wav("sword_swing.wav", sword_swing())
    write_wav("barrel_break.wav", barrel_break())
    write_wav("conch_enter.wav", conch_enter())
    print(f"Generated audio assets in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
