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
$ignore_text = true

# First argument to plugin-tts is the basename of the calling script 
ARGV.insert(0, File.basename(__FILE__))
# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-tts.rb"


# Speaker format: "SoX synth filters"
#   Colons can be used to prepare sequences of synth operations, but each sequence will need it's own normalization step!
# FIX ME?: Break into individual sequences, based on colons, then insert the proper filters at the end of each piece
sfx_filters=$speaker

# An experiment in implementing the text processing for filtering multiple sequences
# In the end, it's probably better to run each sound effect independently, or pre-generate and store them as audio files
#puts split_on_delim($speaker, ":", "|").join("#{$filters} : ") + " #{$filters}"




# This ignores the input text, because that's only there to be read by a default voice if an error occurs!
system("sox -n #{$model} \"#{$out_file}\" #{sfx_filters} #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
unless $? == 0
    raise "SoX output failure on sound effect filter: #{sfx_filters}"
end

