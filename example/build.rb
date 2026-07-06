#!/usr/bin/env ruby

# TTS engine enable flags
ENABLE_CHATTERBOX = true
ENABLE_PARLER = false
ENABLE_PIPER = false
ENABLE_POCKET = true
ENABLE_QWEN = true
ENABLE_VOXCPM = false

# We need all the common data and functions from this file and those it requires
require "#{File.dirname(__FILE__)}/../common.rb"



# Constants specific to this audiobook
# Directory of the start script, which may not be the current directory
AUDIO_SCRIPT="#{START_DIR}/audiobook.odt"



#  __________________
# /                  \
# |  Prepare Voices  |
# \__________________/
# Base voice that can be adjusted for either quick testing with faster, but lower quality TTS engine, or a slower, better one, for production
copy_voice("base-voice", "pocket", vc_command: SCRIPT["ehhance-resemble-denoise"], enhance_command: "#{SCRIPT["enhance-lavasr-denoise"]}")
#copy_voice("base-voice", "qwen-clone", vc_command: SCRIPT["ehhance-resemble-denoise"], enhance_command: "#{SCRIPT["enhance-lavasr-denoise"]}")

# NOTE: DO NOT use dashes or spaces in voice/soundeffect names, because that will make them inaccessible via audio scripts!
# That is NOT supported, but you *can* use underscores!
# They'l work fine for the --test command-line switch, but it won't work with audio scripts!
# ../common.rb uses these as an informal means to prevent base voices from colliding with user-added voices, as does 'base-voice' in this file.
# All audiobooks MUST specify a voice named "narrator" for lines with no designated voice, or errors WILL happen!
copy_voice("narrator", "base-voice", speaker: "#{START_DIR}/david_clark.flac")
# Voices can use any alphanumeric character, plus underscore characters
copy_voice("cori", "base-voice", speaker: "#{START_DIR}/cori_samuel.flac")
copy_voice("jodi", "base-voice", speaker: "#{START_DIR}/jodi_krangle.flac")
# This one is a little different, because it uses chatterbox-turbo to allow for para-linguistic tags
# The following can be inserted for such effects, in character voice:
# <clear throat> <sigh> <shush> <cough> <groan> <sniff> <gasp> <chuckle> <laugh>
copy_voice("jodi_cb", "chatterbox-turbo", speaker: "#{START_DIR}/jodi_krangle.flac")

# Example sound effect
copy_voice("romance_interrupted", "sfx-file", speaker: "#{START_DIR}/romance-interrupted.flac")


# Main entry point for the application, allowing the user to modify command-line switches before they're used, if desired
main(AUDIO_SCRIPT)


