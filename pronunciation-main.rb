#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/plugin-pronunciation.rb"



# __________________________
#/                          \
#|  Raw symbol replacement  |
#\__________________________/
# Most TTS engines totally ignore special characters, so if they're to be pronounced, they need to become readable words
# Square brackets
raw("[", "open bracket")
raw("]", "close bracket")
# Quotation marks can cause bizarre pronunciations, so better to remove them, since there's so much dialog in a novel
raw("\"", "")
# Ellipses aren't usually turned into pauses, much the same as some engines and models ignore commas
# Three periods turned out to create pauses that are too long, so make it just two
raw("#{ELIPSIS}", "..")
# Anything special thing with a trailing period needs to be spelled out, to avoid starting a new sentence
#   Title abbreviations
raw(/\badm\./i, "Admiral")
raw(/\bcapt\./i, "Captain")
raw(/\bcol\./i, "Colonel")
raw(/\bcmdr\./i, "Commander")
raw(/\bcpl\./i, "Corporal")
raw(/\bdr\./i, "Doctor")
raw(/\besq\./i, "Esquire")
raw(/\bgen\./i, "General")
raw(/\bj\.g\./i, "junior grade")
raw(/\blt\./i, "Lieutenant")
raw(/\bmaj\./i, "Major")
raw(/\bms\./i, "Miss")
raw(/\bmrs\./i, "Missus")
raw(/\bmr\./i, "Mister")
raw(/\bpvt\./i, "Private")
raw(/\bpfc\./i, "Private First Class")
raw(/\bsgt\./i, "Sergeant")
raw(/\bspc\./i, "Specialist")
#   Some country abbreviations
raw(/\bu\.s\./i, "you ess")
raw(/\bu\.s\.a\./i, "you ess eh")
raw(/\bu\.s\.s\.r\./i, "you ess ess are")
raw(/\bu\.k\./i, "you kay")
#   Versus 
raw(/\bvs\./i, "versus")
# A special case of the general issue of bullet calibers, which had to be handled before periods are stripped out
raw(/\b\.357/i, "three fifty seven")
# Assuming a novel, allow for bullet calibers
# So, don't treat ".45" as "dot forty-five"
# Strip the dot off the start, but make sure we don't mess with numbers with a decimal point in the middle
#   Covers the start of line
raw(/^\.([[:digit:]])/i, "\\1")
#   Anywhere else in a sentence
raw(/([^[:alnum:]])\.([[:digit:]])/i, "\\1\\2")
# The next three MUST be in the specific order they're in!
# Strings of text with a period in the middle (ala numbers, like this: "0.1") need to be modified to avoid the periods being stripped out
raw(/([[:alnum:]])\.([[:alnum:]])/, "\\1#{ELIPSIS}\\2")
# Some Piper models need the periods to be there, but other models need them stripped out, to avoid them randomly saying "dot" at the end of sentences
# Regardless, however, remove trailing spaces at the end of sentences
if flag("cori") or flag("steve")
    if not flag("effects")
        raw(/\. */, ".\n")
    else
        raw(/\. */, ".\n[period]\n")
    end
else
    if not flag("effects")
        raw(/\. */, ".\n")
    else
        raw(/\. */, "\n[period]\n")
    end
end
raw(/([[:alnum:]])${ELIPSIS}([[:alnum:]])/, "\\1.\\2")
# Special handling for the end of sentences, colons and semicolons
if not flag("effects")
    raw(/[!] */, "!\n")
    raw(/[?] */, "?\n")
    raw(/: +/, "\n")
    raw(/; +/, "\n")
else
    raw(/[!] */, "n[period]\n")
    raw(/[?] */, "?\n[period]\n")
    raw(/: +/, "\n[period]\n")
    raw(/; +/, "\n[period]\n")
end
# Remove commas and instead insert line breaks for Cori model, which skips whole words without this
if flag("cori") and (not flag("effects"))
    raw(/,/, "\n")
end


# Dash characters get inconsistent treatment
# Sometimes they're ignored and sometime pronounced, so it's best to turn them into spaces
raw("-", " ")

# Aside from these exceptions...
raw(/\band\/or\b/i, "and or")
raw(/\b24\/7\b/, "twenty four seven")
# ...the slash characters should be pronounced, not ignored like some models do
raw("/", " slash ")
raw(/\\/, " backslash ")

# Some of the models also ignore these characters
raw("@", " at ")
raw("#", " hash ")
# FIX ME?: Add special handling for '$' preceeding a number, but this may best be served with manual handling
raw("$", " dollar ")
raw("%", " percent ")
raw("^", " caret ")
raw("&", " and ")
raw("*", " asterik ")
raw("(", " open parenthesis ")
raw(")", " close parenthesis ")
raw("{", " open brace ")
raw("}", " close brace ")
raw("|", " pipe ")


# [clear throat], [sigh], [shush], [cough], [groan], [sniff], [gasp], [chuckle], [laugh]
# The Chatterbox script uses these paraliguistic tags, so we don't want them pronounced the wrong way
if flag("chatterbox")
    raw(/<clear throat>/i, "[clear throat]")
    raw(/<sigh>/i, "[sigh]")
    raw(/<shush>/i, "[shush]")
    raw(/<cough>/i, "[cough]")
    raw(/<groan>/i, "[groan]")
    raw(/<sniff>/i, "[sniff]")
    raw(/<gasp>/i, "[gasp]")
    raw(/<chuckle>/i, "[chuckle]")
    raw(/<laugh>/i, "[laugh]")
end

raw("<", " less than ")
raw(">", " greater than ")
raw("=", " equals ")
raw("+", " plus ")
# FIX ME?: In mathematics, this usually means approximately, so add an alternate version that matches ahead of a number
raw("~", " tilde ")
# Probably best to leave this commented out, because grave is sometimes an alternate version of a quotation mark
#raw("`", " grave ")
raw("©", " copyright ")
raw("®", " registered trademark ")
raw("¥", " yen ")
raw("¢", " cents ")



# SPECIAL NOTE: Words with a single spelling that have multiple meanings sometimes require special handling
# This article has a list of them: https://en.wikipedia.org/wiki/Heteronym_(linguistics)
# Common examples: read {red} vs. {reed}, tear {teer} vs. {tare}, live {lyve} vs. {liv}, bow {bo} vs. {bouw}, bowed vs. {bouwed},
# Uncommon examples: dove {dohv} vs. {duv}, buffet vs. {buffit}, minute vs. {mineoot}, desert vs. {dessert}, content vs. {contint},
#       coordinate vs. {coordin-ate}, close vs. {cloze}, wind {wend} vs. {whined}, refuse {reefuse} vs. {ref'use}, lead {leed} vs. {led}
# This can't be done automatically, because English is a pain about such things



#  _______________
# /               \
# |  Model Fixes  |
# \_______________/

# LibriTTS sometimes refuses to say the word 'slash' , or anything like unto it, but only in a sentence
# Therefore, we break it up, putting it on it's own line
# That will cause it to be interpreted by the Piper TTS script as its own sentence
# This will introduce gaps, but what else can I do?
# Piper is REALLY broken when it comes to this word!
if flag("libritts")
    word("slash", "\nslash\n")
#    word("slashing", "\nslashing\n")
#    word("slashes", "\nslashes\n")
#    word("slashed", "\nslashed\n")
    word("slasher", "\nslasher\n")
end

if flag("clean100")
    # Clean100 drops the K in "York"; this is the closest I can get to fixing it
    # It softens the K in any word ending in 'rk', but York seems to be the worst case, entirely dropping it, which doesn't sound right
    word("york", "yor'rk")
    word("calves", "ca'ves")
    word("torso", "tor so")
    word("failure", "fail'yur")
    # Oddly, clean100 shares this flaw of the jenny model (see below)
    word("pawn", "pon")
    word("pawns", "pons")
    # Similar to "york"
    word("cork", "cor'rk")
    word("nazi", "noughtzi")
end

if flag("jenny")
    word("era", "ee'rah")
    # Oddly, Jenny shares this flaw with LibriTTS, though with slight differences
    word("slash", "\nslash\n")
    word("slashed", "\nslashed\n")
    word("slashing", "\nslashing\n")
    # The Jenny model sometimes flubs this word, pronouncing only the A and F, and it gets worse with a question mark after it
    word("after", "aftour")
    # Jenny sometimes flubs this word
    word("laughter", "laugh ter")
    # The Jenny model has an unfortunate tendency to say "pawn" almost like "porn"
    # She needs a little help with this, lest I die of shame
    # "...which is still a terminal disease in certain parts of the galaxy." ― Douglas Adams, The Hitchhiker's Guide to the Galaxy
    word("pawn", "pon")
    word("pawns", "pons")
    # The Jenny model sometimes doesn't say this word right, speaking only the first syllable, so let's trick her into saying it right
    word("window", "whyndoh")
    word("windows", "whyndohs")
    word("windowed", "whyndohed")
end

if flag("piper")
    # Oddly, this is how everyone says the word and for some reason, Jenny chokes on the true spelling
    # Dunno about other models, but this fixes that and forces the common pronunciation
    word("asterisk", "asterik")
    word("asterisks", "asteriks")
    word("copyright", "copy right")
    word("neither", "nyether")
    word("prologue", "pro log")
    word("samurai", "samoorye")
    word("samurais", "samooryes")
    word("via", "vieuh")
    
    name("reggie", "Rejjee")
end

if flag("kokoro")
    # This one surprises me, because Kokoro tends to say "amooze" without help
    word("amuse", "a muse")
    # Been hearing 'curse-ed' on this one, which is not apropriate for a general pronunciation
    word("cursed", "curst")
    word("eons", "eeons")
    word("prophesy", "prophesee")
    word("prophesies", "prophesees")
    word("ragged", "raggid")
    # Used for cases like re-match and similar dashed words
    # This seems to be a problem due to the way this script strips out dashes and replaces them with spaces
    # Been hearing 'ray' instead of 'ree', so that needs to be fixed
    word("re", "ree")
    word("samurai", "samoorye")
    word("samurais", "samooryes")
    # Some dwarf accent fixes
    word("aye", "eye")
    word("ye", "yee")
    
    name("nicole", "Nick'ole")
    name("reggie", "Rejjee")
end

if flag("pocket")
    word("adamant", "ada'mant")
    word("asterisk", "asterik")
    word("bathe", "bayth")
    word("cloth", "clauth")
    word("disheartened", "dis'heartened")
    word("fin", "fen")
    word("fins", "fens")
    word("high g", "high gee")
    word("honed", "hone'd")
    word("megalomaniacal", "megalomin-aye'ikle")
    word("maniacal", "min-aye'ikle")
    word("maniacally", "min-aye'ikli")
    word("samurai", "samoo-rye")
    
    # Fixes for words ending in 'ed', which get said in odd ways
    # Pocket has a tendencey to pronounce 'blessed' like 'bless-ed'
    # This can be forced to 'bless-ed' with 'blessid'
    word("blessed", "blest")
    # This can be forced to 'curse-ed' with 'cursid'
    word("cursed", "curst")
    # And 'legged' as 'leg-ed'
    # This can be forced to 'leg-ed' with 'leggid'
    word("legged", "legd")
    
    name("artemis", "Art'em'iss")
    name("faraday", "Fairuhday")
    name("macie", "Maysee")
    
    word("id", "eye dee")
end



#  _________________
# /                 \
# |  Grammar Fixes  |
# \_________________/
# A very unusual edge case that needs to be pronouced like a capital A
# FIX ME?: Is this where this belongs?
#   It could possibly be moved into a character-specific pronunciation script for LMS from Ashen Blades
raw(/\ba([\.!?])/i, "eh\\1")



#  _____________________
# /                     \
# |  Common Word Fixes  |
# \_____________________/
# Some words TTS engines commonly don't know or have trouble with in sentences
#word("ablative", "ablate iive")
# This is a common way to stretch absolutely
word("ab so lute ly", "ab, so, lute, lee")
word("albino", "albeye no")
word("algae", "algee")
word("arboretum", "arbor'ee'tum")
word("audiobook", "audio book")
word("aussie", "ossee")
word("aussies", "ossees")
word("bas relief", "bah relief")
word("bassline", "base line")
word("beeswax", "bees wax")
word("bedrock", "bed rock")
word("bellhop", "bell hop")
word("bipod", "byepod")
word("bipods", "byepods")
word("bogeyman", "booggie man")
word("bogeymen", "booggie men")
word("buffet", "buffay")
word("buffets", "buffays")
word("buzzkill", "buzz kill")
word("canine", "kay nine")
word("canines", "kay nines")
word("coup", "coo")
word("charade", "shahraide")
word("charades", "shahraides")
word("chain mail", "chainmail")
# Went with the American pronunciation for this one
word("cloche", "clohsh")
# This one works as a prefix, like in de-mixed
word("de", "dee")
word("dematerialized", "dee'materialized")
word("derringer", "derrinjer")
word("derringers", "derrinjers")
# Part of the proper scientific name of LSD
word("diethlyamide", "die ethyl amide")
word("dandelion", "dandih lyun")
word("dogeared", "dog eared")
# Dove, as in diving, is more common than dove, as in the bird, but Piper treats it like the bird
# If you need dove as in bird, it can be specified with {duv}
word("dove", "dohve")
# Still, the plural is definitely the bird
word("doves", "duvs")
word("en garde", "on guard")
word("en masse", "on masse")
word("eww", "eew")
word("eyeshadow", "eye shadow")
word("fecal", "feecal")
word("feces", "feesees")
word("fillet", "fillay")
word("fillets", "fillays")
word("filleting", "fillaying")
word("fluorine", "florine")
# Note the fact that plural cases need two entries!
word("gnomish", "gnome'ish")
word("golem", "gohlem")
word("golems", "gohlems")
word("grâce", "grah")
word("gravitas", "grav'ih'tass")
word("gymnast", "gymnyst")
# I'm surprised to find this in online dictionaries, classed as an interjection
# Strange how a word was born from a little thinking sound
word("hrm", "herm")
word("ideology", "eye'dee'ology")
word("inky", "ink'ee")
word("jellybean", "jelly bean")
word("jellybeans", "jelly beans")
word("jugular", "jug'you'lar")
word("kiddie", "kidee")
word("kiddies", "kidees")
word("kraken", "crackin")
word("layout", "lay out")
word("layouts", "lay outs")
word("macabre", "muh cob")
word("mannequin", "mannekin")
word("mannequins", "mannekins")
word("moviegoer", "movie goer")
word("moviegoers", "movie goers")
word("ninja", "ninjuh")
word("ninjas", "ninjuhs")
word("obi", "obee")
word("orichalcum", "oricalcum")
word("organometallic", "organo metallic")
word("ow", "ouw")
word("oww", "ouw")
# French word for step, as used in pas de deux (meaning literally "step of two"), which is a ballet term
word("pas", "pah")
word("peachy", "peachie")
word("penchant", "penshant")
word("pentagon", "penta'gone")
word("phlogiston", "flowjiston")
word("plie", "plea eh")
word("plies", "plea ehs")
word("procreate", "pro create")
word("prophesied", "prophess eyed")
word("rabid", "rabbid")
# Read in the past tense is probably what we need, but if the other pronunciation is required, it can be specified with {reed}
word("read", "red")
# But this variation has enough context to go the other way
word("reads", "reeds")
word("recon", "ree con")
word("regicide", "rejjicide")
word("reneged", "ree'negged")
word("riffling", "rifling")
#word("router", "ruwter")
word("rune", "roone")
word("runes", "roones")
word("ruse", "ruze")
# Surprises me this one was necessary
word("sage's", "sages")
word("scythe", "scy'th")
word("siccing", "sicking")
word("siegfried", "sigfried")
word("space/time", "space-time")
word("spreadsheet", "spread sheet")
word("spreadsheets", "spread sheets")
word("stroboscope", "strobe'oh'scope")
word("tarry", "taree")
# Tjhese two most likely describe crying
# If you need to refer to rips in fabric, it can be specified with {tare} or {tares}
word("tear", "teer")
word("tears", "teers")
#word("terror", "tair our")
#word("terrors", "tair ours")
word("topiary", "tope'ee'airy")
word("trollish", "troll-ish")
word("tv", "tee vee")
word("tvs", "tee vees")
word("vizier", "vizeer")
word("wakizashi", "wockee'zashee")
word("wakizashis", "wockee'zashees")
word("woodcutter", "wood cutter")
word("woodcutters", "wood cutters")
# Talking about the movement of the air is more common in my writing than talking about winding a spring, though {wined} should work if you need that pronunciation
word("wind", "wend")
word("windshield", "wend shield")
word("windshields", "wend shields")
word("workshop", "work shop")
word("ya", "yuh")
word("ya'all", "yuh all")
word("yarn", "yahrn")
word("yech", "yeck")

# Some (un)common names
word("annmarie", "Anne-marie")
word("coppelia", "Coppellia")
word("evelyn", "Ev'ellen")
word("ferengi", "Fur'rain'ghee")
word("geiger", "Guy'gur")
word("giselle", "Jiz'elle")
word("lorena", "Lor'eh'na")
# A name from Irish muthology
word("lugh", "Loo")
word("prague", "Prog")
word("rapunzel", "Rah'pun'zel")
word("raquel", "Rackell")
# Historic New York City airport name
word("idlewild", "Idle-wild")
word("isabelle", "Izabelle")
# Name of a TTS engine
word("kokoro", "Kokore'oh")



#  _________________
# /                 \
# |  Abbreviations  |
# \_________________/
# Abbreviations get pronounced as if they were words, so we process them to adjust
# I find best success with these spelling out the syllables, because it sometimes goes too fast
# This also prevents an appostraphe and an 'S' on the end from changing the pronunciation
# These phoenetic spellings of the alphabet should be helpful to ensure the letters are pronounced as intended
#   'eh' 'bee' 'see' 'dee' 'ee' 'ef' 'gee' 'aitch' 'eye' 'jay' 'kay' 'el' 'em'
#   'in' 'oh' 'pee' 'cue' 'are' 'ess' 'tee' 'you' 'vee' 'double you' 'ex' 'why' 'zee'
# 9-1-1
word("911", "nine one one")
# A-10 Thunderbolt, also known as the Warthog, a very tough aircraft designed to destroy tanks
word("a 10", "eh ten")
# Automatic Colt Pistol, a common suffix used for ammunition
word("acp", "eh see pee")
# As Soon As Possible
# A little change of pace, since the common pronunciation isn't as characters, but as a word
word("asap", "eh sap")
# This is a sniper rifle favored by police
word("at308", "eh tee three oh eight")
# Astronomical Unit
word("au", "eh you")
# Air (or Aerospace) Warning and Control System
# Another one with a unique pronunciation
word("awacs", "eh whacks")
# Chief Executive Officer
word("ceo", "see ee oh")
# Carbon-Dioxide
word("co2", "see oh two")
# Digital Subscriber Line
word("dsl", "dee ess el")
# Electro Magnetic Pulse
word("emp", "ee em pee")
word("emps", "ee em pees")
# Emergency Medical Technician
word("emt", "ee em tee")
word("emts", "ee em tees")
# Evironmental Protection Agency
word("epa", "ee pee eh")
# Emergency Room
word("er", "ee are")
# Estimated Time to Arrival
word("eta", "ee tee eh")
# Federal Bureau of Investigation
word("fbi", "ef bee eye")
# Faster Than Light
# Common in sci-fi fiction
word("ftl", "ef tee el")
# Short for 'hours', so just expand this
word("hrs", "hours")
# Inter-Continental Ballistic Missile
word("icbm", "eye see bee em")
# Roman numberal two
word("ii", "two")
# Roman numberal three
word("iii", "three")
# Identify Friend or Foe
word("iff", "eye ef ef")
# Intravenous
word("iv", "eye vee")
# Lysergic acid Diethylamide
word("lsd", "el ess dee")
# Landing Zone
word("lz", "el zee")
word("lzs", "el zees")
# The M2 Browning is a machine gun
word("m2", "em two")
# The M67 is a modern anti-personnel grenade
word("m67", "em sixty seven")
# Mark, as in Mk 2 pineapple grenade
word("mk", "mark")
# Meal Ready to Eat
word("mre", "em are ee")
word("mres", "em are ees")
# Non-Commissioned-Officer
word("nco", "in see oh")
word("ncos", "in see oh's")
# National Security Agency
word("nsa", "in ess eh")
# New York Police Department
word("nypd", "in why pee dee")
# Public Address
word("pa", "pee eh")
# Rocket Propelled Grenade or Role-Playing Game
word("rpg", "are pee gee")
word("rpgs", "are pee gees")
# Single-Action Army abbreviation
word("saa", "ess eh eh")
# Transportation Security Administration
word("tsa", "tee ess eh")
# Unidentified Flying Object
word("ufo", "you ef oh")
word("ufos", "you ef ohs")
# Universal Serial Bus
word("usb", "you ess bee")
# Video Home System
word("vhs", "vee aitch ess")

# The roman numberals after "World War" need some attention
word("world war i", "world war one")
word("world war ii", "world war two")
word("world war iii", "world war three")
word("world war iv", "world war four")



#  __________________
# /                  \
# |  Time and Years  |
# \__________________/
# Time
word("1:00", "one o'clock")
word("2:00", "two o'clock")
word("3:00", "three o'clock")
word("4:00", "four o'clock")
word("5:00", "five o'clock")
word("6:00", "six o'clock")
word("7:00", "seven o'clock")
word("8:00", "eight o'clock")
word("9:00", "nine o'clock")
word("10:00", "ten o'clock")
word("11:00", "eleven o'clock")
word("12:00", "twelve o'clock")

# Some years
word("1600's", "sixteen hundreds")
word("1700's", "seventeen hundreds")
word("1800's", "eighteen hundreds")
word("1900's", "nineteen hundreds")
word("1910's", "nineteen tens")
word("1920's", "nineteen twenties")
word("1930's", "nineteen thirties")
word("1940's", "nineteen forties")
word("1950's", "nineteen fifties")
word("1960's", "nineteen sixties")
word("1970's", "nineteen seventies")
word("1980's", "nineteen eighties")
word("1990's", "nineteen nineties")
word("20's", "twenties")
word("30's", "thirties")
word("40's", "forties")
word("50's", "fifties")
word("60's", "sixties")
word("70's", "seventies")
word("80's", "eighties")
word("90's", "nineties")




#  ____________________________
# /                            \
# |  Oddities and assortments  |
# \____________________________/
# An assault rifle favored by Russians and their allies
word("ak 47", "eh kay forty seven")
# This is a military cargo plane
word("c 130", "see one thirty")
# A little Japanese, which means outsider, though it can also translate as "white guy"
word("gaijin", "guyjeen")
# An old, but common model of gun
word("m1911", "em nineteen eleven")
word("m1911s", "em nineteen elevens")
# A model of revolver suitable for a 1940's detective
word("m1917", "em nineteen seventeen")
word("m1917s", "em nineteen seventeens")
# What does the kitty say?
word("mrow", "mer ouw")
# Something fun that's sometimes used when someone disrespects royalty
word("kingie", "king ee")
word("queenie", "queen ee")



#  ____________________
# /                    \
# |  Scriptural Names  |
# \____________________/
# From the Bible
word("boaz", "Boe-az")
word("isaiah", "Eyesayuh")
# From the Book of Mormon
word("laman", "Layman")
word("lamanite", "Laymanite")
word("lamanites", "Laymanites")
word("nephi", "Neephi")
word("nephite", "Neephite")
word("nephites", "Neephites")



# _________________________________
#/                                 \
#|  Perform the Text Replacement!  |
#\_________________________________/
main
