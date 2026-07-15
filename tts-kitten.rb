#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/KittenML/KittenTTS

require "tmpdir"

$speaker="Rosie"
$length_scale=1.0
$fade_in=0.05
$fade_out=0.05
# Kitten does this well for itself, so no pre-sentence padding is required
$pre_sentence_silence=0.0
# But we do need a little extra padding at the end of sentences
$sentence_silence=0.15
$filters="norm -8"


# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"


# Kitten needs some small adjustments to the text to read
#$text.gsub!(/\n/, " ")

Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    system("#{SAY_COMMAND} --out \"#{audiofile}\" -s \"#{$tempo}\" -m \"#{$model}\" -v \"#{$speaker}\" -t \"#{$text}\" >\"#{logfile}\" 2>&1")
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Kitten failed!"
    end
    
    system("sox \"#{audiofile}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end


