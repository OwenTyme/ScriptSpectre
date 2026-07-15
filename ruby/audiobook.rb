
#  _________________________
# /                         \
# |  Ruby Library Requires  |
# \_________________________/
# Used for file manipulation
require "fileutils"
require "tmpdir"



#  __________________
# /                  \
# |  Local Requires  |
# \__________________/
# Text manipulation methods for processing audio scripts in preparation to be read
require "#{File.absolute_path(File.dirname(__FILE__))}/audio-script.rb"
require "#{File.absolute_path(File.dirname(__FILE__))}/voice.rb"
require "#{File.absolute_path(File.dirname(__FILE__))}/ui.rb"



#  _____________________________
# /                             \
# |  Audio Script Manipulation  |
# \_____________________________/
# Turn an ODT file into markdown, split by chapter
def audiobook_script_to_chapter_markdown(target_dir, odt_file, title_page: nil, credits_page: nil, thanks_page: nil)
    chapters = markdown_to_chapters(prepare_markdown_script(odt_file, title_page: title_page,
            credits_page: credits_page, thanks_page: thanks_page))
    unless Dir.exist?(target_dir)
        FileUtils.mkdir_p(target_dir)
    end
    chapters.each_index do |index|
        File.write("#{target_dir}/#{String(index).rjust(3, "0")}.md", chapters[index])
    end
end

# Turns markdown into an arracy of text lines specifying speaker (or sound effect) in square brackets, followed by text
# This assumes the speaker for lines without one specified should be "narrator"
# Also adds lines for "[lead_in]" and "[lead_out]" at the beginning and end
def markdown_to_voice_lines(markdown)
    text = markdown_to_plaintext(markdown)
    # Adjust the layout of the text in preparation for reading, to isolate each line
    preprocess!(text)
    text.prepend("[lead_in]\n")
    text.concat("[lead_out]")
    
    lines = Array.new
    current_speaker = "narrator"
    text.split("\n").each do |line|
        # This indicates a voice name, but may be a sound effect
        if line.start_with?("[") and line.end_with?("]")
            voice_name = line.delete_prefix("[").delete_suffix!("]")
            voice = VOICES[voice_name]
            # If this is a sound effect, then set it up for that and move on, without touching the current speaker
            if voice != nil and voice.sound_effect?
                lines.push("[#{voice_name}]")
            # Otherwise, set the current speaker
            else
                current_speaker = voice_name
            end
        else
            lines.push("[#{current_speaker}] #{line}")
        end
    end
    
    return lines
end



#  ________________
# /                \
# |  Audio Output  |
# \________________/
# FIX ME: Make the file extensions for markdown and text files configurable
# Uses TTS engines, sound effects, filtering and enhancement to turns an ODT file into audio tracks for chapters
def novel_to_audiobook(odt_file, chapters,
            mode_tts: false, mode_vc: false, mode_enhance: false, mode_final: false,
            mode_review: false, mode_review_all: false, mode_review_sfx: false,
            overwrite_tts: false, overwrite_vc: false, overwrite_enhance: false,
            title_page: nil, credits_page: nil, thanks_page: nil)
    unless chapters.is_a?(Array)
        raise "chapters MUST be an Array!"    
    end
    puts "Processing audiobook script '#{odt_file}'..."
    if odt_file == nil
        raise "odt_file cannot be nil!"
    end
    puts odt_file
    unless File.exist?(odt_file)
        raise "Audio script file doesn't exist!"
    end
    
    # Update the chapter cache, if required
    unless FileUtils.uptodate?("#{$chapter_cache}/000.md", [odt_file])
        puts "    Updating chapter cache..."
        FileUtils.rm(Dir.glob("#{$chapter_cache}/*.md"))
        audiobook_script_to_chapter_markdown($chapter_cache, odt_file, title_page: title_page,
                credits_page: credits_page, thanks_page: thanks_page)
    end
    
    unless Dir.exist?($line_cache)
        FileUtils.mkdir_p($line_cache)
    end
    
    chapters.each do |chapter|
        # Run through the text and prepare voice lines, consisting of a single speaker and their lines
        #   Sound effects get lines to themselves
        lines = markdown_to_voice_lines(File.read("#{$chapter_cache}/#{String(chapter).rjust(3, "0")}.md"))
        
        # Clean up old line files from the chapter, to prevent excess lines from sticking around
        FileUtils.rm(Dir.glob("#{$line_cache}/#{String(chapter).rjust(3, "0")}-*.txt"))
        
        # Write the voice lines to disk, as one-line text files
        lines.each_index do |index|
            line = VoiceLine.from_str("#{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}", lines[index])
            line.write($line_cache)
        end
        
        
        # Audio extension and format come from the config file
        # Extension is just the file extension, minus the "."
        audio_ext = setting("audio.ext", "flac")
        # The audio format is just a set of SoX switches
        audio_format = setting("audio.format", "-b 16 -c 1 -r 48000")
        
        
        # Review algorithm:
        #   If audio file doesn't exist, generate it
        #   Play audio for user
        #   Ask for guidance, offering to replay or regenerate audio
        #   Repeat as required, until user approves
        
        
        # Read the text as audio and sound effects
        if mode_tts
            # Make the directory to hold raw output from TTS, with only minimal filtering
            unless Dir.exist?($raw_audio_dir)
                FileUtils.mkdir_p($raw_audio_dir)
            end
            
            # Run over the lines and generate audio
            lines.each_index do |index|
                generated = false
                # Read the VoiceLine from disk, because we can't guarantee it's fully up to date!
                # The end user is allowed to edit the lines on disk, during operation, to get better pronunciation!
                line = VoiceLine.read($line_cache, "#{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}")
                if (not line.audio_exist?($raw_audio_dir)) or overwrite_tts
                    puts "Reading #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}: \"#{String(line)}\""
                    line.say($raw_audio_dir, audio_ext: audio_ext)
                    generated = true
                else
                    puts "Skipping #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")} for existing audio..."
                end
                
                # If the user is reviewing lines, play and request approval, replay or redo until they're happy
                if (mode_review and generated) or (mode_review and mode_review_all)
                    # However, we should skip reviewing sound effects, unless requested, because they're a known quantity
                    if (not line.sound_effect?) or (line.sound_effect? and mode_review_sfx)
                        # Replay until told otherwise
                        replay = true
                        while replay
                            result = review_audio("#{$raw_audio_dir}/#{line.file_name}.#{audio_ext}",
                                    backtitle: "Line #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}: #{String(line)}",
                                    question: "Are you happy with the sound of the line?")
                            # Exit if the user hits ESC at the dialog box, indicating they want to quit
                            if result == REVIEW_EXIT
                                # We delete the last line they reviewed, because the user didn't approve it
                                FileUtils.rm("#{$raw_audio_dir}/#{line.file_name}.#{audio_ext}")
                                exit true
                            # Approval is simple: we just stop looping
                            elsif result == REVIEW_YES
                                replay = false
                            # For a redo, we reload the line from disk (allowing the user edits at runtime)
                            # Then we run the TTS engine again and continue, the same as a replay
                            elsif result == REVIEW_REDO
                                line = VoiceLine.read($line_cache, "#{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}")
                                puts "Reading #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}: \"#{String(line)}\""
                                line.say($raw_audio_dir, audio_ext: audio_ext)
                            # Runtime error, because something isn't quite as expected
                            else
                                raise "Unexpected response from review_audio method: #{result}"
                            end
                        end
                    end
                end
            end
        end
        
        
        # Voice convert (or filter) raw TTS output
        if mode_vc
            # Make the directory to hold raw output from TTS, with only minimal filtering
            unless Dir.exist?($filtered_audio_dir)
                FileUtils.mkdir_p($filtered_audio_dir)
            end
            
            # Run over the lines and generate audio
            lines.each_index do |index|
                # Read the VoiceLine from disk, because we can't guarantee it's fully up to date!
                # The end user is allowed to edit the lines on disk, during operation, to get better pronunciation!
                line = VoiceLine.read($line_cache, "#{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}")
                if line.will_vc?
                    if overwrite_vc or (not line.vc_uptodate?($raw_audio_dir, $filtered_audio_dir, audio_ext: audio_ext))
                        puts "Filtering #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}..."
                        line.voice_convert($raw_audio_dir, $filtered_audio_dir, audio_ext: audio_ext)
                    else
                        puts "Skipping filtering #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")} for existing audio..."
                    end
                end
            end
        end
        
        
        # Enhance raw TTS or VC output
        if mode_enhance
            # Make the directory to hold raw output from TTS, with only minimal filtering
            unless Dir.exist?($enhanced_audio_dir)
                FileUtils.mkdir_p($enhanced_audio_dir)
            end
            
            # Run over the lines and generate audio
            lines.each_index do |index|
                # Read the VoiceLine from disk, because we can't guarantee it's fully up to date!
                # The end user is allowed to edit the lines on disk, during operation, to get better pronunciation!
                line = VoiceLine.read($line_cache, "#{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}")
                if line.will_enhance?
                    if overwrite_enhance or (not line.enhance_uptodate?($raw_audio_dir, $filtered_audio_dir, $enhanced_audio_dir, audio_ext: audio_ext))
                        puts "Enhancing #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}..."
                        line.enhance($raw_audio_dir, $filtered_audio_dir, $enhanced_audio_dir, audio_ext: audio_ext)
                    else
                        puts "Skipping enhancing #{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")} for existing audio..."
                    end
                end
            end
        end
        
        
        # Assemble the best audio we've got into a final track
        #   We prefer enhanced audio over VC audio, which is preferred over raw TTS audio
        if mode_final
            # Make the directory to hold final, complete audio tracks for chapters
            unless Dir.exist?($final_audio_dir)
                FileUtils.mkdir_p($final_audio_dir)
            end
            
            # Array to hold the file names of the audio files
            files = Array.new
            
            # Run over the lines and generate audio
            lines.each_index do |index|
                # Read the VoiceLine from disk, because we can't guarantee it's fully up to date!
                # The end user is allowed to edit the lines on disk during operation, to get better pronunciation!
                line = VoiceLine.read($line_cache, "#{String(chapter).rjust(3, "0")}-#{String(index).rjust(4, "0")}")
                best_audio = line.best_audio($raw_audio_dir, $filtered_audio_dir, $enhanced_audio_dir, audio_ext: audio_ext)
                
                unless best_audio == nil
                    files.push(best_audio)
                end
            end
            #files = "\"" + files.join("\" \"") + "\""
            puts "Chapter #{String(chapter).rjust(3, "0")}: Combining line audio into chapter track '#{$final_audio_dir}/#{String(chapter).rjust(3, "0")}.#{audio_ext}'..."
            
            # Unfortunately, because SoX likes to whine about mis-matched sample rates
            # Forcing us to transcode to a temp directory as an intermediate step, before building the final track
            Dir.mktmpdir do |temp|
                files.each do |file|
                    system("sox \"#{file}\" #{audio_format} \"#{temp}/#{File.basename(file)}\"")
                    if $?.exitstatus != 0
                        raise "SoX transcode failure!"
                    end    
                end
                system("sox \"#{temp}\"/*.#{audio_ext} #{audio_format} \"#{$final_audio_dir}/#{String(chapter).rjust(3, "0")}.#{audio_ext}\"")
                if $?.exitstatus != 0
                    raise "SoX final encode failure!"
                end
            end
        end
    
    end
    

end



#  ___________________________
# /                           \
# |  Application Entry Point  |
# \___________________________/
# This should be called at the end of an audiobook build script, once all required constants and variables have been set
# This is the command-line interface for the application that does the real work
def main(odt_file, title_page: nil, credits_page: nil, thanks_page: nil)
    # Save the name of the starting script, under the assumption that's the true entry point
    #   This is only used for the --help switch, to helpfully display the name of the script
    launched_from = caller.last.gsub(/:.*/, "")
    
    # Should we run TTS to generate raw audio?
    mode_tts = false
    # Should we run Voice Conversion or filtering processes?
    mode_vc = false
    # Should we run Enhacement or post filtering processes?
    mode_enhance = false
    # Should we generate final audio tracks for each chapter
    mode_final = false
    # Should TTS audio be reviewed?
    mode_review = false
    # Should pre-existing TTS audio be reviewed?
    mode_review_all = false
    # Should even designated sound effects be reviewed?
    mode_review_sfx = false
    # Should we overwrite existing, but up to date TTS audio?
    overwrite_tts = false
    # Should we overwrite existing, but up to date VC/filtered audio?
    overwrite_vc = false
    # Should we overwrite existing, but up to date Enhanced/post filtered audio?
    overwrite_enhance = false
    
    # Used for voice testing
    mode_test = false
    #   The name of the voice to test; nil indicates no test
    test_voice = nil
    #   Text for the test voice to read
    test_text = nil
    #   Directory for test audio to be stored in
    test_dir = $test_audio_dir
    
    # Chapter numbers to process into audio
    #   Markdown files can be manually added to the chapter cache for the sake of testing
    #   However, such file names (minus extension!) should always be at least three characters in length
    #   That's because chapter numbers are padded with zeros to a minimum of three characters
    chapters = Array.new
    
    # If no arguments specified, the user probably needs help with switches
    if ARGV.length == 0
        ARGV.push("--help")
    end
    
    # Process command-line arguments
    while ARGV.length > 0
        arg=ARGV.shift
        if arg == "-t" or arg == "--tts"
            mode_tts = true
        elsif arg == "-f" or arg == "--filter"
            mode_vc = true
        elsif arg == "-e" or arg == "--enhance"
            mode_enhance = true
        elsif arg == "-F" or arg == "--final"
            mode_final = true
        elsif arg == "-ot" or arg == "--overwrite-tts"
            mode_tts = true
            overwrite_tts = true
        elsif arg == "-of" or arg == "--overwrite-filter"
            mode_vc = true
            overwrite_vc = true
        elsif arg == "-oe" or arg == "--overwrite-enhance"
            mode_enhance = true
            overwrite_enhance = true
        elsif arg == "-r" or arg == "--review"
            mode_tts = true
            mode_review = true
        elsif arg == "-ra" or arg == "--review-all"
            mode_tts = true
            mode_review = true
            mode_review_all = true
        elsif arg == "-rs" or arg == "--review-sfx"
            mode_tts = true
            mode_review = true
            mode_review_sfx = true
        elsif arg == "--test"
            mode_tts = true
            mode_test = true
        elsif arg == "--text"
            mode_tts = true
            mode_test = true
            test_text = ARGV.shift
            if test_text == nil
                raise "Missing argument for --text switch!"
            end
        elsif arg == "--test-dir"
            mode_tts = true
            mode_test = true
            test_dir = ARGV.shift
            if test_dir == nil
                raise "Missing argument for --test-dir switch!"
            end
        elsif arg == "-h" or arg == "--help"
            puts "Usage: #{File.basename(launched_from)} [OPTIONS] CHAPTERS..."
            puts ""
            puts "Turns chapters of an audio book script into audio tracks."
            puts ""
            puts "    -t --tts                  Text to speech (TTS) tasks should be run"
            puts "    -f --filter               Filter tasks should be run, including voice conversion"
            puts "    -e --enhance              Audio enhancement tasks should be run"
            puts "    -F --final                Finalization tasks should be run, to produce chater audio tracks"
            puts "    -ot --overwrite-tts       Overwrite existing TTS audio"
            puts "    -of --overwrite-filter    Overwrite existing filter audio"
            puts "    -oe --overwrite-enhance   Overwrite existing enhanced audio"
            puts "    -r --review               TTS tasks should be run and manually reviewed by the user"
            puts "    -ra --review-all          TTS tasks should be run and all existing audio will be manually reviewed by the user"
            puts "    -rs --review-sfx          TTS tasks should be run and manually reviewed by the user, including sound effects"
            puts "    --test                    Test voices instead of processing chapters"
            puts "    --text text               As --test, but sets text for voice tests, defaults to 3 Harvard sentences"
            puts "    --text-dir DIR            As --test, but sets directory to store audio, defaults to 'test'"
            puts "    -h --help                 Display this help message"
            puts ""
            exit
        elsif arg.start_with?("-")
            puts "Unknown option: #{arg}"
            exit false
        # Fail with a non-zero exit code for unexpected switches
        else
            chapters.push(arg)
        end
    end
    
    # Indicates no active mode specified, so default to TTS
    if (not mode_tts) and (not mode_vc) and (not mode_enhance) and (not mode_final)
        mode_tts = true
        mode_final = true
    end
    
    # Test a voice, if specified
    if mode_test
        unless Dir.exist?(test_dir)
            FileUtils.mkdir_p(test_dir)
        end
        
        # Test the voice, but we want some visible feedback for the user
        SETTINGS["voice.say.info"] = true
        SETTINGS["voice.vc.info"] = true
        SETTINGS["voice.enhance.info"] = true
        
        chapters.each do |test_voice|
            # TTS is assumed, but filter and enhance steps are optional
            tts_file = "#{test_dir}/#{test_voice}-tts.#{setting("audio.ext", "flac")}"
            filter_file = nil
            enhance_file = nil
            if mode_vc
                filter_file = "#{test_dir}/#{test_voice}-filtered.#{setting("audio.ext", "flac")}"
            end
            if mode_enhance
                enhance_file = "#{test_dir}/#{test_voice}-enhanced.#{setting("audio.ext", "flac")}"
            end
            test_voice(test_voice, tts_file, vc_file: filter_file, enhance_file: enhance_file, text: test_text)
        end
        
    # Otherwise, we work on an audiobook
    else
        novel_to_audiobook(odt_file, chapters, mode_tts: mode_tts, mode_vc: mode_vc, mode_enhance: mode_enhance, mode_final: mode_final, mode_review: mode_review, mode_review_all: mode_review_all, overwrite_tts: overwrite_tts, overwrite_vc: overwrite_vc, overwrite_enhance: overwrite_enhance, title_page: title_page, credits_page: credits_page, thanks_page: thanks_page)
    end
end
