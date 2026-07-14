#!/usr/bin/env ruby

# We need a unique name for the ps, pgrep and pkill commands, for the say-selecttion.sh script
#$0 = "say.rb"
#Process.setproctitle("say.rb")
#ProcessCtrl.set_process_name "say.rb"

require "tmpdir"
require "monitor"

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

SETTINGS["voice.say.info"]          = true




# Name of the voice to read with
name = "jenny"

# read in the text and add newlines for sentence ends
text=STDIN.read
text.gsub!(/#{OPEN_QUOTE2}/, "")
text.gsub!(/#{CLOSE_QUOTE2}/, "")
text.gsub!(/\.[ \t]+/, ".\n")
text.gsub!(/\![ \t]+/, "!\n")
text.gsub!(/\?[ \t]+/, "?\n")


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

