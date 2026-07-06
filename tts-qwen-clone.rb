#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/ServeurpersoCom/qwentts.cpp
# If you're using the python version, you'll have to write a pair of python adapter scripts to run in its place

require "tmpdir"

$model=""
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
CODEC_COMMAND=SAY_COMMANDS["qwen-codec"]
# Flags
use_codec=setting("tts.qwen.use_codec", false)


# Speaker format: "AUDIO_FILE:TEMPERATURE:TOP-K:TOP-P:REPETITION_PENALTY"
speaker_parts=split_on_delim($speaker, ":", "|")
if speaker_parts.length > 5
    warn "[warning] Too many speaker parameters!"
end
reference_audio=speaker_parts[0]
temperature=speaker_parts[1]
top_k=speaker_parts[2]
top_p=speaker_parts[3]
repetition_penalty=speaker_parts[4]

if reference_audio == nil
    reference_audio = ""
end
unless File.file?(reference_audio)
    raise "Reference audio file doesn't exist: \"#{reference_audio}\""
end

if temperature == nil
    temperature=setting("tts.qwen.temperature", 0.9)
end
temperature=Float(temperature)

if top_k == nil
    top_k=setting("tts.qwen.top_k", 50)
end
top_k=Integer(top_k)

if top_p == nil
    top_p=setting("tts.qwen.top_p", 1.0)
end
top_p=Float(top_p)

if repetition_penalty == nil
    repetition_penalty=setting("tts.qwen.repetition_penalty", 1.05)
end
repetition_penalty=Float(repetition_penalty)


# Qwen needs some small adjustments to the text to read
if $text.include?("\n")
    $text.gsub!(/\n/, " ")
#    $text.gsub!(/([.!?]) /, "\\1")
#    $text.gsub!(/([.!?])$/, "\\1")
end

if $debug
    puts "Reference Audio: #{reference_audio}"
    puts "Temperature: #{temperature}"
    puts "Top K: #{top_k}"
    puts "Top P: #{top_p}"
    puts "Repetition Penalty: #{repetition_penalty}"
#    puts "Qwen Clone Text: \"#{$text}\""
end

Dir.mktmpdir do |temp|
    # Temp file for holding output before filtering
    audiofile="#{temp}/audiofile.wav"
    # Temp file for wav version of the reference audio, since Qwen won't use anything other than wav files
    infile="#{temp}/infile.wav"
    logfile="#{temp}/log.txt"
    system("touch #{logfile}")
    
    
    
    # Process audio to save rvq and spk files to accelerate future runs when cloning the same voice sample
    if use_codec
        rvqfile = "#{reference_audio.chomp(File.extname(reference_audio))}.rvq"
        spkfile = "#{reference_audio.chomp(File.extname(reference_audio))}.spk"
        
        # Update the stored the data if the audio sample is newer
        unless FileUtils.uptodate?(rvqfile, [reference_audio]) and FileUtils.uptodate?(spkfile, [reference_audio])
            # The particular version of Qwen used can't handle anything other than wav files, so transcode
            system("sox \"#{reference_audio}\" \"#{infile}\"")
            if $?.exitstatus != 0
                raise "SoX input failure!"
            end
            warn "Qwen Clone: Generating '#{rvqfile}' and '#{spkfile}' from '#{reference_audio}'..."
                system("#{CODEC_COMMAND} -i \"#{infile}\" >\"#{logfile}\" 2>&1")
            if $?.exitstatus != 0 or (not File.exist?("#{temp}/infile.rvq")) or (not File.exist?("#{temp}/infile.spk"))
                warn File.read(logfile)
                raise "Error generating '#{rvqfile}' and '#{spkfile}'!"
            end
            FileUtils.mv("#{temp}/infile.rvq", rvqfile)
            FileUtils.mv("#{temp}/infile.spk", spkfile)
        end
        
        # Command-line switches to use the rvq and spk files
        switches="--ref-rvq \"#{rvqfile}\" --ref-spk \"#{spkfile}\" --ref-text \"#{reference_audio}.txt\""
    else
        # The particular version of Qwen used can't handle anything other than wav files, so transcode
        system("sox \"#{reference_audio}\" \"#{infile}\"")
        if $?.exitstatus != 0
            raise "SoX input failure!"
        end
        switches="--ref-wav \"#{infile}\""
    end
    
    # Like Pocket, model specifies language, since the Qwen models are specified elsewhere
    if $model != ""
        switches = switches + " --lang \"#{$model}\""
    end
    
    # Finally, we can run Qwen to clone the voice
#    puts "echo \"#{$text}\" |#{SAY_COMMAND} #{switches} -o \"#{audiofile}\" --temp \"#{temperature}\" --top-k \"#{top_k}\" --top-p \"#{top_p}\" --rep-pen \"#{repetition_penalty}\" >\"#{logfile}\" 2>&1"
    system("echo \"#{$text}\" |#{SAY_COMMAND} #{switches} -o \"#{audiofile}\" --temp \"#{temperature}\" --top-k \"#{top_k}\" --top-p \"#{top_p}\" --rep-pen \"#{repetition_penalty}\" >\"#{logfile}\" 2>&1")
    unless $?.exitstatus == 0
        warn File.read(logfile)
        raise "Qwen clone failed!"
    end
    
    # Convert the resulting audio
    system("sox \"#{audiofile}\" \"#{$out_file}\" #{$fade_filter} #{$pad_filter} #{$tempo_filter} #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end

