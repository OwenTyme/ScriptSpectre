#!/usr/bin/env python

# For argument parsing
from sys import argv
import argparse

# For Chatterbox
import torchaudio
import torch
from chatterbox.vc import ChatterboxVC

# Argument Parsing
parser = argparse.ArgumentParser(description='Chatterbox commandline plugin for novel2audiobook.sh')
parser.add_argument('-i','--in', help='Where to find the input audio file', required=False, default='in.wav', dest='infile')
parser.add_argument('-o','--out', help='Where to put the output audio file', required=False, default='out.wav', dest='outfile')
parser.add_argument('-p','--prompt', help='The audio prompt for Chatterbox to mimic', required=True, dest='promptfile')
args = parser.parse_args()
print(args)
infile=args.infile
outfile=args.outfile
promptfile=args.promptfile


# Setup and run Chatterbox 
if torch.cuda.is_available():
    device = "cuda"
elif torch.backends.mps.is_available():
    device = "mps"
else:
    device = "cpu"
model = ChatterboxVC.from_pretrained(device)
wav = model.generate(
    audio=infile,
    target_voice_path=promptfile,
)

# FIX ME: I should fix this to stream the data via stdout, to avoid using temporary files
# Sadly, I don't have the slightest clue how to do that, because I don't know python very well
# As it was, just doing argument parsing was fairly difficult for me
torchaudio.save(outfile, wav, model.sr)

