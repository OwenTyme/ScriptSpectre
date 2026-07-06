
#  _____________
# /             \
# |  Constants  |
# \_____________/
#   I maintain two conda-based installs of Pocket TTS and alternate between them
#   That allows me to avoid affecting production-ready software with an experiment, since Pocket it my go-to TTS engine
#   Should the experimental or regular install be used?
TTS_POCKET_EXPERIMENTAL=true
QWEN_DIR="/home/simulatoralive/Applications/qwentts.cpp"



#  ____________________
# /                    \
# |  General Settings  |
# \____________________/
SETTINGS["tts.engine.info"]         = false
SETTINGS["tts.engine.debug"]        = false
SETTINGS["voice.say.info"]          = false
SETTINGS["voice.say.debug"]         = false
SETTINGS["voice.vc.info"]           = false
SETTINGS["voice.vc.debug"]          = false
SETTINGS["voice.enhance.info"]      = false
SETTINGS["voice.enhance.debug"]     = false



#  _____________________________________________________
# /                                                     \
# |  Pronunciation, TTS, VC and Enhance Plugin Scripts  |
# \_____________________________________________________/
SCRIPT["pronounce"]                 = "#{SCRIPT["pronounce"]} --require #{CONFIG_DIR}/pronunciation-owentyme.rb"



#  ________________________________________________
# /                                                \
# |  Say Commands for Internal Use of TTS Plugins  |
# \________________________________________________/
# FIX ME?: Add CBX as a TTS engine?
SAY_COMMANDS["piper"]               = "piper"
SAY_COMMANDS["chatterbox"]          = "conda run -n chatterbox --live-stream \"#{PYTHON_DIR}/chatterbox-wrapper.py\""
SAY_COMMANDS["parler"]              = "conda run -n parler --live-stream python \"#{PYTHON_DIR}/parler.py\""
if TTS_POCKET_EXPERIMENTAL
    SAY_COMMANDS["pocket"]          = "conda run -n pocket-tts-experimental --live-stream pocket-tts"
else
    SAY_COMMANDS["pocket"]          = "conda run -n pocket-tts --live-stream pocket-tts"
end
SAY_COMMANDS["qwen-clone"]          = "#{QWEN_DIR}/build/qwen-tts --model \"#{QWEN_DIR}/models/qwen-talker-1.7b-base-F32.gguf\" --codec \"#{QWEN_DIR}/models/qwen-tokenizer-12hz-F32.gguf\""
SAY_COMMANDS["qwen-codec"]          = "#{QWEN_DIR}/build/qwen-codec --talker \"#{QWEN_DIR}/models/qwen-talker-1.7b-base-F32.gguf\" --model \"#{QWEN_DIR}/models/qwen-tokenizer-12hz-F32.gguf\""
SAY_COMMANDS["voxcpm"]              = "conda run -n voxcpm --live-stream voxcpm"



#  ____________________________________________________________
# /                                                            \
# |  Voice Conversion Commands for Internal Use of VC Plugins  |
# \____________________________________________________________/
VC_COMMANDS["chatterbox"]           = "conda run -n chatterbox --live-stream \"#{PYTHON_DIR}/chatterbox-vc-wrapper.py\""
VC_COMMANDS["kanade"]               = "conda run -n kokoclone --live-stream \"#{PYTHON_DIR}/kanade-vc-wrapper.py\""
VC_COMMANDS["miocodec"]             = "conda run -n miocodec --live-stream \"#{PYTHON_DIR}/miocodec-vc-wrapper.py\""



#  ______________________________________________________
# /                                                      \
# |  Filter Commands for Internal Use of Filter Plugins  |
# \______________________________________________________/
FILTER_COMMANDS["resynth-kanade"]  = "conda run -n kokoclone --live-stream \"#{PYTHON_DIR}/kanade-resynth.py\""
FILTER_COMMANDS["resynth-miocodec"]= "conda run -n miocodec --live-stream \"#{PYTHON_DIR}/miocodec-resynth.py\""




#  ________________________________________________________
# /                                                        \
# |  Enhance Commands for Internal Use of Enhance Plugins  |
# \________________________________________________________/
ENHANCE_COMMANDS["lavasr"]          = "conda run --cwd \"/home/simulatoralive/Applications/LavaSR-ONNX\" -n lavasr --live-stream python main.py"
ENHANCE_COMMANDS["lavasr-denoise"]  = ENHANCE_COMMANDS["lavasr"]
ENHANCE_COMMANDS["resemble"]        = "conda run -n enhance --live-stream resemble-enhance --device cpu"
ENHANCE_COMMANDS["resemble-denoise"]= ENHANCE_COMMANDS["resemble"]

