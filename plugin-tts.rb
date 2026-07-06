#!/usr/bin/env ruby

=begin
Note to TTS engine plugin authors: before requiring this script, set your desired defaults for global variables!

The following variables used can have defaults set:
$model
$out_file
$speaker
$length_scale
$pre_sentence_silence
$sentence_silence
$fade_in
$fade_out
$filters

The following variables are can have defaults set, but DO NOT have command-line switches to set them:


Additionally, the following variables are set by this script, based on the above:
$tempo
$tempo_filter
$fade_filter

Last of all, this script reads from STDIN until EOF and stores it in this variable, after some filtering:
$text

=end

# We'll need some settings from the config file
require "#{File.dirname(__FILE__)}/config.rb"

# Change to true to see debug output
unless defined?($debug)
    $debug=setting("tts.engine.debug", false)
end

# Change to true to see informational output
unless defined?($info)
    $info=setting("tts.engine.info", false)
end

# If this gets set to true, then this script will completely ignore the text to read
# This is primarily for sound effect scripts
unless defined?($ignore_text)
    $ignore_text = false
end

# Silence threshold is used by the silence filter to determine what is and isn't noise
# This is a string for a floating point number for a percentage of max gain
unless defined?($silence_threshold)
    $silence_threshold = 0.01
end
# This can't be nil!
if $silence_threshold == nil
    $silence_threshold = 0.01
end


# Setup for the number of digits after the decimal to drop for tempo and fade length
# Three digits is probably sufficient for tempo
if $tempo_digits == nil
    $tempo_digits=3
end

if $debug
    puts ARGV.join(" ")
end

def split_on_delim(str, delim, marker)
    unless delim.is_a?(String)
        raise "delim MUST be a String!"
    end
    unless marker.is_a?(String) and marker.length == 1
        raise "marker MUST be a single character String!"
    end
    if str.index(marker) != nil
        raise "str contains marker!"
    end
    # Add the marker string around the delimiter, then split on it
    params=$speaker.gsub(delim, "#{marker}#{delim}#{marker}").split(delim)
    # Remove the marker character from all Strings of the array
    params.each do |param|
        param.gsub!(marker, "")
    end
    # We're done, so return it
    return params
end

plugin_name=ARGV.shift
if plugin_name == nil
    raise "\n    No arguments, indicating a bad call to #{__FILE__}!\n    First parameter is meant to be the basename of the TTS engine's script!"
end

# Set SAY_COMMAND
engine=plugin_name.chomp(File.extname(plugin_name))
engine.delete_prefix!("tts-")
SAY_COMMAND=SAY_COMMANDS[engine]

while ARGV.length > 0
    arg=ARGV.shift
    if arg == "-m" or arg == "--model"
        $model=ARGV.shift
        # This one is unique, in that an empty String is allowed, to accompdate engines that don't use a model
        if $model == nil
            raise "Missing file argument for '--model' switch!"
        end
    elsif arg == "-o" or arg == "--out"
        $out_file=ARGV.shift
        if $out_file == nil or $out_file == ""
            raise "Missing file argument for '--out' switch!"
        end
    elsif arg == "-s" or arg == "--speaker"
        $speaker=ARGV.shift
        if $speaker == nil
            raise "Missing file argument for '--speaker' switch!"
        end
    elsif arg == "--length_scale" or arg == "--length-scale"
        $length_scale=Float(ARGV.shift)
        if $length_scale == nil or $length_scale == ""
            raise "Missing file argument for '--length_scale' switch!"
        end
        if $length_scale <= 0.0
            raise "Length scale can't be zero or less!"
        end
    elsif arg == "--pre_sentence_silence" or arg == "--pre-sentence-silence"
        $pre_sentence_silence=Float(ARGV.shift)
        if $pre_sentence_silence == nil or $pre_sentence_silence == ""
            raise "Missing argument for '--pre_sentence_silence' switch!"
        end
        if $pre_sentence_silence < 0.0
            raise "Pre-sentence silence can't be less than zero!"
        end
    elsif arg == "--sentence_silence" or arg == "--sentence-silence"
        $sentence_silence=Float(ARGV.shift)
        if $sentence_silence == nil or $sentence_silence == ""
            raise "Missing argument for '--sentence_silence' switch!"
        end
        if $sentence_silence < 0.0
            raise "Sentence silence can't be less than zero!"
        end
    elsif arg == "-fi" or arg == "--fade-in" or arg == "--fade_in" or arg == "--fadein"
        $fade_in=Float(ARGV.shift)
        if $fade_in == nil or $fade_in == ""
            raise "Missing argument for '--fade-in' switch!"
        end
        if $fade_in < 0.0
            $fade_in = 0.0
        end
    elsif arg == "-fo" or arg == "--fade-out" or arg == "--fade_out" or arg == "--fadeout"
        $fade_out=Float(ARGV.shift)
        if $fade_out == nil or $fade_out == ""
            raise "Missing argument for '--fade-out' switch!"
        end
        if $fade_out < 0.0
            $fade_out = 0.0
        end
    elsif arg == "--filters"
        $filters=ARGV.join(" ")
        ARGV.clear
    elsif arg == "-h" or arg == "--help"
        puts "Usage: #{plugin_name} [OPTIONS] --out OUTFILE"
        puts ""
        puts "Reads from stdin and calls a TTS engine to produce an audio version of it.  Not every TTS engine script supports every switch and when they do, the details of how are often specific to that engine."
        puts ""
        puts "    -m --model FILE     TTS model (engine-specific)"
        puts "    -s --speaker SPEAK  TTS speaker data (engine-specific)"
        puts "    -o --out FILE       Output audio file name (REQUIRED)"
        puts "    --length_scale      Stretch length of audio by this factor"
        puts "    --pre_sentence_silence FLOAT"
        puts "                        Length of silence, in seconds, at start of sentences (may be ignored)"
        puts "    --sentence_silence FLOAT"
        puts "                        Length of silence, in seconds, at end of sentences (may be ignored)"
        puts "    -fi --fade-in --fadein FLOAT"
        puts "                        Apply a fade in to audio output of FLOAT seconds"
        puts "    -fo --fade-out --fadeout FLOAT"
        puts "                        Apply a fade out to audio output of FLOAT seconds"
        puts "    --filters           Indicates all arguments that follow are SoX filters applied as the audio is transcoded to the format indicated by file extension from --out switch"
        exit
    # Fail with a non-zero exit code for unexpected switches
    else
        raise "Unknown option or parameter: #{arg}"
    end
end

if $out_file == nil
    raise "'--out' switch is required!"
end

# Now we're on to error checks and setting up defaults for unset variables
# We can't error-check $model or $speaker, because they're but engine-specific, so we'll do nothing with them

# We don't want to throw a nil at SoX, but nil should indicate no filters!
if $filters == nil
    # Which requires only an empty string
    filters=""
end

# Pre-sentence silence doesn't make sense as nil or less than zero, so zero it for those cases
#   Less than zero is an error, but not an important one
if $pre_sentence_silence == nil or $pre_sentence_silence < 0.0
    $pre_sentence_silence = 0.0
end
# Sentence silence doesn't make sense as nil or less than zero, so zero it for those cases
#   Less than zero is an error, but not an important one
if $sentence_silence == nil or $sentence_silence < 0.0
    $sentence_silence = 0.0
end
# Prepare the pad filter for SoX
if $pre_sentence_silence == 0.0 and $sentence_silence == 0.0
    $pad_filter=""
    $silence_filter=""
else
    $pad_filter="pad #{$pre_sentence_silence} #{$sentence_silence}"
    # The basic idea of this filter is to trim silence down to a precise sentence pauses
    #   This does trim silence from start and end, but if followed by the pad filter, then the pauses are guaranteed to be a particular length
    #   On the other hand, this may lead to making voices too uniform, so it's a trade-off
    #   It might be worth it for a TTS engine with terribly unreliable sentence pauses
    $silence_filter="silence -l 1 0.1 #{$silence_threshold}% -1 #{$pre_sentence_silence + $sentence_silence} #{$silence_threshold} reverse silence 1 0.1 #{$silence_threshold} reverse"
end

# If this is still nil, then the calling script didn't set it, so 1.0 is a good default
if $length_scale == nil
    $length_scale = 1.0
# On the other hand, if they set it to zero or less, they should be told they made a mistake
elsif $length_scale <= 0.0
    raise "Length scale can't be zero or less!"
end

# Tempo is the inverse of length scale and is used with SoX to alter the speed of engines that don't support that
$tempo=(1.0/$length_scale).truncate($tempo_digits)
if $tempo == 1.0
    $tempo_filter=""
else
    $tempo_filter="tempo -s #{$tempo}"
end
# For fade length, we can reasonably replace nil and less than zero with zero
if $fade_in == nil or $fade_in < 0.0
    $fade_in=0.0
end
if $fade_out == nil or $fade_out < 0.0
    $fade_out=0.0
end
# And use the final result to prepare a SoX filter for the fade
if $fade_in == 0.0 and $fade_out == 0.0
    $fade_filter=""
else
    $fade_filter="fade #{$fade_in} -0 #{$fade_out}"
end

if $ignore_text
    $text = ""
else
    # Read STDIN to EOF, then adjust the text a bit
    $text=STDIN.read
    # Make some small adjustments to avoid confusing the TTS engine
    # Remove leading and trailing whitespace, because they cause some TTS engines to babble
    $text.gsub!(/^[ \t]*/, "")
    $text.gsub!(/[ \t]*$/, "")
    # Blank line removal
    $text.gsub!(/^\n/, "")
    # Trailing newline removal
    $text.delete_suffix!("\n")
end

# Little debugger for this file
#   Make it true to run
if $debug
    puts "\"#{plugin_name}\" reading to \"#{$out_file}\""
    puts "model: \"#{$model}\", speaker: \"#{$speaker}\""
    puts "length_scale: #{$length_scale}, tempo: #{$tempo}, tempo_filter: \"#{$tempo_filter}\""
    puts "fade_in: #{$fade_in}, fade_out: #{$fade_out}, fade_filter: \"#{$fade_filter}\""
    puts "silence_filter: #{$silence_filter}"
    puts "pre_sentence_silence: #{$pre_sentence_silence}, sentence_silence: #{$sentence_silence}, pad_filter: \"#{$pad_filter}\""
    puts "SoX filters: \"#{$filters}\""
end

unless $ignore_text
    if $info
        puts "text: \"#{$text}\""
    end
end

# If there's literally no text to read, just exit
unless $ignore_text
    if $text == ""
        exit
    end
end


