#!/usr/bin/env ruby

# This script can optionally stand on its own, but is prepared to be required by pronunciation-main.rb
if caller.length == 0
    called = false
else
    called = true
end

require "#{File.dirname(__FILE__)}/plugin-pronunciation.rb"



#  ________________
# /                \
# |  Ashen Blades  |
# \________________/
word("1905", "nineteen oh five")
word("1930", "nineteen thirty")
word("1942", "nineteen forty two")
word("1944", "nineteen forty four")
word("1945", "nineteen forty five")
word("1966", "nineteen sixty six")
word("1972", "nineteen seventy two")
word("1973", "nineteen seventy three")
word("1978", "nineteen seventy eight")
word("1986", "nineteen eighty six")
word("1989", "nineteen eighty nine")
# The Barret M107 is part of Demon for President!
word("m107", "em one oh seven")
word("lrp", "el are pee")

name("borkuch", "Bork'uch")
name("degloth", "Deg loth")
# True name of Ella/Ellmozeth, AKA Lust, though she gave up that title in volume 5
name("ell’aruth’uzola’moth", "ell aruth uzola moth")
# This one was odd
# It was pronounced properly all by itself, but pronounced wrong with an "'s" on the end
# Forcing the pronunciation fixed that
name("evie", "Eve'ee")
name("johan", "Yohan")
name("josef", "Yosef")
name("mashu'ra", "Mosh'oo'rah")
name("kanda", "Konda")
name("kordell", "Kore'dell")
name("kugo", "Koogoh")
name("lara", "Laura")
name("mika", "Meeka")
#name("lms", "el em ess"
name("o'duggan", "Oh'Doogan")
name("pecos", "Peycos")
name("shaw", "Shah")
name("shime", "She-may")
# True name of Vogerath, AKA Pride
name("vigge'smort'yergle'rath", "viggee smort yergle rath")
if flag("pocket")
    name("vogerath", "Vogi-wrath")
    name("vogeraths", "Vogi-wraths")
else
    name("vogerath", "Vogueyhrath")
    name("vogeraths", "Vogueyhraths")
end
name("yasu", "Yahsoo")
name("zhilova", "Zeeloav'uh")

# These are used for dialog from Sloth in Ashen Blades, but it might find a use for any german accent text
word("avait", "ahvait")
# FIX ME: This one isn't working right and perhaps the correct way is to replace the original text with 've'
word("hwe", "hoo'wee")
word("hy", "high")
word("hyu", "hue")
word("hyur", "hyuer")
word("hyurs", "hyuers")
word("ja", "yah")
word("jah", "yah")
# This one also hits 'I've', wbich is unacceptable
# FIX ME: Find an alternative way to handle this one
#word("ve", "vee")
word("vhat", "vut")
word("vhen", "ven")

# Chinese accent of Evie in She Seeks Peace
word("actuarry", "acturee")
word("brind", "brined")
word("i'rr", "i'r")
word("rearry", "rear'ee")
word("sreep", "suh'reep")
word("sreeping", "suh'reeping")
name("zhirova", "zeeroav'uh")

# Australian accent, words and phrases
word("g'day", "goo'day")
word("g'night", "goo'night")

# Abbreviations
# Mita Holdings Incorporated
word("mhi", "em aitch eye")
# Mita Transportation Services
word("mts", "em tee ess")



#  ____________________________________________________
# /                                                    \
# |  The Wizard's Scion, Sky Children and Jigsaw City  |
# \____________________________________________________/
word("blackfire", "black fire")
# Eastern Coalition
word("ec", "ee cee")
# Dadum's little verbal habit
word("mmm", "erm")
# Imperial Center for Disease Control
word("icdc", "eye see dee see")
word("magi tech", "magitech")
# United Nations of the South Galaxy
word("unsg", "you en ess gee")
# Teleport Shiping Network
word("tsn", "tee ess inn")
# Abbreviation for walking, talking and breathing
word("wtab", "double you tee eh bee")

name("baaz", "Bahz")
name("cinnamondash", "Cinnamon Dash")
name("dabaline", "Dabaleen")
name("dadum", "Daydum")
name("darek", "Dah'reck")
name("cha'da", "Chah-dah")
name("dagnae", "Dagneh")
name("durouk", "Duruuk")
name("embercrusher", "Ember-crusher")
name("gida", "Gheeduh")
name("gelguth", "Ghelguhth")
name("geller", "Ghelare")
name("goras", "Gore'oss")
name("hollytwinkle", "Holly Twinkle")
name("ida", "Eyeduh")
name("igex", "Eye-gecks")
name("krikor", "Kreecore")
name("levi", "Leeveye")
name("lyra", "Lyerah")
name("lovelysky", "Lovely Sky")
name("nadell", "Nuh'dell")
name("merag", "Mayrag")
name("nisim", "Niseem")
name("nofrath", "Nohfrath")
name("ogomid", "Ohgohmid")
name("olyna", "Oleena")
name("orangerock", "Orange Rock")
name("razzan", "Rozzohn")
name("reizol", "Rayzol")
name("rukrug", "Ruck-rug")
name("teera", "tee-ruh")
name("tisiphone", "Tiss-iff'oh'nee")
name("umak", "Oomock")
name("ushras", "Ooshrass")
name("ustrina", "Oostreenuh")
name("vanu", "Van'oo")
name("vrad", "Vraud")
name("winzon", "Winson")
name("yizor", "Yeezoar")
name("yrica", "Yearica")
name("zech", "Zeck")
name("zechariah", "Zeckariah")



#  ____________
# /            \
# |  Null War  |
# \____________/
# Words specific to Troll War
word("108th", "one hundred eighth")
word("lobras", "lobrass")
word("lm 20377", "el em 2 0 3 7 7")
word("moonblade", "moon blade")
word("moonblades", "moon blades")

# Names from Troll War Piper needs help with
name("3455c4b1", "3, 4, 5, 5, C, 4, B, 1")
name("40e8b60f", "4, 0, E, 8, B, 6, 0, F")
name("70a3f0e8", "7, 0, A, 3, F, 0, E, 8")
name("72d5e639", "7, 2, D, 5, E, 6, 3, 9")
name("c9e1af51", "C, 9, E, 1, A, F, 5, 1")
name("aketa", "Uh ket uh")
name("alethis", "Uh'leth'is")
name("anji", "Aunji")
name("arun", "Ahrune")
name("azra", "Auzrah")
name("blueleaf", "Blue Leaf")
name("bodor", "Beaudoor")
name("brastek", "Braztech")
name("brosla", "Brauzla")
name("daber", "Dobber")
name("dorabido", "Dorabeedough")
name("emberback", "Ember Back")
name("fidra", "Fidruh")
name("ghinead", "Ghineeyad")
name("gorgo", "Gorgoh")
name("gymdir", "Gimdir")
name("grimrock", "Grim Rock")
name("grumblefall", "Grumble Fall")
name("idoi", "Yh doy")
name("illa", "Ill'luh")
name("iz'eol", "Iz'wall")
name("jadetoe", "Jade Toe")
name("kadrek", "Kad'reck")
name("kragminer", "Krag Miner")
name("leatherspine", "Leather Spine")
name("lovelymint", "Lovely Mint")
name("nepita", "Nepeetuh")
name("nobris", "Nahbris")
name("olgun", "Ole'gun")
name("posey", "Pose'ee")
name("rashi", "Rawshi")
name("rolar", "Rollarre")
name("rujin", "Ruejin")
name("segawa", "Sega'wuh")
name("shadowfang", "Shadow Fang")
name("shaffurukattā", "Shafoorukot'ah")
name("shatterhand", "Shatter Hand")
name("shengis", "Sheng'ghiss")
name("spidercliff", "Spider Cliff")
name("stormbreaker", "Storm Breaker")
name("teja", "Teya")
name("thergith", "Thurgith")
name("trevan", "Treyvan")
name("turloth", "Tur'loth")
name("utros", "Ootrose")
name("utrocide", "Ootrocide")
name("vokosian", "Vokohsian")
name("warmaul", "War Maul")
name("whitewall", "White Wall")
name("windmaker", "Wind Maker")
name("withermine", "Wither Mine")
name("yera", "Eeruh")
name("yetu", "Eetoo")
name("zulkis", "Zulk'iss")



#  _____________________
# /                     \
# |  The Book of Newts  |
# \_____________________/
name("ahmeeleeyuh", "ah me lee yuh")
name("airwitch", "Air Witch")
name("astorene", "Astoreen")
name("blackbird", "Black Bird")
name("bonebuster", "Bone Buster")
name("cedarbeam", "Cedar Beam")
name("daleshade", "Dale Shade")
name("davit", "Dav'eet")
#name("dugaria", "doo gar'eeuh")
#name("dugaria", "due'gar'ia")
name("dugaria", "Doog'aaria")
name("havisa", "Have'ee'suh")
name("heavyskull", "Heavy Skull")
name("hobard", "Hoebard")
name("holyheart", "Holy Heart")
name("ironrock", "Iron Rock")
name("ithys", "Ithiss")
name("junkshop", "Junk Shop")
name("katuna", "Ketuna")
name("kontoti", "Kon-tawtee")
if flag("jenny")
    name("krauss", "Krouss")
end
name("kryenna", "Cry'enna")
# The irsih voices (Jenny, for example) tend to soften the end of the name so badly, it isn't understandable, so a fix was needed
if flag("jenny")
    name("marta", "Martuh")
end
name("maccle", "Mackle")
name("macclesfield", "Mackle's Field")
#name("mina", "meena")
name("nyna", "Neena")
name("nicklebender", "Nickle Bender")
name("nonar", "No-narr")
name("nupria", "Noo'pree'uh")
name("nyra", "Nigh'ra")
name("redroar", "Red Roar")
name("rimestar", "Rime-Star")
name("starwitch", "Star Witch")
name("sakura", "Sockoo'rah")
name("sydos", "Sigh'dose")
name("theano", "Thayano")
name("tibota", "Tih'boat'ah")
name("vanenta", "Vuhnentuh")
name("usdal", "Oosdahl")
name("whitjaw", "Whit jaw")
name("wia", "double you eye eh")
name("yseulte", "Eesyulte")



#  ___________________________
# /                           \
# |  The Most Powerful Words  |
# \___________________________/
name("owyn", "Owen")
name("ileus", "Ill'eeus")



# _________________________________
#/                                 \
#|  Perform the Text Replacement!  |
#\_________________________________/
unless called
    main
end
