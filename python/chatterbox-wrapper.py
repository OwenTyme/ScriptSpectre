#!/usr/bin/env python

# For argument parsing
from sys import argv
import argparse

# For Chatterbox
import torchaudio
import torch

# Argument Parsing
parser = argparse.ArgumentParser(description='Chatterbox commandline plugin for novel2audiobook.sh')
parser.add_argument('-m','--model', help='The model for Chatterbox to speak with', required=False, default='regular', dest='model')
parser.add_argument('-o','--out', help='Where to put the resulting audio file', required=False, default='out.wav', dest='outfile')
parser.add_argument('-w','--weight', help='The value of cfg_weight for Chatterbox to use', required=False, default='0.5', dest='weight')
parser.add_argument('-e','--exaggeration', help='The value of exaggeration for Chatterbox to use', required=False, default='0.5', dest='exaggeration')
parser.add_argument('-T','--temp', help='The value of temperature for Chatterbox to use', required=False, default='0.8', dest='temperature')
parser.add_argument('-p','--prompt', help='The audio prompt for Chatterbox to mimic', required=False, default='', dest='promptfile')
parser.add_argument('-t','--text', help='The text to read', required=True, dest='text')
args = parser.parse_args()
print(args)
modelname=args.model
outfile=args.outfile
promptfile=args.promptfile
weight=args.weight
exag=args.exaggeration
temp=args.temperature
text=args.text


# Setup and run Chatterbox 
if torch.cuda.is_available():
    device = "cuda"
elif torch.backends.mps.is_available():
    device = "mps"
else:
    device = "cpu"

if modelname == 'turbo':
    from chatterbox.tts_turbo import ChatterboxTurboTTS
    model = ChatterboxTurboTTS.from_pretrained(device=device)
elif modelname == 'multi':
    # FIX ME: This one needs support for language codes
    from chatterbox.mtl_tts import ChatterboxMultilingualTTS
    model = ChatterboxMultilingualTTS.from_pretrained(device=device)
else:
    from chatterbox.tts import ChatterboxTTS
    model = ChatterboxTTS.from_pretrained(device=device)

if promptfile == '':
    if modelname == 'turbo' or modelname == 'multi':
        wav = model.generate(text, temperature=float(temp))
    else:
        wav = model.generate(text, cfg_weight=float(weight), exaggeration=float(exag), temperature=float(temp))
else:
    if modelname == 'turbo' or modelname == 'multi':
        wav = model.generate(text, audio_prompt_path=promptfile, temperature=float(temp))
    else:
        wav = model.generate(text, audio_prompt_path=promptfile, cfg_weight=float(weight), exaggeration=float(exag), temperature=float(temp))
    wav = model.generate(text, audio_prompt_path=promptfile, cfg_weight=float(weight), exaggeration=float(exag), temperature=float(temp))

# FIX ME: I should fix this to stream the data via stdout, to avoid using temporary files
# Sadly, I don't have the slightest clue how to do that, because I don't know python very well
# As it was, just doing argument parsing was fairly difficult for me
torchaudio.save(outfile, wav, model.sr)

