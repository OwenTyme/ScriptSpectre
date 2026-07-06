#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/huggingface/parler-tts

require "tmpdir"

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

# Speaker format: "SEED:DESCRIPTION" or "DESCRIPTION"
if $speaker.include?(":")
    speaker_parts=split_on_delim($speaker, ":", "|")
    if speaker_parts.length > 2
        warn "[warning] Too many speaker parameters!"
    end
    seed=speaker_parts[0]
    description=speaker_parts[1]
else
    seed=""
    description=$speaker 
end

if seed == nil
    seed = ""
end
# This ensures that seed is either an empty String or a true integer, raising an exception if it isn't
# An empty String indicates the seed is meant to be random
if seed != ""
    seed = Integer(seed)
end

if description == nil
    description = "Slightly expressive and animated, moderate speed.  The recording is of very high quality, with the speaker's voice sounding clear and very close up."
end


# Parler needs some small adjustments to the text to read
$text.gsub!(/\n/, " ")
$text.gsub!(/([.!?]) /, "\\1.. ")
$text.gsub!(/([.!?])$/, "\\1..")
#$text.gsub!(/\. /,  ". [breath] ")

if $debug
    puts "Seed: #{seed}"
    puts "Description: #{description}"
    puts "Parler Text: \"#{$text}\""
end


Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    system("#{SAY_COMMAND} --out \"#{audiofile}\" -m \"#{$model}\" -d \"#{description}\" -s \"#{seed}\" -t \"#{$text}\" >\"#{logfile}\" 2>&1")
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Parler failed!"
    end
    
    system("sox \"#{audiofile}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end


