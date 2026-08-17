#!/usr/bin/env ruby

# Generates emotional variations of a voice, via VoxCPM

# This script is in the same directory as common, so this copy and pasted bit is fine
COMMON_DIR=File.absolute_path(File.dirname(__FILE__))
# We need conffig loaded, since we'll be calling user-defined scripts
require "#{COMMON_DIR}/config.rb"
# And this is full of the methods abd data we need
require "#{RUBY_DIR}/emotion-voxcpm.rb"

# Giving the user a little feedback would be helpful
SETTINGS["voice.say.info"] = true
SETTINGS["voice.vc.info"] = true
SETTINGS["voice.enhance.info"] = true

# Flags for standard emotions
anger = true
calm = true
confused = true
crying = true
enthused = true
excited = true
frustrated = true
happy = true
menace = true
neutral = true
sad = true
scared = true
shout = true
surprised = true
tired = true
whisper = true
worried = true

# File-based parameters
clone = nil
tts_prefix = nil
vc_prefix = nil
enhance_prefix = nil

# Review flags
review_tts = false
review_filter = false
review_enhance = false

# Array of custom emotion names
custom = []

# Process command-line switches
while ARGV.length > 0
    arg=ARGV.shift
    if arg == "-c" or arg == "--clone"
        clone=ARGV.shift
        if clone == nil || clone == ""
            raise "Missing file argument for '--clone' switch!"
        end
    elsif arg == "-t" or arg == "--tts-prefix"
        tts_prefix=ARGV.shift
        if tts_prefix == nil or tts_prefix == ""
            raise "Missing file argument for '--tts-prefix' switch!"
        end
    elsif arg == "-f" or arg == "--filter-prefix"
        vc_prefix=ARGV.shift
        if vc_prefix == nil or vc_prefix == ""
            raise "Missing file argument for '--filter-prefix' switch!"
        end
    elsif arg == "-e" or arg == "--enhance-prefix"
        enhance_prefix=ARGV.shift
        if enhance_prefix == nil or enhance_prefix == ""
            raise "Missing file argument for '--enhance-prefix' switch!"
        end
    elsif arg == "-rt" or arg == "--review-tts"
        review_tts = true
    elsif arg == "-rf" or arg == "--review-filter"
        review_vc = true
    elsif arg == "-re" or arg == "--review-enhance"
        review_enhance = true
    elsif arg == "--all"
        anger = (not anger)
        calm = (not calm)
        confused = (not confused)
        crying = (not crying)
        enthused = (not enthused)
        excited = (not excited)
        frustrated = (not frustrated)
        happy = (not happy)
        menace = (not menace)
        neutral = (not neutral)
        sad = (not sad)
        scared = (not scared)
        shout = (not shout)
        surprised = (not surprised)
        tired = (not tired)
        whisper = (not whisper)
        worried = (not worried)
    elsif arg == "--anger"
        anger = (not anger)
    elsif arg == "--calm"
        calm = (not calm)
    elsif arg == "--confused"
        confused = (not confused)
    elsif arg == "--crying"
        crying = (not crying)
    elsif arg == "--enthused"
        enthused = (not enthused)
    elsif arg == "--excited"
        excited = (not excited)
    elsif arg == "--frustrated"
        frustrated = (not frustrated)
    elsif arg == "--happy"
        happy = (not happy)
    elsif arg == "--menace"
        menace = (not menace)
    elsif arg == "--neutral"
        neutral = (not neutral)
    elsif arg == "--sad"
        sad = (not sad)
    elsif arg == "--scared"
        scared = (not scared)
    elsif arg == "--shout"
        shout = (not shout)
    elsif arg == "--surprised"
        surprised = (not surprised)
    elsif arg == "--tired"
        tired = (not tired)
    elsif arg == "--whisper"
        whisper = (not whisper)
    elsif arg == "--worried"
        worried = (not worried)
    elsif arg == "--custom"
        custom_emotion=ARGV.shift
        if not custom_emotion.include?("=")
            raise "Bad custom emotion: \"#{custom_emotion}\"\n    Please use: NAME=DESCRIPTION"
        end
        cut_at = custom_emotion.index("=")
        name = custom_emotion[0, cut_at]
        description = custom_emotion[cut_at + 1, custom_emotion.size]
        unless VOX_EMOTION[name] == nil
            raise "Emotion \"#{name}\" already exists!"
        end
        VOX_EMOTION[name] = description
        custom.push(name)
    elsif arg == "-h" or arg == "--help"
        puts "Usage: #{File.basename(__FILE__)} [OPTIONS]"
        puts ""
        puts "    -c --clone AUDIOFILE       The audio file to use for input (REQUIRED)"
        puts "    -t --tts-prefix PREFIX     The prefix for TTS audio files (REQUIRED)"
        puts "    -f --filter-prefix PREFIX  The prefix for filtered audio files"
        puts "    -e --enhance-prefix PREFIX The prefix for enhanced audio files"
        puts "    -rt --review-tts           Enables manual review of TTS audio files via dialog boxes"
        puts "    -rf --review-filter        Enables manual review of filtered audio files via dialog boxes"
        puts "    -re --review-enhance       Enables manual review of enhanced audio files via dialog boxes"
        puts "    --all                      Toggles all emotions on or off (all are on by default)"
        puts "    --anger                    Toggles emotion 'anger' on or off"
        puts "    --calm                     Toggles emotion 'calm' on or off"
        puts "    --confused                 Toggles emotion 'confused' on or off"
        puts "    --crying                   Toggles emotion 'crying' on or off"
        puts "    --enthused                 Toggles emotion 'enthused' on or off"
        puts "    --excited                  Toggles emotion 'excited' on or off"
        puts "    --frustrated               Toggles emotion 'frustrated' on or off"
        puts "    --happy                    Toggles emotion 'happy' on or off"
        puts "    --menace                   Toggles emotion 'menace' on or off"
        puts "    --neutral                  Toggles emotion 'neutral' on or off"
        puts "    --sad                      Toggles emotion 'sad' on or off"
        puts "    --scared                   Toggles emotion 'scared' on or off"
        puts "    --shout                    Toggles emotion 'shout' on or off"
        puts "    --surprised                Toggles emotion 'surprised' on or off"
        puts "    --tired                    Toggles emotion 'tired' on or off"
        puts "    --whisper                  Toggles emotion 'whisper' on or off"
        puts "    --worried                  Toggles emotion 'worried' on or off"
        puts "    --custom NAME=DESCRIPTION  Adds a custom emotion with the supplied name and description"
        puts "                               Note: Custom emotions can't be toggled"
        puts "    -h --help                  Display this help message"
        puts ""
        exit
    # Fail with a non-zero exit code for unexpected switches
    else
        raise "Unknown option or parameter: #{arg}"
    end
end

# Can't do anything without the clone voice
if clone == nil
    raise "--clone switch is required!"
end

# Also need the TTS prefix, at a bare minimum
if tts_prefix == nil
    raise "--tts-prefix switch is required!"
end

#vox_emotion_multi(clone, tts_prefix: tts_prefix, vc_prefix: vc_prefix, enhance_prefix: enhance_prefix,
#        review_tts: review_tts, review_vc: review_vc, review_enhance: review_enhance,
#        anger: anger, calm: calm, confused: confused, crying: crying, enthused: enthused, excited: excited,
#        frustrated: frustrated, happy: happy, neutral: neutral, sad: sad, scared: scared, shout: shout,
#        surprised: surprised, tired: tired, whisper: whisper, worried: worried,
#        custom_emotions: custom)

# Assemble an array of emotion names, including both standard and custom
emotions = []
if neutral
    emotions.push("neutral")
end
if anger
    emotions.push("anger")
end
if calm
    emotions.push("calm")
end
if confused
    emotions.push("confused")
end
if crying
    emotions.push("crying")
end
if enthused
    emotions.push("enthused")
end
if excited
    emotions.push("excited")
end
if frustrated
    emotions.push("frustrated")
end
if happy
    emotions.push("happy")
end
if menace
    emotions.push("menace")
end
if sad
    emotions.push("sad")
end
if scared
    emotions.push("scared")
end
if shout
    emotions.push("shout")
end
if surprised
    emotions.push("surprised")
end
if tired
    emotions.push("tired")
end
if whisper
    emotions.push("whisper")
end
if worried
    emotions.push("worried")
end
emotions = emotions + custom

vox_emotion_multi(clone,
        tts_prefix: tts_prefix, vc_prefix: vc_prefix, enhance_prefix: enhance_prefix,
        review_tts: review_tts, review_vc: review_vc, review_enhance: review_enhance,
        emotions: emotions)


