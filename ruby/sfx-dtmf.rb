
#  ___________________________________________
# /                                           \
# |  Dual-Tone Multi-Frequency Sound Effects  |
# \___________________________________________/
# DTMF signals are the sounds the common telephone systems of the world operate on
VOICES["dtmf"] = Voice.new("#{SCRIPT["sfx-synth"]}",       sound_effect: true, pronunciation_command: nil, enhance_command: "", pre_filters: "norm -16", post_filters: "norm -12")

# Just a little pause to put between numbers
copy_voice("dtmf_pause",        "sfx-silence",  speaker: "trim 0.0 0.25")
# The common keypad sounds
copy_voice("dtmf_1",            "dtmf",         speaker: "synth 0.25 sine 697 sine 1209")
copy_voice("dtmf_2",            "dtmf",         speaker: "synth 0.25 sine 697 sine 1336")
copy_voice("dtmf_3",            "dtmf",         speaker: "synth 0.25 sine 697 sine 1477")
copy_voice("dtmf_4",            "dtmf",         speaker: "synth 0.25 sine 770 sine 1209")
copy_voice("dtmf_5",            "dtmf",         speaker: "synth 0.25 sine 770 sine 1336")
copy_voice("dtmf_6",            "dtmf",         speaker: "synth 0.25 sine 770 sine 1477")
copy_voice("dtmf_7",            "dtmf",         speaker: "synth 0.25 sine 852 sine 1209")
copy_voice("dtmf_8",            "dtmf",         speaker: "synth 0.25 sine 852 sine 1336")
copy_voice("dtmf_9",            "dtmf",         speaker: "synth 0.25 sine 852 sine 1477")
copy_voice("dtmf_0",            "dtmf",         speaker: "synth 0.25 sine 941 sine 1209")
copy_voice("dtmf_star",         "dtmf",         speaker: "synth 0.25 sine 941 sine 1336")
copy_voice("dtmf_pound",        "dtmf",         speaker: "synth 0.25 sine 941 sine 1477")
# The last four aren't commonly seen on keypads and tend to be reserved for internal use of telephone systems
copy_voice("dtmf_a",            "dtmf",         speaker: "synth 0.25 sine 697 sine 1633")
copy_voice("dtmf_b",            "dtmf",         speaker: "synth 0.25 sine 770 sine 1633")
copy_voice("dtmf_c",            "dtmf",         speaker: "synth 0.25 sine 852 sine 1633")
copy_voice("dtmf_d",            "dtmf",         speaker: "synth 0.25 sine 941 sine 1633")

# US dial, ring, busy and off-hook sounds
copy_voice("dtmf_us_dial",      "dtmf",         speaker: "synth 1.0 sin 350 sin 440")
copy_voice("dtmf_us_ring",      "dtmf",         speaker: "synth 2.0 sin 440 sin 480 : trim 0.0 3.0")
copy_voice("dtmf_us_busy",      "dtmf",         speaker: "synth 0.5 sin 480 sin 620 : trim 0.0 0.5")
copy_voice("dtmf_us_offhook",   "dtmf",         speaker: "synth 0.1 sin 1400 sin 2060 sin 2450 sin 2600 : trim 0.0 0.1")

# US dial, ring, busy and off-hook sounds
copy_voice("dtmf_uk_dial",      "dtmf",         speaker: "synth 1.0 sin 350")
copy_voice("dtmf_uk_ring",      "dtmf",         speaker: "synth 0.4 sin 400 sin 450 : trim 0.0 0.2 : synth 0.4 sin 400 sin 450 : trim 0.0 2.0" )
# Not sure why this one produces clipping warnings without the normalization, but that did fix it
copy_voice("dtmf_uk_busy",      "dtmf",         speaker: "synth 0.4 sin 400 norm -8 : trim 0.0 0.4")

# The "dtmf" voice is only there to be copied, to get the volume right, so there's no need for it to lurk after this
VOICES.delete("dtmf")


