#!/usr/bin/env ruby

# We need a unique name for the ps, pgrep and pkill commands, for the say-selecttion.sh script
#$0 = "say.rb"
#Process.setproctitle("say.rb")
#ProcessCtrl.set_process_name "say.rb"

require "tmpdir"

# Shut off all engines, except Piper
ENABLE_CHATTERBOX = false
ENABLE_PARLER = false
ENABLE_PIPER = true
ENABLE_POCKET = false
ENABLE_QWEN = false
ENABLE_VOXCPM = false
# Shut off the other Piper models
ENABLE_PIPER_LIBRITTS = false

# We need all the common data and functions from this file and those it requires
require "#{File.dirname(__FILE__)}/../common.rb"

SETTINGS["voice.say.info"] = true



# Name of the voice to read with
name = "jenny"

# read in the text and add newlines for sentence ends
text=STDIN.read
text.gsub!(/\.[ \t]+/, ".\n")
text.gsub!(/\![ \t]+/, "!\n")
text.gsub!(/\?[ \t]+/, "?\n")


# We need a temporary directory to store the audio files, so we can play them
Dir.mktmpdir do |temp|
    # Avoiding compression will keep things light, so well use wav format
    audiofile="#{temp}/audiofile.wav"
    log_file="#{temp}/log.txt"
    system("touch #{log_file}")
    
    voice = VOICES[name]
    if voice == nil
        raise "Voice '#{name}' not found!"
    end
        
    # FIX ME: This ought to be done in a multi-threaded way, to allow audio to be generated on one thread, while another plays it
    # But I don't know how to do that, just yet
    text.each_line do |line|
        voice.say(line, audiofile)
        system("play -q \"#{audiofile}\"")
        if $?.exitstatus != 0
            raise "Play failure!"
        end
    end
end

