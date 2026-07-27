
# NOTE: This file MUST be called with the config file already required!
# If you fail to do that, it won't be able to find the ruby script used to invoke VoxCPM!

#  _________________________
# /                         \
# |  Ruby Library Requires  |
# \_________________________/
# We'll need a temporary directory
require "tmpdir"



#  __________________
# /                  \
# |  Local Requires  |
# \__________________/
# We'll be using Harvard lines for the text to read
require "#{File.absolute_path(File.dirname(__FILE__))}/harvard.rb"
# The machinery of the Voice class will make things easier
require "#{File.absolute_path(File.dirname(__FILE__))}/voice.rb"
# We'll need the UI for user review of audio
require "#{File.absolute_path(File.dirname(__FILE__))}/ui.rb"



#  _____________________
# /                     \
# |  Emotion Constants  |
# \_____________________/
VOX_ANGER="Very intense anger and fast pacing"              # Can be self-fed
VOX_CALM="Relaxed, calm and slow pacing"
VOX_CONFUSED="Very intense confusion"
VOX_CRYING="Very intense despair"
VOX_ENTHUSED="Very intense enthusiasm"
VOX_EXCITED="Very intense excitement and fast pacing"
VOX_FRUSTRATED="Very intense frustration"
VOX_HAPPY="Cheerful, warm and happy"
VOX_MENACE="Very intense anger, slow pacing and low pitch"
VOX_NEUTRAL=""                                              # Intentionally left empty
VOX_SAD="Very intense sadness and slow pacing"
VOX_SCARED="Very intense fear and fast pacing"              # Can be self-fed
#VOX_SHOUT="Very intense yelling and fast pacing"            # Old shout prompt, not very reliable
#VOX_SHOUT="Very intense screaming and fast pacing"          # This seems to work better, but is still unreiable
# Just a little note: that ":3.0" on the end if the CFG weight to go with this emotion, to get VoxCPM to vary less
#   Since thta seems to help with shout lines
VOX_SHOUT="Very intense screaming, high crackle, very intense voice projection and fast pacing:3.0"
VOX_SURPRISED="Very intense surprise and shock, fast pacing"
VOX_TIRED="Very intensely tired and slow pacing"
VOX_WHISPER="Whispering, micro-pauses, close to microphone, low breathy pitch and slow pacing"
VOX_WORRIED="Very intensely worried"



#  ________________
# /                \
# |  Emotion Hash  |
# \________________/
# Maps emotion names to the above emotion constants
VOX_EMOTION={}
VOX_EMOTION["anger"] = VOX_ANGER
VOX_EMOTION["angry"] = VOX_ANGER
VOX_EMOTION["enraged"] = VOX_ANGER
VOX_EMOTION["rage"] = VOX_ANGER
VOX_EMOTION["calm"] = VOX_CALM
VOX_EMOTION["confused"] = VOX_CONFUSED
VOX_EMOTION["crying"] = VOX_CRYING
VOX_EMOTION["enthused"] = VOX_ENTHUSED
VOX_EMOTION["enthusiasm"] = VOX_ENTHUSED
VOX_EMOTION["enthusiastic"] = VOX_ENTHUSED
VOX_EMOTION["excited"] = VOX_EXCITED
VOX_EMOTION["excitment"] = VOX_EXCITED
VOX_EMOTION["frustrated"] = VOX_FRUSTRATED
VOX_EMOTION["frustration"] = VOX_FRUSTRATED
VOX_EMOTION["happy"] = VOX_HAPPY
VOX_EMOTION["menace"] = VOX_MENACE
VOX_EMOTION["neutral"] = VOX_NEUTRAL
VOX_EMOTION["normal"] = VOX_NEUTRAL
VOX_EMOTION["sad"] = VOX_SAD
VOX_EMOTION["afraid"] = VOX_SCARED
VOX_EMOTION["scared"] = VOX_SCARED
VOX_EMOTION["shout"] = VOX_SHOUT
VOX_EMOTION["surprise"] = VOX_SURPRISED
VOX_EMOTION["surprised"] = VOX_SURPRISED
VOX_EMOTION["tired"] = VOX_TIRED
VOX_EMOTION["whisper"] = VOX_WHISPER
VOX_EMOTION["whispering"] = VOX_WHISPER
VOX_EMOTION["worried"] = VOX_WORRIED
VOX_EMOTION["worry"] = VOX_WORRIED



#  ___________________________
# /                           \
# |  Emotion Utility Methods  |
# \___________________________/
def vox_emotion(clone_audio, emotion, line_count: 3,
        tts_output: nil, vc_output: nil, enhance_output: nil,
        review_tts: true, review_vc: false, review_enhance: false)
    emotion_prompt = VOX_EMOTION[String(emotion)]
    if emotion_prompt == nil
        raise "Unknown emotion: \"#{emotion}\""
    end
    
    if not File.exist?(clone_audio)
        raise "Audio file to clone doesn't exist: \"#{clone_audio}\""
    end
    
    # No output files were requested, which is strange, but we can in that case at least not waste time
    if tts_output == nil and vc_output == nil and enhance_output == nil
        # Indicate that no work was performed
        return false
    end
    
    # Prepare the voice we'll use to read, using some very default and basic assumptions
    voice = Voice.new("#{SCRIPT["tts-vox"]}", speaker: "#{clone_audio}:#{emotion_prompt}",
            pronunciation_command: "#{SCRIPT["pronounce"]} vox",
            vc_command: SCRIPT["ehhance-resemble-denoise"], enhance_command: SCRIPT["enhance-lavasr-denoise"])
    
    puts "Generating emotion \"#{emotion}\" for voice \"#{clone_audio}\""
    
    tts_message = "\nCloning: #{clone_audio}\nEmotion: #{emotion} (tts)"
    vc_message = "\nCloning: #{clone_audio}\nEmotion: #{emotion} (filter)"
    enhance_message = "\nCloning: #{clone_audio}\nEmotion: #{emotion} (enhance)"
    backtitle = "\"#{clone_audio}\": #{emotion}"
    
    #puts "Reading with emotion \"#{emotion}\" as \"#{clone_audio}\""
    worked = false
    if say_missing(voice, tts_output, review: review_tts, review_message: tts_message, review_backtitle: backtitle)
        worked = true
    else
        puts "    Skipped TTS: File already exists!"
    end
    unless vc_output == nil
        if vc_missing(voice, tts_output, vc_output, review: review_vc, review_message: vc_message, review_backtitle: backtitle)
            worked = true
        else
            puts "    Skipped Filter: File up to date!"
        end
    end
    unless enhance_output == nil
        if enhance_missing(voice, tts_output, vc_output, enhance_output, review: review_enhance, review_message: enhance_message, review_backtitle: backtitle)
            worked = true
        else
            puts "    Skipped Enhance: File up to date!"
        end
    end
    
    # Indicate some work was successfully performed
    return worked
end

def emotion_filename(prefix, emotion)
    if prefix == nil
        return nil
    end
    ext = setting("audio.ext", "flac")
    return "#{prefix}#{emotion}.#{ext}"
end

def vox_emotion_prefixed(clone_audio, emotion,
        tts_prefix: nil, vc_prefix: nil, enhance_prefix: nil,
        review_tts: true, review_vc: false, review_enhance: false)
    
    # FIX ME: Check for existing files and skip generating them if they're already there
    # That allows interative testing to check result, delete undesired results, then generate again
    # If one has no desire to babysit the program for the review process
    
    tts_file = emotion_filename(tts_prefix, emotion)
    vc_file = emotion_filename(vc_prefix, emotion)
    enhance_file = emotion_filename(enhance_prefix, emotion)
    
    
    return vox_emotion(clone_audio, emotion,
            tts_output: tts_file, vc_output: vc_file, enhance_output: enhance_file,
            review_tts: review_tts, review_vc: review_vc, review_enhance: review_enhance)
end

def vox_emotion_multi(clone_audio,
        tts_prefix: nil, vc_prefix: nil, enhance_prefix: nil,
        review_tts: false, review_vc: false, review_enhance: false,
        emotions: ["neutral", "anger", "calm", "confused", "crying", "enthused", "excited", "frustrsated", "happy",
                "menace", "sad", "scared", "shout", "surprised", "tired", "whisper", "worried"])
    
    if not File.exist?(clone_audio)
        raise "Audio file to clone doesn't exist: \"#{clone_audio}\""
    end
    
    if emotions == nil or (not emotions.is_a?(Array))
        raise "emotions MUST be an Array!"
    end
    
    # No output files were requested, which is strange, but we can in that case at least not waste time
    if tts_prefix == nil and vc_prefix == nil and enhance_prefix == nil
        # Indicate that no work was performed
        return false
    end
    
    worked = false
    while emotions.length > 0
        emotion = emotions.shift
        if vox_emotion_prefixed(clone_audio, emotion, tts_prefix: tts_prefix, vc_prefix: vc_prefix, enhance_prefix: enhance_prefix,
                review_tts: review_tts, review_vc: review_vc, review_enhance: review_enhance)
            worked = true
        end
    end
    
    return worked
end

