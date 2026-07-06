#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/rhasspy/piper

require "tmpdir"

PIPER_AUDIO="-b 16 -c 1 -e signed-integer -r 22050"

$model="#{File.dirname(__FILE__)}/piper/libritts-high.onnx"
$speaker=0
$length_scale=1.0
$fade_in=0.01
$fade_out=0.01
$pre_sentence_silence=0.2
$sentence_silence=0.35
$filters="norm -8"


# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"


def say_line(text, out_file, log_file)
    system("echo \"#{text}\" |\"#{SAY_COMMAND}\" --output_file - --model \"#{$model}\" --speaker \"#{$speaker}\" --length_scale \"#{$length_scale}\" 2>\"#{log_file}\" |sox - \"#{out_file}\" #{$fade_filter} #{$filters}")
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Piper or SoX filter failure!"
    end
end

Dir.mktmpdir do |temp|
    #audiofile="#{temp}/audiofile.wav"
    log_file="#{temp}/log.txt"
    system("touch #{log_file}")
    
    files = Array.new
    
    line_number = 0
    $text.split("\n").each do |line|
        out_file = temp + "/" + String(line_number).rjust(4, '0') + ".wav"
        # Add a sentence pause to handle the "[period]" lines inserted by the pronunciation script
        #   That works around the fact that some some Piper models say "period" instead of ignoring a sentence-ending period
        if line == "[period]"
            system("sox -n #{PIPER_AUDIO} \"#{out_file}\" trim 0.0 \"#{$sentence_silence}\"")
            if $?.exitstatus != 0
                raise "SoX silence failure!"
            end
        else
            # Add a bit of pre-sentence silence
            system("sox -n #{PIPER_AUDIO} \"#{out_file}\" trim 0.0 \"#{$pre_sentence_silence}\"")
            files.push(out_file)
            # Which forces us to manually push the loop along
            line_number = line_number + 1
            out_file = temp + "/" + String(line_number).rjust(4, '0') + ".wav"
            # Finally, read the line
            say_line(line, out_file, log_file)
        end
        files.push(out_file)
        line_number = line_number + 1
    end
    
    files_string="\"#{files.join("\" \"")}\""
    system("sox #{files_string} \"#{$out_file}\"")
    #system("sox \"#{audiofile}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end


