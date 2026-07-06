#!/usr/bin/env python

# For argument parsing
from sys import argv
import argparse

# For MioCodec
from miocodec import MioCodecModel, load_audio
import soundfile as sf


# Argument Parsing
parser = argparse.ArgumentParser(description='MioCodec commandline plugin for novel2audiobook.sh')
parser.add_argument('-i','--in', help='Where to find the input audio file', required=False, default='in.wav', dest='infile')
parser.add_argument('-o','--out', help='Where to put the output audio file', required=False, default='out.wav', dest='outfile')
parser.add_argument('-p','--prompt', help='The audio prompt for MioCodec to mimic', required=True, dest='promptfile')
parser.add_argument('-m','--model', help='The model to use for voice conversion', required=False, default='Aratako/MioCodec-25Hz-44.1kHz-v2', dest='vcmodel')
args = parser.parse_args()
print(args)
infile=args.infile
outfile=args.outfile
promptfile=args.promptfile
vcmodel=args.vcmodel


# Load model from Hugging Face
model = MioCodecModel.from_pretrained(vcmodel)
model = model.eval().cpu()

# Voice conversion (content from input file, speaker from prompt file)
source = load_audio(infile, sample_rate=model.config.sample_rate).cpu()
reference = load_audio(promptfile, sample_rate=model.config.sample_rate).cpu()

# Perform voice conversion
vc_wave = model.voice_conversion(source, reference)
sf.write(outfile, vc_wave.cpu().numpy(), samplerate=model.config.sample_rate)
