#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/ServeurpersoCom/qwentts.cpp
# If you're using the python version, you'll have to write a pair of python adapter scripts to run in its place

require "tmpdir"

$model=""
$speaker=""
$length_scale=1.0
$fade_in=0.05
$fade_out=0.05
$pre_sentence_silence=0.2
$sentence_silence=0.35
$filters="norm -8"


# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"
CODEC_COMMAND=SAY_COMMANDS["qwen-codec"]


# Speaker format: "SEED:DESCRIPTION:TEMPERATURE:TOP-K:TOP-P:REPETITION_PENALTY"
speaker_parts=split_on_delim($speaker, ":", "|")
if speaker_parts.length > 6
    warn "[warning] Too many speaker parameters!"
end
seed=speaker_parts[0]
description=speaker_parts[1]
temperature=speaker_parts[2]
top_k=speaker_parts[3]
top_p=speaker_parts[4]
repetition_penalty=speaker_parts[4]

if seed == nil
    seed = ""
end
if seed != ""
    seed = Integer(seed)
end

if description == nil
    description = ""
end

if temperature == nil
    temperature=setting("tts.qwen.temperature", 0.9)
end
temperature=Float(temperature)

if top_k == nil
    top_k=setting("tts.qwen.top_k", 50)
end
top_k=Integer(top_k)

if top_p == nil
    top_p=setting("tts.qwen.top_p", 1.0)
end
top_p=Float(top_p)

if repetition_penalty == nil
    repetition_penalty=setting("tts.qwen.repetition_penalty", 1.05)
end
repetition_penalty=Float(repetition_penalty)


# Qwen needs some small adjustments to the text to read
if $text.include?("\n")
    $text.gsub!(/\n/, " ")
#    $text.gsub!(/([.!?]) /, "\\1")
#    $text.gsub!(/([.!?])$/, "\\1")
end

if $debug
    puts "Seed: #{seed}"
    puts "Description: #{description}"
    puts "Temperature: #{temperature}"
    puts "Top K: #{top_k}"
    puts "Top P: #{top_p}"
    puts "Repetition Penalty: #{repetition_penalty}"
#    puts "Qwen Clone Text: \"#{$text}\""
end

Dir.mktmpdir do |temp|
    # Temp file for holding output before filtering
    audiofile="#{temp}/audiofile.wav"
    # Temp file for wav version of the reference audio, since Qwen won't use anything other than wav files
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    switches = ""
    # Like Pocket, model specifies language, since the Qwen models are specified elsewhere
    if $model != ""
        switches = switches + " --lang \"#{$model}\""
    end
    
    if seed != ""
        switches = switches + " --seed \"#{seed}|\""
    end
    
    # Finally, we can run Qwen to clone the voice
#    puts "echo \"#{$text}\" |#{SAY_COMMAND} #{switches} -o \"#{audiofile}\" --temp \"#{temperature}\" --top-k \"#{top_k}\" --top-p \"#{top_p}\" --rep-pen \"#{repetition_penalty}\" >\"#{logfile}\" 2>&1"
    system("echo \"#{$text}\" |#{SAY_COMMAND} #{switches} --instruct \"#{description}\" -o \"#{audiofile}\" --temp \"#{temperature}\" --top-k \"#{top_k}\" --top-p \"#{top_p}\" --rep-pen \"#{repetition_penalty}\" >\"#{logfile}\" 2>&1")
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Qwen design failed!"
    end
    
    # Convert the resulting audio
    system("sox \"#{audiofile}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end

