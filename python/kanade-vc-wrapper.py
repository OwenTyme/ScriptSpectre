#!/usr/bin/env python

# For argument parsing
from sys import argv
import argparse

# For Kanade
import torch
import soundfile as sf
from kanade_tokenizer import KanadeModel, load_audio, load_vocoder, vocode

# Argument Parsing
parser = argparse.ArgumentParser(description='Kanade commandline plugin for novel2audiobook.sh')
parser.add_argument('-i','--in', help='Where to find the input audio file', required=False, default='in.wav', dest='infile')
parser.add_argument('-o','--out', help='Where to put the output audio file', required=False, default='out.wav', dest='outfile')
parser.add_argument('-p','--prompt', help='The audio prompt for Kanade to mimic', required=True, dest='promptfile')
parser.add_argument('-m','--model', help='The model to use for voice conversion', required=False, default='frothywater/kanade-25hz-clean', dest='vcmodel')
args = parser.parse_args()
print(args)
infile=args.infile
outfile=args.outfile
promptfile=args.promptfile
vcmodel=args.vcmodel


# Much of this is copy and paste from https://github.com/Ashish-Patnaik/kokoclone/blob/main/core/cloner.py
# Therefore, this file should probably be licensed Apache 2.0
# Setup and run Kanade 
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# Load Kanade model
model = KanadeModel.from_pretrained(vcmodel).to(device).eval()
vocoder = load_vocoder(model.config.vocoder_name).to(device)
sample_rate = model.config.sample_rate

# Load source from infile and reference audio from promptfile
source_wav = load_audio(infile, sample_rate=sample_rate).to(device)
ref_wav = load_audio(promptfile, sample_rate=sample_rate).to(device)

# Do the voice conversaion
converted_mel = model.voice_conversion(source_waveform=source_wav, reference_waveform=ref_wav)
converted_wav = vocode(vocoder, converted_mel.unsqueeze(0))


sf.write(outfile, converted_wav.squeeze().cpu().numpy(), sample_rate)
