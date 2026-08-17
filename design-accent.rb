#!/usr/bin/env ruby

# This script tricks Pocket-TTS into imparting a foreign accent to a cloned voice
# The result can then be cloned to produce a softer, more understandable version of it

# TTS engine enable flags, for Pocket-TTS only
ENABLE_POCKET = true

# We need all the common data and functions from this file and those it requires
require "#{File.dirname(__FILE__)}/common.rb"

# Giving the user a little feedback would be helpful
SETTINGS["voice.say.info"] = true
SETTINGS["voice.vc.info"] = true
SETTINGS["voice.enhance.info"] = true
# Avoid generating and saving a safetensors file for each accent used, since this is not meant to be done repeatedly
SETTINGS["tts.pocket.use_tensors"] = false

# Default settings
source = "pocket"
speaker = nil
language = nil
out_file = nil

# Process command-line switches
while ARGV.length > 0
    arg=ARGV.shift
    if arg == "-s" or arg == "--speaker"
        speaker=ARGV.shift
        if speaker == nil or speaker == ""
            raise "Missing argument for '--speaker' switch!"
        end
    elsif arg == "-l" or arg == "--lang"
        language=ARGV.shift
        if language == nil or language == ""
            raise "Missing argument for '--lang' switch!"
        end
    elsif arg == "-o" or arg == "--out"
        out_file=ARGV.shift
        if out_file == nil or out_file == ""
            raise "Missing file argument for '--out' switch!"
        end
    elsif arg == "-h" or arg == "--help"
        puts "Usage: #{File.basename(__FILE__)} [OPTIONS]"
        puts ""
        puts "    Uses Pocket-TTS to impart a foreign accent to a cloned voice, producing a rather thick variation of it.  The resulting audio clip can then be cloned again, to produce a softer version of the same accent.  However, some post-processing for noise removal may be required, since some of the language models Pocket uses are noisier than the English model, especially the 24l variations."
        puts ""
        puts "    -s --speaker SPEAKER   The speaker data for Pocket-TTS to use (REQUIRED)"
        puts "    -o --out AUDIOFILE     The destination for the output audio file (REQUIRED)"
        puts "    -l --lang LANGUAGE     The Pocket-TTS language to supply an accent"
        puts "    -h --help              Display this help message"
        puts ""
        exit
    # Fail with a non-zero exit code for unexpected switches
    else
        raise "Unknown option or parameter: #{arg}"
    end
end

if out_file == nil
    raise "'--out' switch is required!"
end

if speaker == nil
    raise "'--speaker' switch is required!"
end

copy_voice("target", source, speaker: speaker, model: language)

# FIX ME: Allow setting text to read and/or count of Harvard lines
test_voice("target", out_file)

