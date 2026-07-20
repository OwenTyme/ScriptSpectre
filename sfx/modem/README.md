# About This Directory

After I added the option to use DTMF signals as sound effects, [EnigmaCurry](https://github.com/EnigmaCurry) suggested I add a synthesized version of a modem negotiation and he eventually produced [modem2.sh](modem2.sh) using [claude.ai](claude.ai).

In the next section, the portions in block quotes are from EnigmaCurry, while the rest is the response from the LLM, minus the files.  Only the final version of the script was passed to me.

[modem2.sh](modem2.sh) takes two parameters, first the file name to save the audio to, then the phone number to dial, without dashes.

This requires both the `sox` and `awk` commands available on the path.

Here's an example of the result, using the default phone number, which is 555-0187: [modem.flac](modem.flac)


## The LLM Conversation

> I want to write a bash script using sox to synthesize modem negotiation sounds

This is a fun one — the classic V.34/V.90 handshake has really distinct phases (dial tone, DTMF, answer tone, probing, then the noise burst), and sox can approximate all of them. Let me build it and actually test that it produces something that sounds right.Sox is available. Now the script:One typo in the grind segment — fixing:Done and tested — the script runs clean and produces a ~17 second handshake. I included a rendered sample so you can hear it before running anything.

A few notes on the synthesis tricks it uses, in case you want to tweak:

- **8 kHz sample rate** keeps everything telephone-bandwidth, which does a lot of the "authenticity" work for free.
- **DTMF** is two `sine` generators mixed with `remix 1,2` (sox's `synth` puts multiple oscillators on separate channels by default).
- **ANSam answer tone** is 2100 Hz with `tremolo 15 40` to fake the 15 Hz amplitude modulation. Real ANSam also flips phase every 450 ms — if you want that, generate 450 ms chunks and alternate `vol 1` / `vol -1` before concatenating.
- **FSK chatter** cheats with a frequency sweep (`sine 1650-1850`) plus a fast tremolo (~150 Hz) so it warbles like 300-baud V.21 traffic.
- **The data hiss** is just band-limited noise (`sinc 300-3400`), since scrambled QAM is spectrally close to noise anyway — pinknoise with a slow tremolo for the "grinding" phase, then whitenoise for the full-rate roar.

Usage: `./modem.sh out.wav 8675309` — second arg is the number it "dials," so the DTMF sequence changes accordingly.

> well, that's like a comical version of one, it doesn't match reference modems I have

Fair — that first pass was more "cartoon modem" than modem. The tremolo tricks don't hold up against real recordings because a real handshake contains *actual modulated signals*: true continuous-phase FSK at 300 baud, a 2100 Hz answer tone with hard 450 ms phase reversals, a wideband probe that's a comb of 150 Hz harmonics, and QAM data that's spectrally shaped noise with sharp band edges. Sox's `synth` can't do most of that directly, but a bash script can generate the real waveforms sample-by-sample (awk → sox `.dat` text format) and use sox for filtering, mixing, and assembly. Let me rebuild it properly around the V.34 sequence and verify against a spectrogram, since that's the easiest way to compare against references.What changed, structurally: `synth`/`tremolo` is gone for everything modem-side. An embedded awk program generates the actual waveforms sample-by-sample (output as sox's `.dat` text format, which sox then converts), so you get real continuous-phase FSK with random bits at 300 baud, a genuine ANSam with 15 Hz AM and hard 450 ms phase flips, a proper 150 Hz harmonic comb for the line probe, and random-symbol 16-QAM on an 1800 Hz carrier for training and data. The caller and answerer are also built as two separate tracks and mixed, so bursts overlap full-duplex the way they do on a real line — that overlap is a big part of why real recordings sound "conversational" and v1 sounded like a slideshow. Everything runs through a 250–3550 Hz sinc filter with a faint pink-noise floor underneath.

Two things worth comparing against your references:

1. **Which standard are they?** This models V.34. A V.32bis handshake has no ANSam wobble (plain 2100 Hz ANS) and no harmonic-comb probe, and V.90/V.92 adds the very distinctive digital-impairment-learning section (the rhythmic "clicking/chugging" after training). If your references are 56k modems, that missing section will be the most audible difference.

2. **Timing and levels.** All segment durations, gaps, and amplitudes are individual `synth`/`sil` lines in the two track sections, so you can line the script up against a spectrogram of your reference (sox can make one: `sox ref.wav -n spectrogram -o ref.png`) and adjust burst-by-burst.

If you can tell me which modems/standard your reference recordings are, I can restructure the sequence to match — the synth primitives (fsk/tone/comb/qam) cover most of what any of the standards need.