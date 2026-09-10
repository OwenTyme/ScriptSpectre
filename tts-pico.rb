#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/ihuguet/picotts

require "tmpdir"

$model=""
$speaker=""
$length_scale=1.0
$fade_in=0.05
$fade_out=0.05
$pre_sentence_silence=0.2
$sentence_silence=0.0
$filters="norm -8"


# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"


Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    if $model == ""
        system("#{SAY_COMMAND} --wave \"#{audiofile}\" \"#{$text}\" >\"#{logfile}\" 2>&1")
    else
        system("#{SAY_COMMAND} --lang \"#{$model}\" --wave \"#{audiofile}\" \"#{$text}\" >\"#{logfile}\" 2>&1")
    end
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Pico TTS failed!"
    end
    
    system("sox \"#{audiofile}\" \"#{$out_file}\" #{$tempo_filter} #{$fade_filter} #{$pad_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end


