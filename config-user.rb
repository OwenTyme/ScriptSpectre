
#  _____________
# /             \
# |  Constants  |
# \_____________/
# This is a good place to put constants for directory locations



#  ____________________
# /                    \
# |  General Settings  |
# \____________________/
# These are here for ease of debugging, so you don't have to edit config.rb
SETTINGS["tts.engine.info"]         = false
SETTINGS["tts.engine.debug"]        = false
SETTINGS["voice.say.info"]          = false
SETTINGS["voice.say.debug"]         = false
SETTINGS["voice.vc.info"]           = false
SETTINGS["voice.vc.debug"]          = false
SETTINGS["voice.enhance.info"]      = false
SETTINGS["voice.enhance.debug"]     = false
# Settings for speaking aloud, at runtime
# These have to be set for the util/say.rb script to work, though the details are engine-specific
SETTINGS["speak.engine"]            = ""    # Use "piper" for Piper
SETTINGS["speak.model"]             = ""    # Use "jenny" for the Jenny model, but default for Piper is "libritts"
SETTINGS["speak.speaker"]           = ""    # Piper uses this for speaker number, but "" indicates zero
# Optionally set to a floating point value to adjust speed of speech
SETTINGS["speak.length_scale"]      = nil
SETTINGS["speak.filters"]           = "norm -3.2"




#  ________________________________________________
# /                                                \
# |  Say Commands for Internal Use of TTS Plugins  |
# \________________________________________________/
# Once you've installed the TTS engines, fill these out with the commands required to activate them, then uncomment
#SAY_COMMANDS["piper"]               = ""
#SAY_COMMANDS["chatterbox"]          = ""
#SAY_COMMANDS["parler"]              = ""
#SAY_COMMANDS["pocket"]              = ""
#SAY_COMMANDS["qwen-clone"]          = ""
#SAY_COMMANDS["qwen-codec"]          = ""
#SAY_COMMANDS["voxcpm"]              = ""



#  ____________________________________________________________
# /                                                            \
# |  Voice Conversion Commands for Internal Use of VC Plugins  |
# \____________________________________________________________/
# Once you've installed the VC engines, fill these out with the commands required to activate them, then uncomment
#VC_COMMANDS["chatterbox"]           = ""
#VC_COMMANDS["kanade"]               = ""
#VC_COMMANDS["miocodec"]             = ""



#  ______________________________________________________
# /                                                      \
# |  Filter Commands for Internal Use of Filter Plugins  |
# \______________________________________________________/
# Once you've installed the VC engines (resynthesis is a form of voice conversion), fill these out with the commands required to activate them, then uncomment
#FILTER_COMMANDS["resynth-kanade"]  = ""
#FILTER_COMMANDS["resynth-miocodec"]= ""




#  ________________________________________________________
# /                                                        \
# |  Enhance Commands for Internal Use of Enhance Plugins  |
# \________________________________________________________/
# Once you've installed the enhance engines, fill these out with the commands required to activate them, then uncomment
#ENHANCE_COMMANDS["lavasr"]          = ""
#ENHANCE_COMMANDS["resemble"]        = ""

