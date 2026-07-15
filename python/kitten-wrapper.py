#!/usr/bin/env python

# For argument parsing
from sys import argv
import argparse

# For Kitten
from kittentts import KittenTTS
import soundfile as sf

# Argument Parsing
parser = argparse.ArgumentParser(description='Kitten commandline plugin for novel2audiobook.sh')
parser.add_argument('-m','--model', help='The model for Kitten to speak with', required=False, default='KittenML/kitten-tts-nano-0.8', dest='model')
parser.add_argument('-o','--out', help='Where to put the resulting audio file', required=False, default='out.wav', dest='outfile')
parser.add_argument('-s','--speed', help='The value of speed for Kitten to use', required=False, default=1.0, dest='speed')
parser.add_argument('-v','--voice', help='The voice for Kitten to use', required=False, default='Rosie', dest='voice')
parser.add_argument('-t','--text', help='The text to read', required=True, dest='text')
args = parser.parse_args()
print(args)
modelname=args.model
outfile=args.outfile
speed=float(args.speed)
voice=args.voice
text=args.text

# TTS
model = KittenTTS(modelname)
audio = model.generate(text, voice=voice, speed=speed)
sf.write(outfile, audio, 24000)
