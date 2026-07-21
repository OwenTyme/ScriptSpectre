
# NOTE: This file MUST remain self-suffient, because it's required by multiple other scripts, as a source of config data
#   We can't rely on it to be called by any particular script or in any specific order
#   So, DO NOT reference anything external without requiring it first!

#  _____________
# /             \
# |  Constants  |
# \_____________/
# Save the directory of this file, to work relative to it
CONFIG_DIR=File.absolute_path(File.dirname(__FILE__))
# Save the location of the script that was actually run
START_SCRIPT=File.absolute_path(caller.last.gsub(/:.*/, ""))
# Save the directory of the starting script
START_DIR=File.absolute_path(File.dirname(START_SCRIPT))
# A stand-in command to fail with a helpful message, indicating the need to set some configuration values
SCRIPT_FAIL="#{CONFIG_DIR}/script-fail.rb"
# Some constants that can be changed to adjust the data listed below
#   Directory used to hold python scripts, to keep things a little more tidy
PYTHON_DIR="#{CONFIG_DIR}/python"
#   Directory used for non-executable ruby scripts, to keep them out of the way
RUBY_DIR="#{CONFIG_DIR}/ruby"



#  ____________________
# /                    \
# |  General Settings  |
# \____________________/
# FIX ME: Need settings to control line breaking based on sentence or paragraph when processing text for TTS
# Hash of general settings that affect scripts, both in general and in specific cases
SETTINGS={}
# Helper method to access settings, providing a default value if there's no stored value
def setting(key, default)
    if SETTINGS.include?(key)
        return SETTINGS[key]
    else
        return default
    end
end

#   Directory that holds audio files to clone with zero-shot engines
SETTINGS["audio.samples_dir"]       = "#{CONFIG_DIR}/voices"
#   SoX format output switches for final chapter track audio
SETTINGS["audio.format"]            = "-b 16 -c 1 -r 48000"
#   The file extension that should be used for audio files, indirectly setting the format SoX uses
SETTINGS["audio.ext"]               = "flac"

#   Paragraph pause length
SETTINGS["text.pause.paragraph"]    = 0.15
#   Scene break pause length
SETTINGS["text.pause.scene_break"]  = 1.5
#   Track lead in length
SETTINGS["text.pause.lead_in"]      = 1.0
#   Track lead out length
SETTINGS["text.pause.lead_out"]     = 2.0

#   Should informational lines be displayed by TTS engines?
SETTINGS["tts.engine.info"]         = false
#   Should debug lines be displayed by TTS engines?
SETTINGS["tts.engine.debug"]        = false

#   Should informational lines be displayed by Voice.say?
SETTINGS["voice.say.info"]          = false
#   Should debug lines be displayed by Voice.say?
SETTINGS["voice.say.debug"]         = false

#   Should informational lines be displayed by Voice.vc?
SETTINGS["voice.vc.info"]           = false
#   Should debug lines be displayed by Voice.vc?
SETTINGS["voice.vc.debug"]          = false

#   Should informational lines be displayed by Voice.enhance?
SETTINGS["voice.enhance.info"]      = false
#   Should debug lines be displayed by Voice.enhance?
SETTINGS["voice.enhance.debug"]     = false


# Piper settings
#   Directory that holds Piper models
SETTINGS["tts.piper.model_dir"]     = "#{CONFIG_DIR}/piper"

# Chatterbox settings
#   Classifier Free Guidance
SETTINGS["tts.chatterbox.cfg"]      = 0.5
#   Emotional exaggeration
SETTINGS["tts.chatterbox.exaggeration"] = 0.5
#   Temperature controls the variability of the voice
SETTINGS["tts.chatterbox.temperature"] = 0.8

# Pocket TTS settings
#   Should safetensors files be saved beside the reference audio for each voice+model cloned, to accelerate future runs?
SETTINGS["tts.pocket.use_tensors"]  = true
#   Temperature controls the variability of the voice
SETTINGS["tts.pocket.temperature"]  = 0.7
#   LSD Decode steps, an integer value: higher leads to better quality, but lower performance
SETTINGS["tts.pocket.steps"]        = 1

# Qwen TTS settings
#   Should rvq and spk files be saved beside the reference audio for each cloned voice, to accelerate future runs?
#   Enabling it REQUIRES a text file transcript of the reference (full audiofile name, including extenson with .txt on the end)
#   This doesn't seem to work right and I don't know why; it only slows everything down, contrary to all expectation
SETTINGS["tts.qwen.use_codec"]      = false
#   Temperature controls the variability of the voice
SETTINGS["tts.qwen.temperature"]    = 0.9
SETTINGS["tts.qwen.top_k"]          = 50
SETTINGS["tts.qwen.top_p"]          = 1.0
SETTINGS["tts.qwen.repetition_penalty"] = 1.05

# VoxCPM settings
#   Classifier Free Guidance
SETTINGS["tts.voxcpm.cfg"]          = 2.0


# Settings for speaking aloud, at runtime
#   Name of the TTS engine
SETTINGS["speak.engine"]            = ""
#   Name of the model for the TTS engine
SETTINGS["speak.model"]             = ""
#   Name of a specific speaker
SETTINGS["speak.speaker"]           = ""
#   Floating-point value to scale the length of audio by, to adjust speed of speaking
#   Leaving this as nil uses the existing setting for the base voice for the specified engine and model
SETTINGS["speak.length_scale"]      = nil
#   SoX filters for the speaker
SETTINGS["speak.filters"]           = "norm -3.2"



#  _____________________________________________________
# /                                                     \
# |  Pronunciation, TTS, VC and Enhance Plugin Scripts  |
# \_____________________________________________________/
SCRIPT={}
# Pronunciation scripts
#  The default pronunciation command used to preprocess text for TTS engines
SCRIPT["pronounce"]                 = "#{CONFIG_DIR}/pronunciation-main.rb"

# TTS scripts
# Chatterbox is slow, but handles zero shot voice cloning rather well
SCRIPT["tts-chatterbox"]            = "#{CONFIG_DIR}/tts-chatterbox.rb"
# Kitten is fast and sounds decent
SCRIPT["tts-kitten"]                = "#{CONFIG_DIR}/tts-kitten.rb"
# Piper is fast AI, but low quality
SCRIPT["tts-piper"]                 = "#{CONFIG_DIR}/tts-piper.rb"
#  Pocket is the fastest available zero-shot voice cloning engine and works well on CPU
SCRIPT["tts-pocket"]                = "#{CONFIG_DIR}/tts-pocket.rb"
# Parler is slow as a seven year itch and also of quationable quality
#   However, it has a unique feature: you can describe the desired voice, in text
#   That may be of value for producing samples for the zero-shot engines to mimic
SCRIPT["tts-parler"]                = "#{CONFIG_DIR}/tts-parler.rb"
#  Qwen3-tts can also fuction like Parler, but can also clone voices and works well on CPU, though it is slower than Pocket
#   This script handles the voice cloning functionality
SCRIPT["tts-qwen-clone"]            = "#{CONFIG_DIR}/tts-qwen-clone.rb"
#   This script handles the voice design feature (which takes a prompt for a voice desecription in place of an audio reference)
#   This doesn't seem able to take accent requests, always producing an American accent
# FIX ME: Commented out, because it hasn't been implemented yet
#SCRIPT["tts-qwen-design"]           = "#{CONFIG_DIR}/tts-qwen-design.rb"
#  VoxCPM is similar to Parler, but far faster and more flexible, able to handle both accent and emotion requests, on top of voice cloning
SCRIPT["tts-vox"]                   = "#{CONFIG_DIR}/tts-voxcpm.rb"

# Sound effect scripts
SCRIPT["sfx-file"]                  = "#{CONFIG_DIR}/sfx-file.rb"
SCRIPT["sfx-synth"]                 = "#{CONFIG_DIR}/sfx-synth.rb"

# NOTE: Enhance and VC scripts are interchangeable and can be used in place of each other!

# Enhance scripts
#  Resemble Enhance can denoise audio and also upscale to 44.1 Khz
#   This performs just the denoise step
SCRIPT["ehhance-resemble-denoise"]  = "#{CONFIG_DIR}/enhance-resemble-denoise.rb"
#   This also enhances to 44.1 Khz, but every once in a while, this distorts speech
SCRIPT["enhance-resemble"]          = "#{CONFIG_DIR}/enhance-resemble.rb"
#  LavaSR is a 48 Khz upscaler, but can optionally also perform some denoising
#   This performs upscaling only
SCRIPT["enhance-lavasr"]            = "#{CONFIG_DIR}/enhance-lavasr.rb"
#   This adds the denoising step
SCRIPT["enhance-lavasr-denoise"]    = "#{CONFIG_DIR}/enhance-lavasr-denoise.rb"

# VC scripts
# Chatterbox is fairly slow and noisy, but works in a different manner from Kanade and MioCodec, which can sometimes be useful
SCRIPT["vc-chatterbox"]             = "#{CONFIG_DIR}/vc-chatterbox.rb"
#  Kanade Tokenizer is relatively fast and high quality as a voice converter
#   This requires the addition of a --prompt option, for an audio file as a conversion target
SCRIPT["vc-kanade"]                 = "#{CONFIG_DIR}/vc-kanade.rb"
#  MioCodec is a fork of Kanade Tokenizer that isn't as robust at most tasks, but it is faster and handles whispers better
SCRIPT["vc-miocodec"]               = "#{CONFIG_DIR}/vc-miocodec.rb"
#  Kanade Tokenizer can also serve as a resynthesizer, which can analyze an audio clip to determine its ideal characteristics
#   Followed by voice converting the original sample to match that ideal version
#   It can remove reverb, but sometimes fails on simple noise, mistaking it for breath sounds
#   Combined with preprocessing via other noise filters, this can make even badly damaged samples quite clear
#   But only so long as the underlying pronunciation is correct
#   However, it doesn't work very well on whispers, turning them into a raspy mess
SCRIPT["resynth-kanade"]            = "#{CONFIG_DIR}/filter-resynth-kanade.rb"
#  MioCodec can also resynthesize, but handles whispers better
#   On the other hand, it doesn't do quite as well at noise removal
SCRIPT["resynth-miocodec"]          = "#{CONFIG_DIR}/filter-resynth-miocodec.rb"



#  ________________________________________________
# /                                                \
# |  Say Commands for Internal Use of TTS Plugins  |
# \________________________________________________/
# Hash of commands to run TTS engines
SAY_COMMANDS={}
SAY_COMMANDS["chatterbox"]          = "#{SCRIPT_FAIL} Chatterbox command not set!"
SAY_COMMANDS["kitten"]              = "#{SCRIPT_FAIL} Kitten command not set!"
SAY_COMMANDS["parler"]              = "#{SCRIPT_FAIL} Parler command not set!"
SAY_COMMANDS["piper"]               = "#{SCRIPT_FAIL} Piper command not set!"
SAY_COMMANDS["voxcpm"]              = "#{SCRIPT_FAIL} VoxCPM command not set!"
SAY_COMMANDS["pocket"]              = "#{SCRIPT_FAIL} Pocket TTS command not set!"
SAY_COMMANDS["qwen-clone"]          = "#{SCRIPT_FAIL} Qwen TTS clone command not set!"
SAY_COMMANDS["qwen-codec"]          = "#{SCRIPT_FAIL} Qwen TTS codec command not set!"



#  ____________________________________________________________
# /                                                            \
# |  Voice Conversion Commands for Internal Use of VC Plugins  |
# \____________________________________________________________/
# Hash of commands to run VC (voice conversion) engines
VC_COMMANDS={}
VC_COMMANDS["chatterbox"]           = "#{SCRIPT_FAIL} Chatterbox VC command not set!"
VC_COMMANDS["kanade"]               = "#{SCRIPT_FAIL} Kanade VC command not set!"
VC_COMMANDS["miocodec"]             = "#{SCRIPT_FAIL} MioCodec VC command not set!"



#  ______________________________________________________
# /                                                      \
# |  Filter Commands for Internal Use of Filter Plugins  |
# \______________________________________________________/
# Hash of commands to run audio filtering processes
FILTER_COMMANDS={}
FILTER_COMMANDS["resynth-kanade"]  = "#{SCRIPT_FAIL} Kanade Resynth command not set!"
FILTER_COMMANDS["resynth-miocodec"]= "#{SCRIPT_FAIL} MioCodec Resynth command not set!"



#  ________________________________________________________
# /                                                        \
# |  Enhance Commands for Internal Use of Enhance Plugins  |
# \________________________________________________________/
# Hash of commands to run audio enhancement processes
ENHANCE_COMMANDS={}
ENHANCE_COMMANDS["lavasr"]          = "#{SCRIPT_FAIL} LavaSR command not set!"
ENHANCE_COMMANDS["lavasr-denoise"]  = "#{SCRIPT_FAIL} LavaSR Denoise command not set!"
ENHANCE_COMMANDS["resemble"]        = "#{SCRIPT_FAIL} Resemble Enhance command not set!"
ENHANCE_COMMANDS["resemble-denoise"]= "#{SCRIPT_FAIL} Resemble Enhance Denoise command not set!"



#  ____________________
# /                    \
# |  Global Variables  |
# \____________________/
# These following variables are meant to be set by a script that requires this one
# Directory for the markdown chapter cache
$chapter_cache                      = "#{START_DIR}/0-chapters"
# Directory for audio script lines for reading and editing on the fly
$line_cache                         = "#{START_DIR}/1-lines"
# Directory for raw audio files
#   Essentially, this should hold the direct output of the TTS engine(s), with only normalization filtering
$raw_audio_dir                      = "#{START_DIR}/2-raw"
# Directory for filtered audio files produced by utility scripts
#   Holds second stage audio from voice conversion, resynthesis and noise reduction
#   Some voices won't need this, so don't assume files will be created here for every line
$filtered_audio_dir                 = "#{START_DIR}/3-filtered"
# Directory for enhanced audio files
#   Holds final stage audio from enhancement and final effects filtering
$enhanced_audio_dir                 = "#{START_DIR}/4-enhanced"
# Directory for final audio tracks
#   Holds finished audio ready for manual mastering steps
$final_audio_dir                    = "#{START_DIR}/5-tracks"
# Directory for voice tests
$test_audio_dir                     = "#{START_DIR}/test"
# Directory of audio files for voice samples
#   Used for zero-shot voice cloning and voice conversion (VC)
$voice_dir                          = setting("audio.samples_dir", "#{CONFIG_DIR}/voices")
# Directory in which to find piper TTS models
$piper_model_dir                    = setting("tts.piper.model_dir", "#{CONFIG_DIR}/piper")
$pause_paragraph                    = setting("text.pause.paragraph", 0.15)
$pause_scene_break                  = setting("text.pause.scene_break", 1.5)
$pause_lead_in                      = setting("text.pause.lead_in", 1.0)
$pause_lead_out                     = setting("text.pause.lead_out", 2.0)



# Call a script for user-defined settings, if it exists, allowing this file to serve as default values
require "#{CONFIG_DIR}/config-user.rb"
