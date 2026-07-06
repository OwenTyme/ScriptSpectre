

#  _____________________
# /                     \
# |  Emotion Constants  |
# \_____________________/
VOX_ANGRY="Very intense anger and fast pacing"              # Can be self-fed
VOX_CALM="Relaxed, calm and slow pacing"
VOX_CONFUSED="Very intense confusion"
VOX_CRYING="Very intense despair"
VOX_ENTHUSIASTIC="Very intense enthusiasm"
VOX_EXCITED="Very intense excitement and fast pacing"
VOX_FRUSTRATED="Very intense frustration"
VOX_HAPPY="Cheerful, warm and happy"
VOX_NEUTRAL=""                                              # Intentionally left empty
VOX_SAD="Very intense sadness and slow pacing"
VOX_SCARED="Very intense fear and fast pacing"              # Can be self-fed
VOX_SHOUT="Very intense yelling and fast pacing"
VOX_SURPRISED="Very intense surprise and shock, fast pacing"
VOX_TIRED="Very intensely tired and slow pacing"
VOX_WHISPER="Whispering and slow pacing"
VOX_WORRIED="Very intensely worried"



#  ________________
# /                \
# |  Emotion Hash  |
# \________________/
# Maps emotion names to the above emotion constants
VOX_EMOTION={}
VOX_EMOTION["anger"]=VOX_ANGRY
VOX_EMOTION["angry"]=VOX_ANGRY
VOX_EMOTION["enraged"]=VOX_ANGRY
VOX_EMOTION["rage"]=VOX_ANGRY
VOX_EMOTION["calm"]=VOX_CALM
VOX_EMOTION["confused"]=VOX_CONFUSED
VOX_EMOTION["crying"]=VOX_CRYING
VOX_EMOTION["enthused"]=VOX_ENTHUSIASTIC
VOX_EMOTION["enthusiasm"]=VOX_ENTHUSIASTIC
VOX_EMOTION["enthusiastic"]=VOX_ENTHUSIASTIC
VOX_EMOTION["excited"]=VOX_EXCITED
VOX_EMOTION["excitment"]=VOX_EXCITED
VOX_EMOTION["frustrated"]=VOX_FRUSTRATED
VOX_EMOTION["frustration"]=VOX_FRUSTRATED
VOX_EMOTION["happy"]=VOX_HAPPY
VOX_EMOTION["neutral"]=VOX_NEUTRAL
VOX_EMOTION["normal"]=VOX_NEUTRAL
VOX_EMOTION["sad"]=VOX_SAD
VOX_EMOTION["afraid"]=VOX_SCARED
VOX_EMOTION["scared"]=VOX_SCARED
VOX_EMOTION["shout"]=VOX_SHOUT
VOX_EMOTION["surprise"]=VOX_SURPRISED
VOX_EMOTION["surprised"]=VOX_SURPRISED
VOX_EMOTION["tired"]=VOX_TIRED
VOX_EMOTION["whisper"]=VOX_WHISPER
VOX_EMOTION["whispering"]=VOX_WHISPER
VOX_EMOTION["worried"]=VOX_WORRIED
VOX_EMOTION["worry"]=VOX_WORRIED



#  ___________________________
# /                           \
# |  Emotion Utility Methods  |
# \___________________________/
# FIX ME: Need a method for producing emotional variants of a reference audio file, with optional user review

