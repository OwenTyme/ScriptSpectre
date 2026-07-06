#!/usr/bin/env ruby

require "tmpdir"


$model=""
$speaker=""
$length_scale=1.0
$fade_in=0.0
$fade_out=0.0
$pre_sentence_silence=0.0
$sentence_silence=0.0
$filters="norm -8"

# Signal that this script has no interest in reading text
$ignore_text = true

# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"


# Speaker format: "AUDIO_FILE"
sfx_audio=$speaker
if sfx_audio == nil || sfx_audio == ""
    raise "Sound effect audio file MUST be specified via speaker!"
end
unless File.file?(sfx_audio)
    raise "Sound effect audio file doesn't exist: \"#{sfx_audio}\""
end

if $debug
    puts "Sound effect file: #{sfx_audio}"
end

# This ignores the input text, because that's only there to be read by a default voice if an error occurs!
system("sox \"#{sfx_audio}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
unless $?.exitstatus == 0
    raise "SoX output failure on sound effect file: #{sfx_audio}"
end

