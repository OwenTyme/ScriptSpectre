

#  _________________________
# /                         \
# |  Ruby Library Requires  |
# \_________________________/
# Used for running shell commands with some measure of fine control, particularly pandoc
#   And by the way, that is required by the odt_to_markdown and markdown_to_plantext methods
require 'open3'



#  ____________________
# /                    \
# |  Global Constants  |
# \____________________/
# Characters used for text manipulation
ELIPSIS="\u2026"
OPEN_QUOTE1="\u2019"
CLOSE_QUOTE1="\u2018"
OPEN_QUOTE2="\u201C"
CLOSE_QUOTE2="\u201D"



#  ____________________
# /                    \
# |  Markdown Methods  |
# \____________________/
# Reads an ODT file and converts it to markdown, returning it as a String
def odt_to_markdown(odt_file)
    # The only reason we're taking a pass through HTML is that it make the text manipulation quite easy
    #   This allows easily catching the repeated combinations of "<em>" and "</em>" Pandoc produces from ODT italics
    #   Those would be far more painful to catch in markdown
    output = `pandoc -f odt -t html --wrap=none "#{odt_file}" |sed 's|<blockquote>||g ; s|</blockquote>||g ; s|</em><em>||g ; s|<em><em>|<em>|g ; s|</em></em>|</em>|g ; s|<sup>||g ; s|</sup>||g ; s|<sub>||g ; s|</sub>||g' |pandoc -f html -t markdown --wrap=none |sed 's/^#/\\n#/'`
    if $?.exitstatus == 0
        return output
    else
        raise "pandoc failed: #{output}"
    end
end

# Calls odt_to_markdown on odt_file
# Then adds title_page to the start, followed by two newlines
# Then adds two newlines, credits_page, two more newlines, thanks_page and finally, two more newlines
# Having done all that, it returns the markdown text as a String
def prepare_markdown_script(odt_file, title_page: nil, credits_page: nil, thanks_page: nil)
    markdown = odt_to_markdown(odt_file)
    if title_page != nil
        markdown.prepend(title_page, "\n\n")
    end
    if credits_page != nil    
        markdown.concat("\n\n", credits_page)
    end
    if thanks_page != nil
        markdown.concat("\n\n", thanks_page, "\n")
    end
    
    return markdown
end

# Converts a String of mardown text into a list of Strings for the chapters, in markdown format
# Headings are assumed to be chapter starts, but chapters with no content are added to the start of the next chapter
#   Under the assumtion that they mark the start of a part, rather than a chapter
# Chapter zero is the title page
def markdown_to_chapters(markdown)
    # Index zero becomes the title page
    chapters = [""]
    
    # This will become false if the last line that wasn't empty was a heading
    was_heading = false
    
    markdown.each_line do |line|
        # Most Heading indicate the start of a chapter
        if line.start_with?("#")
            # Though if they're followed by another, they're the start of a part
            unless was_heading
                chapters.append("")
            end
            was_heading = true
        # Regular non-empty lines are definitely NOT headings, but empty lines are treated specially
        #   They DO NOT reset was_heading to false
        elsif not line.strip.empty?
            was_heading = false
        end
        
        # Add the line to the current chapter
        chapters.last.concat(line)
    end
    
    # We're done, so return the chapters
    return chapters
end

# Converts a String filled with markdown text into plain text, then returns it as a String
def markdown_to_plaintext(markdown)
    
    plaintext = ""
    Open3.popen3("pandoc -f markdown -t plain --wrap=none --") do |stdin, stdout, stderr, wait_thr|
        stdin.puts markdown
        stdin.close
        
        plaintext = stdout.read
        
        unless wait_thr.value.exitstatus == 0
            raise "pandoc failed: #{stderr.read}"
        end
    end
    
    # Pandoc is failing to weed out this little bit of markdown superscript
    #   This is despite all superscript having been stripped out during the HTML pass, just before producing markdown
    #   To my mind, this indicates Pandoc is being too clever by half and trying *far* too hard to be helpful
    plaintext.gsub!(/\^(th)/i, "th")
    
    return plaintext
end



#  _____________________
# /                     \
# |  Plaintext Methods  |
# \_____________________/
# Performs various tasks designed to simplify text manipulation in preparation for reading of text by a TTS engine:
#   Curly bracket replacement of words like so: "word{a replacement}" -> "a replacement"
#   Removal of doble quotes, because they're problematic for many TTS engines
#   Adding [paragraph_end] on a serarate line, after paragraphs, to signal the need for a brief pause
#   Put text in square brackets on lines of their own
#   Removal of leading and trailing whitespace on each line
#   Put each sentence on its own line
#   Blank line removal is performed at various stages along the way, to keep the text clean of them
def preprocess!(text, curly_replace=true, comments=false)
    # Character substitution for simplification
    #  But pausing for three periods is too long, so make this just two
    text.gsub!(/#{ELIPSIS}/, "..")
    text.gsub!(/#{OPEN_QUOTE1}/, "'")
    text.gsub!(/#{CLOSE_QUOTE1}/, "'")
    # But we're stripping out double quotes of all sorts
    text.gsub!(/#{OPEN_QUOTE2}/, "")
    text.gsub!(/#{CLOSE_QUOTE2}/, "")
    text.gsub!(/\"/, "")
    
    # Comment line removal
    if comments
        text.gsub!(/^[ \t]*#.*/, "")
    end
    # Blank line removal
    text.gsub!(/^[ \t]*\n/, "")
    # Curly bracket word replacement
    if curly_replace
        text.gsub!(/\b[a-zA-Z0-9']*{([a-zA-Z0-9 ']*)}/, "\\1")
    end
    # Blank line removal
    text.gsub!(/^[ \t]*\n/, "")
    # Paragraph end
    text.gsub!(/$/, "[paragraph_end]")
    # Put square bracket text on it's own lines
    text.gsub!(/\[/, "\n[")
    text.gsub!(/\]/, "]\n")
    # Remove leading and trailing spaces and tabs
    text.gsub!(/^[ \t]*/, "")
    text.gsub!(/[ \t]*$/, "")
    # Split on sentence end, colon and semicolon
    text.gsub!(/\.[ \t]+/, ".\n")
    text.gsub!(/\![ \t]+/, "!\n")
    text.gsub!(/\?[ \t]+/, "?\n")
    text.gsub!(/\:[ \t]+/, "\n")
    text.gsub!(/\;[ \t]+/, "\n")
    # Blank line removal
    text.gsub!(/^[ \t]*\n/, "")
    # Scene break directive
    text.gsub!("* * *", "[scene_break]")
    # Pointless paragraph end removal
    text.gsub!(/\[paragraph_end\]\n\[paragraph_end\]/, "[paragraph_end]")
    text.gsub!(/\[scene_break\]\n\[paragraph_end\]/, "[scene_break]")

    return text
end


