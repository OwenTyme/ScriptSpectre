#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/OpenBMB/VoxCPM

require "tmpdir"

$speaker=""
$length_scale=1.0
$fade_in=0.1
$fade_out=0.1
$pre_sentence_silence=0.2
$sentence_silence=0.35
$filters="norm -8"


# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"

# Speaker format: "AUDIO_FILE:DESCRIPTION:CFG"
speaker_parts=split_on_delim($speaker, ":", "|")
if speaker_parts.length > 3
    warn "[warning] Too many speaker parameters!"
end
reference_audio=speaker_parts[0]
description=speaker_parts[1]
cfg=speaker_parts[2]

if reference_audio == nil
    reference_audio = ""
end
if reference_audio != ""
    unless File.file?(reference_audio)
        raise "Reference audio file doesn't exist: \"#{reference_audio}\""
    end
end

if description == nil
    description = ""
end

if cfg == nil
    cfg=setting("tts.voxcpm.cfg", 2.0)
end
cfg=Float(cfg)

# VoxCPM needs some small adjustments to the text to read
$text.gsub!(/\n/, " ")
$text.gsub!(/([.!?]) /, "\\1.. ")
$text.gsub!(/([.!?])$/, "\\1..")
$text.gsub!(/\. /,  ". [breath] ")

unless description == ""
    $text="(#{description})#{$text}"
end

if $debug
    puts "Reference Audio: #{reference_audio}"
    puts "Description: #{description}"
    puts "CFG: #{cfg}"
    puts "VoxCPM Text: \"#{$text}\""
end

Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    if reference_audio == ""
        system("#{SAY_COMMAND} design --output \"#{audiofile}\" --text \"#{$text}\" --cfg-value \"#{cfg}\" >\"#{logfile}\" 2>&1")
        unless $?.exitstatus == 0
            warn File.read(logfile)
            raise "VoxCPM voice design failed!"
        end
    else
        system("#{SAY_COMMAND} clone --output \"#{audiofile}\" --reference-audio \"#{reference_audio}\" --text \"#{$text}\" --cfg-value \"#{cfg}\" >\"#{logfile}\" 2>&1")
        unless $?.exitstatus == 0
            warn File.read(logfile)
            raise "VoxCPM voice clone failed!"
        end
    end
    
    system("sox \"#{audiofile}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end


