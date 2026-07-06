#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/kyutai-labs/pocket-tts

require "tmpdir"

#FIX ME?: indlude handling for --noise-clamp --eos-threshold and --frames-after-eos switches?

$model=""
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
# Flags
use_tensors=setting("tts.pocket.use_tensors", false)


# Speaker format: "AUDIO_FILE:TEMPERATURE:STEPS"
speaker_parts=split_on_delim($speaker, ":", "|")
if speaker_parts.length > 3
    warn "[warning] Too many speaker parameters!"
end
reference_audio=speaker_parts[0]
temperature=speaker_parts[1]
steps=speaker_parts[2]

if reference_audio == nil
    reference_audio = ""
end
unless File.file?(reference_audio)
    raise "Reference audio file doesn't exist: \"#{reference_audio}\""
end

# Reasonable values are anywhere from zero to about 2
# Above that can introduce robotic glitches, which might be useful for the voice of a broken robot
#   For that, 2.3-2.4 is about right
# Less than zero will produce an error
if temperature == nil
    temperature=setting("tts.pocket.temperature", 0.7)
end
temperature=Float(temperature)

# LSD decode steps
if steps == nil or steps == ""
    steps=setting("tts.pocket.steps", 1)
end
steps=Integer(steps)

# Pocket needs some small adjustments to the text to read
if $text.include?("\n")
    $text.gsub!(/\n/, " ")
    $text.gsub!(/([.!?]) /, "\\1")
    $text.gsub!(/([.!?])$/, "\\1")
end

if $debug
    puts "Reference Audio: #{reference_audio}"
    puts "Temperature: #{temperature}"
    puts "Steps: #{steps}"
#    puts "Pocket Text: \"#{$text}\""
end

Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    audiofile2="#{temp}/audiofile2.wav"
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    if use_tensors
        if $model != ""
            tensorfile = "#{reference_audio.chomp(File.extname(reference_audio))}-#{$model}.safetensors"
        else
            tensorfile = "#{reference_audio.chomp(File.extname(reference_audio))}.safetensors"
        end
        
        unless FileUtils.uptodate?(tensorfile, [reference_audio])
            warn "Pocket: Generating '#{tensorfile}' from '#{reference_audio}'..."
            if $model != ""
                system("#{SAY_COMMAND} export-voice --language \"#{$model}\" \"#{reference_audio}\" \"#{tensorfile}\" >\"#{logfile}\" 2>&1")
            else
                system("#{SAY_COMMAND} export-voice \"#{reference_audio}\" \"#{tensorfile}\" >\"#{logfile}\" 2>&1")
            end
            if $?.exitstatus != 0
                warn File.read(logfile)
                raise "Error generating '#{tensorfile}'!"
            end
        end
        prompt=tensorfile
    else
        prompt=reference_audio
    end
    
    if $model != ""
        system("#{SAY_COMMAND} generate --language \"#{$model}\" --output-path \"#{audiofile}\" --voice \"#{prompt}\" --text \"#{$text}\" --temperature \"#{temperature}\" --lsd-decode-steps \"#{steps}\" >\"#{logfile}\" 2>&1")
    else
        system("#{SAY_COMMAND} generate --output-path \"#{audiofile}\" --voice \"#{prompt}\" --text \"#{$text}\" --temperature \"#{temperature}\" --lsd-decode-steps \"#{steps}\" >\"#{logfile}\" 2>&1")
    end
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Pocket failed!"
    end

    # The need for this waste of processing time irritates me, but for some unknown reason, the files coming out of
    #   Pocket-TTS think they're 10 hours long in their headers, on top of the fact the beginnings and ends are not clean
    #   So we have to re-encode them, just to prevent the fade filter from producing ten hours of silence
    system("sox \"#{audiofile}\" \"#{audiofile2}\" -V1")
    if $?.exitstatus != 0
        raise "SoX silence trim failure!"
    end
    # #{$fade_filter}
    system("sox \"#{audiofile2}\" \"#{$out_file}\" silence 1 0.1 0.01% reverse silence 1 0.1 0.01% reverse #{$pad_filter} #{$tempo_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end

