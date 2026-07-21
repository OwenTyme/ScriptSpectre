#!/usr/bin/env ruby

require "tmpdir"
require "monitor"

# Load the config file first, because we're going to base engine, model and voice selection on it
require "#{File.dirname(__FILE__)}/../config.rb"

# Load settings from config
engine = setting("speak.engine", "")
model = setting("speak.model", "")
voice = setting("speak.speaker", "")
length_scale = setting("speak.length_scale", nil)
filters = setting("speak.filters", nil)

base_voice = ""
speaker = nil

# Shut off all engines, except the one specified by config
if engine == "chatterbox"
    ENABLE_CHATTERBOX = true
    if model == "turbo"
        base_voice = "chatterbox-turbo"
    elsif model == "multi"
        base_voice = "chatterbox-multi"
    else
        base_voice = "chatterbox"
    end
    # Allows for the default Chatterbox voice, when no audio clip is supplied
    if voice != ""
        speaker = voice
    end
elsif engine == "kitten"
    ENABLE_KITTEN = true
    if model == "mini"
        ENABLE_KITTEN_NANO = false
        ENABLE_KITTEN_MICRO = false
        base_voice = "kitten-mini"
    elsif model == "micro"
        ENABLE_KITTEN_NANO = false
        ENABLE_KITTEN_MINI = false
        base_voice = "kitten-micro"
    # Default to nano if unspecified
    else
        ENABLE_KITTEN_MICRO = false
        ENABLE_KITTEN_MINI = false
        base_voice = "kitten-nano"
    end
    speaker = voice
elsif engine == "parler"
    ENABLE_PARLER = true
    # FIX ME: Implement this, once the named voices for Parler are defined
    # Is there even any point, since Parler is so dang slow?
    raise "Parler not implemented!"
elsif engine == "piper"
    ENABLE_PIPER = true
    if model == "jenny"
        ENABLE_PIPER_LIBRITTS = false
        base_voice = "jenny"
    # FIX ME: Add Clean100 model
    # LibriTTS is the default
    else
        ENABLE_PIPER_JENNY = false
        base_voice = "libritts"
    end
    # This is merely the speaker number
    if model != "jenny" and voice != ""
        speaker = voice
    end
elsif engine == "pocket"
    ENABLE_POCKET = true
    base_voice = "pocket"
    speaker = voice
elsif engine == "qwen"
    ENABLE_QWEN = true
    base_voice = "qwen-clone"
    speaker = voice
elsif engine == "voxcpm"
    ENABLE_VOXCPM = true
    base_voice = "vox"
    speaker = voice
else
    raise "No recognized TTS engine specified: \"#{engine}\""
end

# We need all the common data and functions from this file and those it requires
require "#{File.dirname(__FILE__)}/../common.rb"

# Set up the narrator for this process
# since we're speaking aloud, make it louder, like a final file
copy_voice("narrator", base_voice, speaker: speaker, length_scale: length_scale)
# If specified, replace the filter, to avoid wasting time on multiple normalization filters
#   We do it this way, because filters add through copy_voice, rather than replacing existing filters
if filters != nil
    VOICES["narrator"].pre_filters = filters
end
name = "narrator"

# A little information if run from the terminal would be nice
SETTINGS["voice.say.info"] = true

# Read in the text and add newlines for sentence ends
text=STDIN.read
preprocess!(text, curly_replace: false, directives: false)


# Simple concurrent queue
class SyncQueue
    def initialize()
        # The actual queue
        @queue = Array.new
        
        # Has this queue been marked done by the feeding thread?
        @done = false
    
        # Synchronization Monitor
        @lock = Monitor.new
    end
    
    # Marks this SyncQueue as done
    def done()
        @lock.synchronize do
            @done = true
        end
    end
    
    # True if and only if the quene has been marked done and is also empty
    def done?()
        @lock.synchronize do
            if @done and @queue.empty?
                return true
            else
                return false
            end
        end
    end
    
    def push(value)
        if value == nil
            raise "SyncQueue can't hold nil!"
        end
        @lock.synchronize do
            @queue.push(value)
        end
    end
    
    def shift()
        while not done?
            @lock.synchronize do
                value = @queue.shift
                unless value == nil
                    return value
                end
            end
            Thread.pass
        end
        return nil
    end
end



# We need a temporary directory to store the audio files, so we can play them
Dir.mktmpdir do |temp|
    queue = SyncQueue.new
    log_file="#{temp}/log.txt"
    system("touch #{log_file}")
    
    voice = VOICES[name]
    if voice == nil
        raise "Voice '#{name}' not found!"
    end
    
    # Start a thread to fill the queue
    Thread.new() {
        count = 1
        text.each_line do |line|
            # Avoiding compression will keep things light, so well use wav format
            audiofile="#{temp}/audiofile-#{count}.wav"
            voice.say(line, audiofile)
            queue.push(audiofile)
            count = count + 1
        end
        
        queue.done
    }
    
    # And the main thread will play the results
    while not queue.done?
        audiofile = queue.shift
        unless audiofile == nil
            puts "Playing '#{audiofile}'..."
            system("play -q \"#{audiofile}\"")
            if $?.exitstatus != 0
                raise "Play failure!"
            end
        end
        Thread.pass
    end
end

