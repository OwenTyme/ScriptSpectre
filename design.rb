#!/usr/bin/env ruby

# TTS engine enable flags, for the ones that can handle voice design
ENABLE_PARLER = true
ENABLE_QWEN = true
ENABLE_VOXCPM = true

# We need all the common data and functions from this file and those it requires
require "#{File.dirname(__FILE__)}/common.rb"

# Giving the user a little feedback would be helpful
SETTINGS["voice.say.info"] = true
SETTINGS["voice.vc.info"] = true
SETTINGS["voice.enhance.info"] = true

# Default settings
source = "qwen-design"
seed = nil
description = nil
out_file = nil

# Process command-line switches
while ARGV.length > 0
    arg=ARGV.shift
    if arg == "-e" or arg == "--engine"
        engine=ARGV.shift
        if engine == nil || clone == ""
            raise "Missing argument for '--engine' switch!"
        elsif engine == "parler"
            source = "parler"
        elsif engine == "qwen"
            source = "qwen-design"
        elsif engine == "vox"
            source = "vox"
        end
    elsif arg == "-s" or arg == "--seed"
        seed=ARGV.shift
        if seed == nil or seed == ""
            raise "Argument for '--seed' switch MUST be an integer!"
        else
            seed = Integer(seed)
        end
    elsif arg == "-d" or arg == "--description"
        description=ARGV.shift
        if description == nil
            raise "Missing file argument for '--filter-prefix' switch!"
        end
    elsif arg == "-o" or arg == "--out"
        out_file=ARGV.shift
        if out_file == nil
            raise "Missing file argument for '--out' switch!"
        end
    elsif arg == "-h" or arg == "--help"
        puts "Usage: #{File.basename(__FILE__)} [OPTIONS]"
        puts ""
        puts "    -e --engine ENGINE     The TTS engine to use ('qwen', 'parler' or 'vox', defaults to 'qwen')"
        puts "    -s --seed INTEGER      The seed value to use (ignored by vox)"
        puts "    -d --description DESC  The description of the voice"
        puts "    -o --out AUDIOFILE     The destination for the output audio file (REQUIRED)"
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

speaker = ""
if seed != nil and source != "vox"
    speaker = speaker + "#{seed}"
end
speaker = speaker + ":"
if description != nil
    speaker = speaker + "#{description}"
end

copy_voice("target", source, speaker: speaker)

# FIX ME: Allow setting text to read or count of Harvard lines
test_voice("target", out_file)

