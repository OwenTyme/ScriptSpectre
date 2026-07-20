#!/usr/bin/env bash
#
# modem2.sh — synthesize a V.34-style modem handshake with real modulation
#
#   * true continuous-phase FSK (V.21 ch1 980/1180 Hz, ch2 1650/1850 Hz, 300 bd)
#   * ANSam: 2100 Hz, 15 Hz AM, hard phase reversal every 450 ms
#   * tones A/B (2400/1200 Hz) with phase reversals
#   * L1/L2 line probe: comb of 150 Hz harmonics, 150-3750 Hz
#   * training + data: random-symbol QAM on an 1800 Hz carrier
#
# Caller and answerer are built as two separate tracks and mixed, so bursts
# overlap the way they do on a real line (full duplex). Everything is then
# band-limited to the telephone channel and a noise floor is mixed under it.
#
# Usage: ./modem2.sh [output.wav] [phone-number]
#
set -euo pipefail

OUT="${1:-v34_handshake.wav}"
NUMBER="${2:-5550187}"
SR=8000
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Sample-accurate synthesizer. Emits sox .dat (text) on stdout.
# Modes:
#   fsk   p1=f_space p2=f_mark p3=baud            random bits, continuous phase
#   ansam                                          2100 Hz AM + phase reversals
#   tone  p1=freq   p2=reversal_interval (0=none)
#   comb  p1=f_step p2=n_tones                     harmonic comb (line probe)
#   qam   p1=carrier p2=baud                       random 16-QAM, rect pulses
# ---------------------------------------------------------------------------
cat > "$TMP/synth.awk" <<'AWK'
BEGIN {
    pi = 3.141592653589793
    print "; Sample Rate " sr
    print "; Channels 1"
    n = int(dur * sr)
    srand(seed)

    if (mode == "comb") {              # random phase per tone
        for (k = 1; k <= p2; k++) phc[k] = rand() * 2 * pi
    }
    spb = (p3 > 0) ? sr / p3 : 0       # samples per bit (fsk)
    sps = (p2 > 0) ? sr / p2 : 0       # samples per symbol (qam)
    nextb = 0; bit = 0; ph = 0
    I = 1; Q = 1

    for (i = 0; i < n; i++) {
        t = i / sr
        if (mode == "fsk") {
            if (i >= nextb) { bit = (rand() < 0.5) ? 0 : 1; nextb += spb }
            f = bit ? p2 : p1
            ph += 2 * pi * f / sr
            v = sin(ph)
        }
        else if (mode == "ansam") {
            sign = (int(t / 0.45) % 2) ? -1 : 1
            v = sign * (1 + 0.2 * sin(2*pi*15*t)) * sin(2*pi*2100*t) / 1.2
        }
        else if (mode == "tone") {
            sign = (p2 > 0 && int(t / p2) % 2) ? -1 : 1
            v = sign * sin(2*pi*p1*t)
        }
        else if (mode == "comb") {
            v = 0
            for (k = 1; k <= p2; k++) v += sin(2*pi*p1*k*t + phc[k])
            v /= (p2 * 0.35)           # crest-factor headroom
            if (v > 1) v = 1; if (v < -1) v = -1
        }
        else if (mode == "qam") {
            if (i >= nextb) {          # new random 16-QAM symbol
                I = (int(rand()*4) * 2 - 3) / 3
                Q = (int(rand()*4) * 2 - 3) / 3
                nextb += sps
            }
            v = (I * cos(2*pi*p1*t) - Q * sin(2*pi*p1*t)) / 1.5
        }
        else v = 0
        printf "%.6f %.6f\n", t, v * amp
    }
}
AWK

SEED=1
synth() {   # synth <outfile.wav> <mode> <dur> <amp> [p1] [p2] [p3]
    local f="$1" mode="$2" dur="$3" amp="$4" p1="${5:-0}" p2="${6:-0}" p3="${7:-0}"
    awk -v sr=$SR -v mode="$mode" -v dur="$dur" -v amp="$amp" \
        -v p1="$p1" -v p2="$p2" -v p3="$p3" -v seed=$((SEED++)) \
        -f "$TMP/synth.awk" > "$TMP/_s.dat"
    sox "$TMP/_s.dat" -r $SR -c 1 -b 16 "$f" fade t 0.005 "$dur" 0.01
}
sil() {     # sil <outfile.wav> <dur>
    sox -r $SR -n -b 16 "$1" trim 0 "$2"
}

# ---------------------------------------------------------------------------
# 1. PSTN section: off-hook clunk, dial tone, DTMF, ringback
# ---------------------------------------------------------------------------
sox -r $SR -n -b 16 "$TMP/p00_clunk.wav" synth 0.04 brownnoise vol 0.5 fade t 0.002 0.04 0.03
sox -r $SR -n -b 16 "$TMP/p01_dial.wav" synth 1.3 sine 350 sine 440 remix 1,2 vol 0.3 fade t 0.02 1.3 0.02

dtmf_freqs() {
    case "$1" in
        1) echo "697 1209";; 2) echo "697 1336";; 3) echo "697 1477";;
        4) echo "770 1209";; 5) echo "770 1336";; 6) echo "770 1477";;
        7) echo "852 1209";; 8) echo "852 1336";; 9) echo "852 1477";;
        0) echo "941 1336";; '*') echo "941 1209";; '#') echo "941 1477";;
    esac
}
i=0
for (( c=0; c<${#NUMBER}; c++ )); do
    read -r f1 f2 <<<"$(dtmf_freqs "${NUMBER:$c:1}")" || continue
    sox -r $SR -n -b 16 "$TMP/$(printf 'p02_dtmf%02d.wav' $i)" \
        synth 0.085 sine "$f1" sine "$f2" remix 1,2 vol 0.4 \
        fade t 0.004 0.085 0.004 pad 0 0.055
    i=$((i+1))
done
sil "$TMP/p03_gap.wav" 0.6
sox -r $SR -n -b 16 "$TMP/p04_ring.wav" synth 1.8 sine 440 sine 480 remix 1,2 vol 0.25 fade t 0.02 1.8 0.05
sil "$TMP/p05_gap.wav" 0.8
sox "$TMP"/p*.wav "$TMP/pstn.wav"

# ---------------------------------------------------------------------------
# 2. Handshake: two tracks, built sequentially, mixed full-duplex.
#    Timings approximate a real V.34 negotiation.
# ---------------------------------------------------------------------------

# --- ANSWERER track --------------------------------------------------------
synth "$TMP/a01.wav" ansam 3.3  0.40                 # ANSam w/ reversals
sil   "$TMP/a02.wav" 0.15
synth "$TMP/a03.wav" fsk  1.5  0.40 1650 1850 300    # JM  (V.21 ch2)
sil   "$TMP/a04.wav" 0.10
synth "$TMP/a05.wav" fsk  0.7  0.40 1650 1850 300    # INFO0a
sil   "$TMP/a06.wav" 0.10
synth "$TMP/a07.wav" tone 1.3  0.45 2400 0.55        # tone A + reversals
synth "$TMP/a08.wav" comb 0.75 0.60 150 25           # L1 probe (loud)
synth "$TMP/a09.wav" comb 1.30 0.30 150 25           # L2 probe
sil   "$TMP/a10.wav" 0.30
synth "$TMP/a11.wav" fsk  0.6  0.40 1650 1850 300    # INFO1a
sil   "$TMP/a12.wav" 0.25
synth "$TMP/a13.wav" qam  1.6  0.35 1800 2400        # S / TRN training
sil   "$TMP/a14.wav" 0.40
synth "$TMP/a15.wav" qam  3.5  0.35 1800 3000        # data
sox "$TMP"/a*.wav "$TMP/track_answer.wav"

# --- CALLER track ----------------------------------------------------------
sil   "$TMP/c01.wav" 1.40                            # listens to ANSam first
synth "$TMP/c02.wav" fsk  2.0  0.40  980 1180 300    # CM  (V.21 ch1)
sil   "$TMP/c03.wav" 1.30
synth "$TMP/c04.wav" fsk  0.7  0.40  980 1180 300    # INFO0c
sil   "$TMP/c05.wav" 0.35
synth "$TMP/c06.wav" tone 1.0  0.45 1200 0.50        # tone B + reversals
sil   "$TMP/c07.wav" 2.60                            # quiet during probe
synth "$TMP/c08.wav" fsk  0.6  0.40  980 1180 300    # INFO1c
sil   "$TMP/c09.wav" 0.20
synth "$TMP/c10.wav" qam  1.4  0.30 1800 2400        # caller training
sil   "$TMP/c11.wav" 0.60
synth "$TMP/c12.wav" qam  3.5  0.30 1800 3000        # data (full duplex)
sox "$TMP"/c*.wav "$TMP/track_caller.wav"

# --- line noise floor -------------------------------------------------------
DUR=$(soxi -D "$TMP/track_answer.wav")
sox -r $SR -n -b 16 "$TMP/floor.wav" synth "$DUR" pinknoise vol 0.012

# --- mix + telephone channel ------------------------------------------------
sox -m -v 1 "$TMP/track_answer.wav" -v 1 "$TMP/track_caller.wav" \
       -v 1 "$TMP/floor.wav" "$TMP/handshake_raw.wav"
sox "$TMP/handshake_raw.wav" "$TMP/handshake.wav" sinc 250-3550 gain -n -3

# ---------------------------------------------------------------------------
# 3. Assemble
# ---------------------------------------------------------------------------
sox "$TMP/pstn.wav" "$TMP/handshake.wav" "$OUT"
echo "Wrote $OUT ($(soxi -d "$OUT"))"


