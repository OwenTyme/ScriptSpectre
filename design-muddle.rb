#!/usr/bin/env ruby

# The result of this script should somewhat mix the prosody of input and prompt, but retain the accent of the input voice
# However, the prosody will more heavily lean toward the input voice
# Nonetheless, this is rather effective at making whispered variations of voices
# When combining whispers with emotional voice samples, the results are surprisingly good

# This script requires Chatterbox, Kanade Tokenizer and MioCodec to be installed and configured


require "tmpdir"

# We need config, to get the VC script locations that have been set by the user
require "#{File.dirname(__FILE__)}/config.rb"

# Default settings
source = "pocket"
in_file = nil
prompt_file = nil
out_file = nil
use_kanade = true

filters = "norm -8"

# Process command-line switches
while ARGV.length > 0
    arg=ARGV.shift
    if arg == "-i" or arg == "--in"
        in_file=ARGV.shift
        if in_file == nil or in_file == ""
            raise "Missing file argument for '--in' switch!"
        end
    elsif arg == "-p" or arg == "--prompt"
        prompt_file=ARGV.shift
        if prompt_file == nil or prompt_file == ""
            raise "Missing file argument for '--prompt' switch!"
        end
    elsif arg == "-o" or arg == "--out"
        out_file=ARGV.shift
        if out_file == nil or out_file == ""
            raise "Missing file argument for '--out' switch!"
        end
    elsif arg == "-m" or arg == "--model"
        arg2=ARGV.shift
        if arg2 == nil or arg2 == ""
            raise "Missing argument for '--model' switch!"
        elsif arg2 == "kanade"
            use_kanade = true
        elsif arg2 == "mio" or arg2 == "miocodec"
            use_kanade = false
        else
            raise "Unknown model string: \"#{arg}\""
        end
    elsif arg == "--filters"
        filters=ARGV.join(" ")
        ARGV.clear
    elsif arg == "-h" or arg == "--help"
        puts "Usage: #{File.basename(__FILE__)} [OPTIONS]"
        puts ""
        puts "    Combines input and prompt voices into one, via multiple voice conversion processes, starting with Chatterbox, then finishing with either Kanade Tokenizer or MioCodec, while retaining the accent of the input voice.  The results can be fairly subtle, but this works extremely well for combining whispered samples with those that aren't whispers.  For best results with whispers, the whispered sample should be the prompt voice."
        puts ""
        puts "    -i --in AUDIOFILE      Audio file that supplies the desired accent and some prosody (REQUIRED)"
        puts "    -p --prompt AUDIOFILE  Audio file that supplies the rest of the prosody (REQUIRED)"
        puts "    -o --out AUDIOFILE     The destination for the output audio file (REQUIRED)"
        puts "    -m --model MODEL       This can ber 'kanade' or 'mio'/'miocodec, determining the VC engine used for the final step"
        puts "    --filters              Indicates all arguments that follow are SoX filters applied as the audio is transcoded to the format indicated by file extension from --out switch"
        puts "    -h --help              Display this help message"
        puts ""
        exit
    # Fail with a non-zero exit code for unexpected switches
    else
        raise "Unknown option or parameter: #{arg}"
    end
end

if in_file == nil
    raise "'--in' switch is required!"
end

if prompt_file == nil
    raise "'--prompt' switch is required!"
end

if out_file == nil
    raise "'--out' switch is required!"
end

# Get the commands required to activate the VC engines
vc1 = SCRIPT["vc-chatterbox"]
engine1 = "Chatterbox"
if use_kanade
    vc2 = SCRIPT["vc-kanade"]
    engine2 = "Kanade Tokenizer"
else
    vc2 = SCRIPT["vc-miocodec"]
    engine2 = "MioCodec"
end

Dir.mktmpdir do |temp|
    audio_file="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    
    # Prompt is voice converted to sound like input, via Chatterbox
    system("#{vc1} --in \"#{prompt_file}\" --prompt \"#{in_file}\" --out \"#{audio_file}\" >\"#{logfile}\"")
    unless $?.exitstatus == 0
        raise "VC engine '#{engine1}' failed!"
    end
    
    # Input is voice converted, via Kanade or MioCodec, to sound like the output from the first VC operation
    system("#{vc2} --in \"#{in_file}\" --prompt \"#{audio_file}\" --out \"#{out_file}\" --filters #{filters} >\"#{logfile}\"")
    unless $?.exitstatus == 0
        raise "VC engine '#{engine2}' failed!"
    end
    
end
