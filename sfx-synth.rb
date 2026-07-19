#!/usr/bin/env ruby

require "tmpdir"


$model="-b 16 -c 1 -r 48000"
$speaker=""
$length_scale=1.0
$fade_in=0.0
$fade_out=0.0
$pre_sentence_silence=0.0
$sentence_silence=0.0
$filters="norm -8"

# Signal that this script has no interest in reading text
# This script ignores the input text, because that's only there to be read by a default voice if an error occurs!
$ignore_text = true

# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"


# Speaker format: "SoX synth filters"
#   Colons can be used to prepare sequences of synth operations
sfx_filters=$speaker


# This runs as two SoX calls piped together, to ensure the overall filters function on the entire stream of sound effects
if sfx_filters.include?(":")
    system("sox -n -t raw -e signed-integer #{$model} - #{sfx_filters} |sox -t raw -e signed-integer #{$model} - \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
# However, if there's no need for that, we can directly produce the audio file, without the pipe
else
    system("sox -n #{$model} \"#{$out_file}\" #{sfx_filters} #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
end
unless $? == 0
    raise "SoX output failure on sound effect filter: #{sfx_filters}"
end

