"""สร้างไฟล์เสียง placeholder แบบ procedural ทั้งหมดของเกม → assets/audio/*.wav
รัน:  python tools/gen_audio.py   (ต้องมี numpy)
เปลี่ยนเป็นเสียงจริงได้: วางไฟล์ .wav ชื่อเดิมทับ (ดู assets/audio/SOUNDS.md)
ไฟล์ที่ลงท้าย _loop / ambient_drone / heartbeat ถูกตั้งให้วนซ้ำในเกม (Game/Core/audio_manager.gd)
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = np.random.default_rng(1998)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=0.005, release=0.05):
    e = np.ones(n)
    a = max(1, int(SR * attack))
    r = max(1, int(SR * release))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] = np.minimum(e[-r:], np.linspace(1, 0, r))
    return e


def decay(n, rate):
    return np.exp(-np.arange(n) / SR * rate)


def noise(sec):
    return rng.uniform(-1, 1, int(SR * sec))


def lowpass(x, alpha):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def norm(x, peak=0.8):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def save(name, x, peak=0.8):
    x = norm(x, peak)
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name}.wav  {len(x) / SR:.2f}s")


def periodic_sine(freq, length):
    # ปัดความถี่ให้ครบรอบพอดีกับความยาว loop → วนต่อกันไม่มีรอยต่อ
    f = round(freq * length) / length
    return np.sin(2 * np.pi * f * t(length))


def thump(sec, f0, f1, rate):
    tt = t(sec)
    freq = np.linspace(f0, f1, len(tt))
    return np.sin(2 * np.pi * np.cumsum(freq) / SR) * decay(len(tt), rate)


def main():
    os.makedirs(OUT, exist_ok=True)

    # --- loops
    L = 24.0
    drone = (periodic_sine(43.0, L) * 0.6 + periodic_sine(64.5, L) * 0.3 + periodic_sine(86.0, L) * 0.15)
    wobble = 0.6 + 0.4 * periodic_sine(1 / 6, L)
    hiss = lowpass(noise(L), 0.02) * 0.4
    save("ambient_drone", drone * wobble + hiss, 0.6)

    st = noise(4.0) * 0.7 + lowpass(noise(4.0), 0.1) * 0.6
    crackle = (rng.random(len(st)) > 0.9985) * rng.uniform(-1, 1, len(st)) * 3
    save("static_loop", st + crackle, 0.5)

    L = 4.0
    carrier = periodic_sine(440, L) * (0.5 + 0.5 * periodic_sine(3, L)) + periodic_sine(660, L) * 0.3 * periodic_sine(0.5, L)
    save("transmission_loop", carrier * 0.35 + noise(L) * 0.25, 0.45)

    L = 3.0
    hum = periodic_sine(50, L) + periodic_sine(100, L) * 0.5 + periodic_sine(150, L) * 0.25
    save("power_hum_loop", hum + noise(L) * 0.03, 0.4)

    hb = np.zeros(int(SR * 1.0))
    a = thump(0.18, 70, 40, 18)
    b = thump(0.16, 60, 35, 20) * 0.7
    hb[:len(a)] += a
    hb[int(SR * 0.28):int(SR * 0.28) + len(b)] += b
    save("heartbeat", hb, 0.9)

    # --- one-shots
    n = lowpass(noise(0.12), 0.25) * decay(int(SR * 0.12), 40)
    save("footstep", n + thump(0.12, 120, 60, 40) * 0.5, 0.6)
    n = lowpass(noise(0.25), 0.12) * decay(int(SR * 0.25), 18)
    save("footstep_enemy", n + thump(0.25, 80, 35, 15) * 0.9, 0.8)

    tt = t(0.18)
    save("pickup", (np.sin(2 * np.pi * 880 * tt) + np.sin(2 * np.pi * 1320 * tt) * 0.5) * decay(len(tt), 20), 0.5)
    save("paper", lowpass(noise(0.4), 0.5) * env(int(SR * 0.4), 0.05, 0.2) * (0.5 + 0.5 * np.abs(np.sin(t(0.4) * 30))), 0.4)
    clack = np.concatenate([thump(0.06, 900, 300, 60), np.zeros(int(SR * 0.08)), thump(0.1, 400, 120, 40)])
    save("fuse_insert", clack + noise(len(clack) / SR) * 0.1 * decay(len(clack), 30), 0.7)

    tt = t(1.6)
    sw = thump(0.1, 300, 80, 30)
    swell = (np.sin(2 * np.pi * 50 * tt) + np.sin(2 * np.pi * 100 * tt) * 0.5) * np.minimum(tt / 1.2, 1) * 0.6
    swell[:len(sw)] += sw * 2
    save("switch_on", swell * env(len(tt), 0.001, 0.3), 0.8)

    tt = t(2.0)
    creak = np.sin(2 * np.pi * np.cumsum(180 + 60 * np.sin(tt * 3) + rng.normal(0, 30, len(tt))) / SR)
    save("door_open", (creak * 0.5 + lowpass(noise(2.0), 0.05)) * env(len(tt), 0.1, 0.5), 0.7)

    tt = t(0.08)
    save("keypad_beep", np.sign(np.sin(2 * np.pi * 1200 * tt)) * env(len(tt), 0.002, 0.02), 0.3)
    tt = t(0.6)
    save("keypad_error", np.sign(np.sin(2 * np.pi * 220 * tt)) * (np.sin(tt * 2 * np.pi * 8) > 0) * env(len(tt), 0.002, 0.05), 0.6)
    ok = np.concatenate([np.sin(2 * np.pi * f * t(0.12)) * env(int(SR * 0.12)) for f in (660, 880, 1320)])
    save("keypad_ok", ok, 0.5)

    save("tape_click", thump(0.05, 2000, 800, 80) + lowpass(noise(0.05), 0.6) * decay(int(SR * 0.05), 60), 0.6)
    save("radio_click", thump(0.04, 1500, 600, 90) + noise(0.04) * 0.3 * decay(int(SR * 0.04), 80), 0.5)
    tt = t(0.5)
    save("radio_lock", np.sin(2 * np.pi * np.linspace(300, 1200, len(tt)) * tt) * env(len(tt), 0.01, 0.2) + noise(0.5) * 0.2 * decay(len(tt), 6), 0.5)

    tt = t(1.4)
    scream_f = 500 + 300 * np.sin(tt * 23) + rng.normal(0, 80, len(tt))
    scream = np.sin(2 * np.pi * np.cumsum(scream_f) / SR) + noise(1.4) * 0.6
    save("enemy_scream", lowpass(scream, 0.4) * env(len(tt), 0.05, 0.5), 0.8)
    tt = t(1.2)
    js = noise(1.2) + np.sin(2 * np.pi * np.cumsum(np.linspace(900, 150, len(tt))) / SR)
    save("jumpscare", js * decay(len(tt), 2.5), 0.95)

    save("flashlight_click", thump(0.03, 3000, 1500, 120), 0.4)
    save("battery_swap", np.concatenate([thump(0.05, 1200, 600, 60), np.zeros(int(SR * 0.1)), thump(0.06, 900, 400, 50)]), 0.5)
    tt = t(0.7)
    save("locker", (lowpass(noise(0.7), 0.15) + np.sin(2 * np.pi * np.cumsum(140 + 40 * np.sin(tt * 9)) / SR) * 0.4) * env(len(tt), 0.02, 0.2), 0.6)
    save("ui_click", thump(0.03, 1800, 900, 100), 0.35)

    tt = t(3.5)
    chord = sum(np.sin(2 * np.pi * f * tt) for f in (220, 277.2, 329.6, 440)) * env(len(tt), 0.8, 1.5)
    save("win_sting", chord + lowpass(noise(3.5), 0.03) * 0.2, 0.5)
    tt = t(3.0)
    low = (np.sin(2 * np.pi * 55 * tt) + np.sin(2 * np.pi * 58.3 * tt)) * decay(len(tt), 0.8)
    save("gameover_sting", low + noise(3.0) * 0.3 * decay(len(tt), 1.5), 0.8)


if __name__ == "__main__":
    main()
