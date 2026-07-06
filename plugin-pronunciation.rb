#!/usr/bin/env ruby

#  _____________
# /             \
# |  Constants  |
# \_____________/
# Characters used for text manipulation
NBSP="\u00A0"
ELIPSIS="\u2026"
OPEN_QUOTE1="\u2019"
CLOSE_QUOTE1="\u2018"
OPEN_QUOTE2="\u201C"
CLOSE_QUOTE2="\u201D"



# _________________________________________
#/                                         \
#|  Flag Declaration and Argument Parsing  |
#\_________________________________________/
FLAG={}

def flag(key)
    if FLAG.has_key?(key)
        return FLAG[key] == true
    else
        return false
    end
end

# This one is special-purpose, indicating if effects should be used for sentence pauses
# Periods are replaced with named sound effects for some models, to avoid inconsistent and lengthy sentence pauses
# To avoid this behavior, this flag needs to be set to false
FLAG["effects"]=false
# Another special-purpose flag, which will force all text to lowercase, if set to true
FLAG["lowercase"]=false
# Another special-purpose flag, which will force all text to uppercase, if set to true
# This take precence over the lowercase flag
FLAG["uppercase"]=false


# Argument Parsing
$requires = Array.new
while ARGV.length > 0
    arg = ARGV.shift
    
    # There's one command-line switch used to require an external script
    if arg == "--require"
        required = ARGV.shift
        if required == nil
            raise "Missing file argument for '--require' switch!"
        end
        $requires.push(required)
    else
        FLAG[arg] = true
    end
end



# ______________________
#/                      \
#|  Dictionary Methods  |
#\______________________/
# Hash of patterns to replacment strings
DICTIONARY={}
# Hash of patterns to replacment strings, but processed last
NAMES={}

# Adds a raw replacement pattern
#   Allows use of an unrestricted regular expression
#   Or full sub-string replacement, without regards to word boundaries
def raw(pattern, replacement)
    DICTIONARY[pattern] = replacement
end

# Adds a case-insensitive word correction pattern
def word(word, replacement)
    raw(/\b#{word}\b/i, replacement)
end

# Adds a raw name replacement pattern
def raw_name(pattern, replacement)
    NAMES[pattern] = replacement
end

# Adds a case-insensitive name correction pattern
def name(word, replacement)
    raw_name(/\b#{word}\b/i, replacement)
end

# Call this method to process stdin and send to stdout, using pronunciation rules established by other methods
def main()
    # Load required external scripts
    while $requires.length > 0
        required = $requires.shift
        require required
    end
    
    # Read text from stdin
    text = STDIN.read
    
    # Alter the text
    # We drop everything to lowercase, because that makes matching easier and makes little difference to pronunciation
    text.downcase!
    DICTIONARY.each_key do |pattern|
        replacement = DICTIONARY[pattern]
        text.gsub!(pattern, replacement)
    end
    NAMES.each_key do |pattern|
        replacement = NAMES[pattern]
        text.gsub!(pattern, replacement)
    end
    
    # Turn multiple spaces into single spaces, to avoid weird behavior
    #   Some engines and models are very weird about unexpected formatting
    text.gsub!(/ +/, " ")
    # Remove leading and trailing spaces that may have been introduced by the pattern and replace combos
    text.gsub!(/^ */, "")
    text.gsub!(/ *$/, "")
    
    # If required, shift everything to upper or lower case
    #   However, this is probably better done by TTS engine scripts that need it
    #   On the other hand, the flags for these can easily be added for testing purposes
    if flag("uppercase")
        text.upcase!
    elsif flag("lowercase")
        text.downcase!
    end
    
    # Write the text to stdout
    puts text
end
