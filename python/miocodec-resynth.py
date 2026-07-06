#!/usr/bin/env python

# For argument parsing
from sys import argv
import argparse

# For Miocodec
from miocodec import MioCodecModel, load_audio
import soundfile as sf


# Argument Parsing
parser = argparse.ArgumentParser(description='MioCodec commandline plugin for novel2audiobook.sh')
parser.add_argument('-i','--in', help='Where to find the input audio file', required=False, default='in.wav', dest='infile')
parser.add_argument('-o','--out', help='Where to put the output audio file', required=False, default='out.wav', dest='outfile')
parser.add_argument('-m','--model', help='The model to use for voice conversion', required=False, default='Aratako/MioCodec-25Hz-44.1kHz-v2', dest='vcmodel')
args = parser.parse_args()
print(args)
infile=args.infile
outfile=args.outfile
vcmodel=args.vcmodel


# Load model from Hugging Face
# Use "Aratako/MioCodec-25Hz-44.1kHz-v2" for 44.1kHz or "Aratako/MioCodec-25Hz-24kHz" for 24kHz
model = MioCodecModel.from_pretrained("Aratako/MioCodec-25Hz-44.1kHz-v2")
model = model.eval().cpu()

# Load audio
waveform = load_audio(infile, sample_rate=model.config.sample_rate).cpu()

# Encode
features = model.encode(waveform)

# Decode to waveform (directly, no vocoder needed)
resynth = model.decode(
    content_token_indices=features.content_token_indices,
    global_embedding=features.global_embedding,
)

# Save
sf.write(outfile, resynth.cpu().numpy(), model.config.sample_rate)
