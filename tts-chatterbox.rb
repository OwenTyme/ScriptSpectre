#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/resemble-ai/chatterbox

require "tmpdir"

$speaker=""
$length_scale=1.0
$fade_in=0.1
$fade_out=0.1
$pre_sentence_silence=0.15
$sentence_silence=0.25
$filters="norm -8"


# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"

# Speaker format: "AUDIO_FILE:CFG:EXAGGERATION:TEMPERATURE"
speaker_parts=split_on_delim($speaker, ":", "|")
if $model == "turbo" or $model == "nano" or $model == "multi"
    if speaker_parts.length > 2
        warn "[warning] Too many speaker parameters!\n\"turbo\" \"nano\" and \"multi\" models use only audio reference and CFG!"
    end    
else
    if speaker_parts.length > 4
        warn "[warning] Too many speaker parameters!"
    end
end
reference_audio=speaker_parts[0]
cfg=speaker_parts[1]
exaggeration=speaker_parts[2]
temperature=speaker_parts[3]

if reference_audio == nil
    reference_audio = ""
end

if cfg == nil
    cfg=setting("tts.chatterbox.cfg", 0.5)
end
cfg=Float(cfg)

if exaggeration == nil
    exaggeration=setting("tts.chatterbox.exaggeration", 0.5)
end
exaggeration=Float(exaggeration)

if temperature == nil
    temperature=setting("tts.chatterbox.temperature", 0.8)
end
temperature=Float(temperature)

# Chatterbox needs some small adjustments to the text to read
$text.gsub!(/\n/, " ")
$text.gsub!(/([.!?]) /, "\\1... ")
$text.gsub!(/([.!?])$/, "\\1...")

if $debug
    puts "Reference Audio: #{reference_audio}"
    puts "CFG: #{cfg}"
    puts "Exaggeration: #{exaggeration}"
    puts "Temperature: #{temperature}"
    puts "Chatterbox Text: \"#{$text}\""
end

Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    system("#{SAY_COMMAND} --out \"#{audiofile}\" -w \"#{cfg}\" -e \"#{exaggeration}\" -T \"#{temperature}\" -m \"#{$model}\" -p \"#{reference_audio}\" -t \"#{$text}\" >\"#{logfile}\" 2>&1")
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Chatterbox failed!"
    end
    
    system("sox \"#{audiofile}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end


