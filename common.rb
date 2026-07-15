#!/usr/bin/env ruby

#  ____________________
# /                    \
# |  Global Constants  |
# \____________________/
# Directories used to find other files
COMMON_DIR=File.absolute_path(File.dirname(__FILE__))

# Feature flags require special handling, because the calling script is allowed to set them before calling this one
#   That allows disabling features of this script by setting some of these to false!

# Flags to enable default voices for each TTS engine
#   Each is disabled by default, to allow enabling only the bare minimum of functionality
if not defined?(ENABLE_CHATTERBOX)
    ENABLE_CHATTERBOX = false
end
if not defined?(ENABLE_KITTEN)
    ENABLE_KITTEN = false
end
if not defined?(ENABLE_PARLER)
    ENABLE_PARLER = false
end
if not defined?(ENABLE_PIPER)
    ENABLE_PIPER = false
end
if not defined?(ENABLE_POCKET)
    ENABLE_POCKET = false
end
if not defined?(ENABLE_QWEN)
    ENABLE_QWEN = false
end
if not defined?(ENABLE_VOXCPM)
    ENABLE_VOXCPM = false
end

# Flags to enable individual models
#   These are enabled by default
if not defined?(ENABLE_KITTEN_NANO)
    ENABLE_KITTEN_NANO = true
end
if not defined?(ENABLE_KITTEN_MICRO)
    ENABLE_KITTEN_MICRO = true
end
if not defined?(ENABLE_KITTEN_MINI)
    ENABLE_KITTEN_MINI = true
end
if not defined?(ENABLE_PARLER_JENNY)
    ENABLE_PARLER_JENNY = true
end
if not defined?(ENABLE_PIPER_JENNY)
    ENABLE_PIPER_JENNY = true
end
if not defined?(ENABLE_PIPER_LIBRITTS)
    ENABLE_PIPER_LIBRITTS = true
end




#  _______________________
# /                       \
# |  Require Config Data  |
# \_______________________/
# Main config file, which holds global settings intended to be configured by the end user
require "#{COMMON_DIR}/config.rb"



#  __________________________
# /                          \
# |  Heavy-Lifting Requires  |
# \__________________________/
# Some little utility methods to mimic shell scripts
require "#{RUBY_DIR}/util.rb"
# And this relates only to the Vox-CPM TTS engine, including data for some tested emotional descriptions
if ENABLE_VOXCPM
    require "#{RUBY_DIR}/emotion-voxcpm.rb"
end
# Voice and VoiceLine classes, plus related methods
require "#{RUBY_DIR}/voice.rb"
# Methods for preparing final data for reading and the actual reading, going from audiobook script to finalized audio
require "#{RUBY_DIR}/audiobook.rb"



#  ______________________
# /                      \
# |  Common Voice Setup  |
# \______________________/
# Sound Effects voices
VOICES["sfx-file"]              = Voice.new("#{SCRIPT["sfx-file"]}",        sound_effect: true, pronunciation_command: nil, enhance_command: "")
VOICES["sfx-synth"]             = Voice.new("#{SCRIPT["sfx-synth"]}",       sound_effect: true, pronunciation_command: nil, enhance_command: "")
# Silence needs no normalization on the enhancement step, which can produce unexpected bursts of noise!
VOICES["sfx-silence"]           = Voice.new("#{SCRIPT["sfx-synth"]}",       sound_effect: true, pronunciation_command: nil, enhance_command: "", post_filters: nil)
#   These four are REQUIRED for full audio script to audio rendering!
#   Silent effects to create pauses in audio corresponding to script directions
#   Can be replaced with actual sound effects, if desired, to audibly mark the moment
copy_voice("paragraph_end",     "sfx-silence", speaker: "trim 0.0 #{$pause_paragraph}")
copy_voice("scene_break",       "sfx-silence", speaker: "trim 0.0 #{$pause_scene_break}")
copy_voice("lead_in",           "sfx-silence", speaker: "trim 0.0 #{$pause_lead_in}")
copy_voice("lead_out",          "sfx-silence", speaker: "trim 0.0 #{$pause_lead_out}")



# Chatterbox has three models named models, regular, multi and turbo (not official names, just what the python adapter script expects)
if ENABLE_CHATTERBOX
    # The regular model is English only and capable of producing emotion though altered speaker parameters
    VOICES["chatterbox"]        = Voice.new("#{SCRIPT["tts-chatterbox"]}",  pronunciation_command: "#{SCRIPT["pronounce"]} chatterbox",        model: "regular",                                   speaker: ":0.5:0.5:0.8")
    # The multilingual model supports more languages
    VOICES["chatterbox-multi"]  = Voice.new("#{SCRIPT["tts-chatterbox"]}",  pronunciation_command: "#{SCRIPT["pronounce"]} chatterbox",        model: "multi",                                     speaker: ":0.5")
    # Turbo is the fastest and also supports a small list of paralinguistic tags
    #   The pronunciation script swaps in "[" and ]" for "<" and ">", to avoid conflict with speaker names:
    #   That allows mixing paraliguisting instructions with changes in speaker names
    #   Here's the supported tages: <chuckle> <clear throat> <cough> <gasp> <groan> <laugh> <shush> <sigh> <sniff>
    VOICES["chatterbox-turbo"]  = Voice.new("#{SCRIPT["tts-chatterbox"]}",  pronunciation_command: "#{SCRIPT["pronounce"]} chatterbox",        model: "turbo",                                     speaker: ":0.5")
end

# Kitten had a nano, mnicro and mini models
if ENABLE_KITTEN and ENABLE_KITTEN_NANO
    VOICES["kitten-nano"]       = Voice.new("#{SCRIPT["tts-kitten"]}",      pronunciation_command: "#{SCRIPT["pronounce"]} kitten",            model: "KittenML/kitten-tts-nano-0.8")
    copy_voice("nano-bella",    "kitten-nano",  speaker: "Bella")
    copy_voice("nano-kiki",     "kitten-nano",  speaker: "Kiki")
    copy_voice("nano-luna",     "kitten-nano",  speaker: "Luna")
    copy_voice("nano-rosie",    "kitten-nano",  speaker: "Rosie")
    copy_voice("nano-bruno",    "kitten-nano",  speaker: "Bruno")
    copy_voice("nano-hugo",     "kitten-nano",  speaker: "Hugo")
    copy_voice("nano-jasper",   "kitten-nano",  speaker: "Jasper")
    copy_voice("nano-leo",      "kitten-nano",  speaker: "Leo")
end
if ENABLE_KITTEN and ENABLE_KITTEN_MICRO
    VOICES["kitten-micro"]      = Voice.new("#{SCRIPT["tts-kitten"]}",      pronunciation_command: "#{SCRIPT["pronounce"]} kitten",            model: "KittenML/kitten-tts-micro-0.8")
    copy_voice("micro-bella",   "kitten-micro", speaker: "Bella")
    copy_voice("micro-kiki",    "kitten-micro", speaker: "Kiki")
    copy_voice("micro-luna",    "kitten-micro", speaker: "Luna")
    copy_voice("micro-rosie",   "kitten-micro", speaker: "Rosie")
    copy_voice("micro-bruno",   "kitten-micro", speaker: "Bruno")
    copy_voice("micro-hugo",    "kitten-micro", speaker: "Hugo")
    copy_voice("micro-jasper",  "kitten-micro", speaker: "Jasper")
    copy_voice("micro-leo",     "kitten-micro", speaker: "Leo")
end
if ENABLE_KITTEN and ENABLE_KITTEN_MINI
    VOICES["kitten-mini"]       = Voice.new("#{SCRIPT["tts-kitten"]}",      pronunciation_command: "#{SCRIPT["pronounce"]} kitten",            model: "KittenML/kitten-tts-mini-0.8")
    copy_voice("mini-bella",    "kitten-mini",  speaker: "Bella")
    copy_voice("mini-kiki",     "kitten-mini",  speaker: "Kiki")
    copy_voice("mini-luna",     "kitten-mini",  speaker: "Luna")
    copy_voice("mini-rosie",    "kitten-mini",  speaker: "Rosie")
    copy_voice("mini-bruno",    "kitten-mini",  speaker: "Bruno")
    copy_voice("mini-hugo",     "kitten-mini",  speaker: "Hugo")
    copy_voice("mini-jasper",   "kitten-mini",  speaker: "Jasper")
    copy_voice("mini-leo",      "kitten-mini",  speaker: "Leo")
end


# FIX ME: Add all of the named Parler voices
if ENABLE_PARLER
    VOICES["parler"]            = Voice.new("#{SCRIPT["tts-parler"]}",      pronunciation_command: "#{SCRIPT["pronounce"]} parler",            model: "parler-tts/parler-tts-mini-v1",
                speaker: "Slightly expressive and animated, moderate speed.  The recording is of very high quality, with the speaker's voice sounding clear and very close up.")

end
if ENABLE_PARLER and ENABLE_PARLER_JENNY
    VOICES["jenny2"]                = Voice.new("#{SCRIPT["tts-parler"]}",  pronunciation_command: "#{SCRIPT["pronounce"]} parler",            model: "parler-tts/parler-tts-mini-jenny-30H",
                speaker: "Slightly expressive and animated, moderate speed.  The recording is of very high quality, with the speaker's voice sounding clear and very close up.")
end

# FIX ME: Add all of the voices for Piper moels, which will also need ENABLE_PIPER_ flags of their own!
if ENABLE_PIPER and ENABLE_PIPER_JENNY
    VOICES["jenny"]                 = Voice.new("#{SCRIPT["tts-piper"]}",   pronunciation_command: "#{SCRIPT["pronounce"]} piper jenny",       model: "#{$piper_model_dir}/jenny.onnx",            speaker: "0")
end
if ENABLE_PIPER and ENABLE_PIPER_LIBRITTS
    VOICES["libritts"]          = Voice.new("#{SCRIPT["tts-piper"]}",       pronunciation_command: "#{SCRIPT["pronounce"]} piper libritts",    model: "#{$piper_model_dir}/libritts-high.onnx",    speaker: "0")
end

if ENABLE_POCKET
    VOICES["pocket"]            = Voice.new("#{SCRIPT["tts-pocket"]}",      pronunciation_command: "#{SCRIPT["pronounce"]} pocket")
end
if ENABLE_QWEN
    VOICES["qwen-clone"]        = Voice.new("#{SCRIPT["tts-qwen-clone"]}",  pronunciation_command: "#{SCRIPT["pronounce"]} qwen")
end
if ENABLE_VOXCPM
    VOICES["vox"]               = Voice.new("#{SCRIPT["tts-vox"]}",         pronunciation_command: "#{SCRIPT["pronounce"]} vox")
end


