#!/usr/bin/env python

# For argument parsing
from sys import argv
import argparse

# For Parler-TTS
import torch
from parler_tts import ParlerTTSForConditionalGeneration
from transformers import AutoTokenizer
import soundfile as sf

# For setting the random seed
import random

# Argument Parsing
parser = argparse.ArgumentParser(description='Parler-TTS commandline plugin for novel2audiobook.sh')
parser.add_argument('-o','--out', help='Where to put the resulting audio file', required=False, default='out.wav', dest='outfile')
parser.add_argument('-m','--model', help='The name of the Parler-TTS model to use', required=False, default='parler-tts/parler-tts-mini-v1', dest='modelname')
parser.add_argument('-d','--description', help='The description prompt Parler-TTS parses to produce a voice', required=True, dest='description')
parser.add_argument('-s','--seed', help='The random seed Parler-TTS will use', required=False, default='', dest='seed')
parser.add_argument('-t','--text', help='The text to read', required=True, dest='text')
args = parser.parse_args()
#print(args)
outfile=args.outfile
modelname=args.modelname
description=args.description
seed=args.seed
text=args.text
#print('outfile: ' + outfile)
#print('model: ' + modelname)
#print('description: ' + description)
#print('text: ' + text)

# Set the random seed, if required
if seed != "":
    torch.manual_seed(int(seed, 16))

# Setup and run Parler-TTS
device = "cuda:0" if torch.cuda.is_available() else "cpu"
model = ParlerTTSForConditionalGeneration.from_pretrained(modelname).to(device)
tokenizer = AutoTokenizer.from_pretrained(modelname)
input_ids = tokenizer(description, return_tensors="pt").input_ids.to(device)
prompt_input_ids = tokenizer(text, return_tensors="pt").input_ids.to(device)
generation = model.generate(input_ids=input_ids, prompt_input_ids=prompt_input_ids)
audio_arr = generation.cpu().numpy().squeeze()

# FIX ME: I should fix this to stream the data via stdout, to avoid using temporary files
# Sadly, I don't have the slightest clue how to do that, because I don't know python very well
# As it was, just doing argument parsing was fairly difficult for me
sf.write(outfile, audio_arr, model.config.sampling_rate)

