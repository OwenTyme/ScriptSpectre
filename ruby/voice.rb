
#  _________________________
# /                         \
# |  Ruby Library Requires  |
# \_________________________/
# Used for comparing audio file dates
require "fileutils"



#  __________________
# /                  \
# |  Local Requires  |
# \__________________/
# Due to the sheer size, the constant holding the Harvard sentences is in another file
# Also includes a method to obtain a specified count of Hardvard sentences in a String, separated by spaces
require "#{File.absolute_path(File.dirname(__FILE__))}/harvard.rb"



#  ____________________
# /                    \
# |  Global Constants  |
# \____________________/
# The hash of voices
VOICES={}



#  _______________
# /               \
# |  Voice Class  |
# \_______________/
# The Voice class handles storing data for indvidual voices and the say method allows transforming text into speech
# FIX ME?: Add support for subordinate voices for other emotions?
class Voice
    def initialize(say_command, pronunciation_command: SCRIPT["pronounce"], model: nil,
                speaker: "", pre_filters: "norm -8", length_scale: nil, tempo: nil, vc_command: "",
                vc_filters: nil, enhance_command: "", post_filters: "norm -3.2", fade_in: nil, fade_out: nil,
                pre_sentence_silence: nil, sentence_silence: nil, sound_effect: false)
        # Text to speech (TTS)
        #  The shell command that's run for the TTS engine, normally a purpose-built script to wrap a TTS engine
        self.say_command = say_command
        #  Text preprocessor
        #   nil or an empty string may be used to specify no pronunciation command
        self.pronunciation_command = pronunciation_command
        #  TTS engine model: details are specific to the engine used, but passed via --model option
        self.model = model
        #  TTS engine speaker: details are specific to the engine used, but passed via --speaker option
        self.speaker = speaker
        #  SoX filters used on the audio as part of the TTS engine script
        self.pre_filters = pre_filters
        #  Speed control for TTS engine, in the form of changing the length by a floating-point scaling factor
        if length_scale == nil and tempo == nil
            self.length_scale = nil
        elsif length_scale != nil and tempo == nil
            self.length_scale = length_scale
        elsif length_scale == nil and tempo != nil
            self.tempo = tempo
        else
            raise "length_scale and tempo cannot both be set!  Pick one or the other!"
        end
        self.fade_in = fade_in
        self.fade_out = fade_out
        self.pre_sentence_silence = pre_sentence_silence
        self.sentence_silence = sentence_silence
        self.sound_effect = sound_effect
        
        # Voice conversion
        #  The shell command that's run for the voice conversion, normally a purpose-built script
        #   Parameters are expected to be like so: --in [input file] --out [output file] --filters [SoX filters]
        #  If this is empty, then no voice conversion process will be used
        self.vc_command = vc_command
        #  SoX filters used on the audio as part of the VC engine script
        self.vc_filters = vc_filters
        
        # Voice enhancement
        #  The shell command that's run for audio enhancement, normally a purpose-built script
        #   Parameters are expected to be like so: [input file] [output file] [SoX filters]
        #  If this is empty, then SoX will be used to convert sample rate for final files
        self.enhance_command = enhance_command
        #  SoX filters used on the audio as part of the enhance script
        self.post_filters = post_filters
    end
    

    # Accessors for say command
    def say_command()
        @say_command
    end
    
    def say_command=(say_command)
        unless say_command.is_a?(String)
            raise "say_command MUST be a String!"
        end
        if say_command == nil
            raise "say_command can't be nil!"
        end
        @say_command = say_command
    end
    
    # Accessors for voice conversion command
    def vc_command()
        @vc_command
    end
    
    def vc_command=(vc_command)
        unless vc_command.is_a?(String)
            raise "vc_command MUST be a String!"
        end
        @vc_command = vc_command
    end
    
    def will_vc?()
        if vc_command == nil or vc_command == ""
            return false
        end
        return true
    end
    
    # Accessors for enhance command
    def enhance_command()
        @enhance_command
    end
    
    def enhance_command=(enhance_command)
        unless enhance_command.is_a?(String)
            raise "enhance_command MUST be a String!"
        end
        @enhance_command = enhance_command
    end
    
    def will_enhance?()
        # This gets special handling, because all tracks must normally go through some enhancement
        #   Even if its just filtering with SoX
        if (enhance_command == nil or enhance_command == "") and (post_filters == nil or post_filters == "")
            return false
        end
        return true
    end
    
    # Accessors for pronunciation command
    def pronunciation_command()
        @pronunciation_command
    end
    
    def pronunciation_command=(pronunciation_command)
        unless pronunciation_command.is_a?(String) || pronunciation_command == nil
            raise "pronunciation_command MUST be a String!"
        end
        @pronunciation_command = pronunciation_command
    end
    
    # Accessors for TTS model
    def model()
        @model
    end
    
    def model=(model)
        unless model == nil or model.is_a?(String)
            raise "model MUST be a String!"
        end
        @model = model
    end
    
    # Accessors for TTS speaker
    def speaker()
        @speaker
    end
    
    def speaker=(speaker)
        if speaker == nil
            speaker = ""
        end
        @speaker = String(speaker)
    end
    
    # Accessors for TTS SoX filters
    def pre_filters()
        @pre_filters
    end
    
    def pre_filters=(pre_filters)
        if pre_filters == nil
            pre_filters = ""
        end
        @pre_filters = String(pre_filters)
    end
    
    # Accessors for voice conversion TTS SoX filters
    def vc_filters()
        @vc_filters
    end
    
    def vc_filters=(vc_filters)
        if vc_filters == nil
            vc_filters = ""
        end
        @vc_filters = String(vc_filters)
    end
    
    # Accessors for enhance SoX filters
    def post_filters()
        @post_filters
    end
    
    def post_filters=(post_filters)
        if post_filters == nil
            post_filters = ""
        end
        @post_filters = String(post_filters)
    end
    
    # Accessors for TTS length scale
    def length_scale()
        @length_scale
    end
    
    def length_scale=(length_scale)
        unless length_scale == nil or length_scale.is_a?(Float)
            raise "length_scale MUST be a Float!"
        end
        @length_scale = length_scale
    end
    
    def tempo()
        1.0/self.length_scale
    end
    
    def tempo=(tempo)
        unless tempo == nil or tempo.is_a?(Float)
            raise "tempo MUST be a Float!"
        end
        if tempo == nil
            self.length_scale=nil
        else
            self.length_scale=1.0/tempo
        end
    end
    
    # Accessors for fade in
    def fade_in()
        @fade_in
    end
    
    def fade_in=(fade_in)
        unless fade_in == nil or fade_in.is_a?(Float)
            raise "fade_in MUST be a Float or nil!"
        end
        if fade_in != nil and fade_in < 0.0
            fade_in = 0.0
        end
        @fade_in = fade_in
    end
    
    # Accessors for fade out
    def fade_out()
        @fade_out
    end
    
    def fade_out=(fade_out)
        unless fade_out == nil or fade_out.is_a?(Float)
            raise "fade_out MUST be a Float or nil!"
        end
        if fade_out != nil and fade_out < 0.0
            fade_out = 0.0
        end
        @fade_out = fade_out
    end
    
    # Accessors for pre sentence silence
    def pre_sentence_silence()
        @pre_sentence_silence
    end
    
    def pre_sentence_silence=(pre_sentence_silence)
        unless pre_sentence_silence == nil or pre_sentence_silence.is_a?(Float)
            raise "pre_sentence_silence MUST be a Float or nil!"
        end
        if pre_sentence_silence != nil and pre_sentence_silence < 0.0
            pre_sentence_silence = 0.0
        end
        @pre_sentence_silence = pre_sentence_silence
    end
    
    # Accessors for post sentence silence
    def sentence_silence()
        @sentence_silence
    end
    
    def sentence_silence=(sentence_silence)
        unless sentence_silence == nil or sentence_silence.is_a?(Float)
            raise "sentence_silence MUST be a Float or nil!"
        end
        if sentence_silence != nil and sentence_silence < 0.0
            sentence_silence = 0.0
        end
        @sentence_silence = sentence_silence
    end
    
    # Accessors for sound effect flag
    def sound_effect?()
        @sound_effect
    end
    
    def sound_effect=(sound_effect)
        if sound_effect
            @sound_effect = true
        else
            @sound_effect = false
        end
    end
        
    
    # Provides the name of the TTS engine
    def engine_name()
        engine = ""
        @say_command.split.each do |arg|
            # If the argument is the filename of a shell/ruby/python script, the basename without the extension will be the engine name
            if arg.end_with?(".sh", ".rb", ".py")
                arg = File.basename(arg)
                engine = engine + arg[0, arg.size - File.extname(arg).size] + " "
            end
        end
        # Remove trailing spaces from the engine name
        engine.gsub!(/ +$/, '')
        
        return engine
    end
    
    # The name of the voice conversion engine
    def vc_name()
        engine = ""
        @vc_command.split.each do |arg|
            # If the argument is the filename of a shell or ruby script, the basename without the extension will be the engine name
            if arg.end_with?(".sh", ".rb")
                arg = File.basename(arg)
                engine = engine + arg[0, arg.size - File.extname(arg).size] + " "
            end
        end
        # Remove trailing spaces from the engine name
        engine.gsub!(/ +$/, '')
        
        return engine
    end
    
    # The name of the enhance engine
    def enhance_name()
        engine = ""
        @enhance_command.split.each do |arg|
            # If the argument is the filename of a shell or ruby script, the basename without the extension will be the engine name
            if arg.end_with?(".sh", ".rb")
                arg = File.basename(arg)
                engine = engine + arg[0, arg.size - File.extname(arg).size] + " "
            end
        end
        # Remove trailing spaces from the engine name
        engine.gsub!(/ +$/, '')
        
        return engine
    end
    
    # Runs the TTS engine to read the given text to an audio file
    def say(text, output_audio)
        # At this point, if text isn't a String, then something is wrong
        unless text.is_a?(String) or text.is_a?(File)
            raise "text MUST be a String or File!"
        end
        # If text is a File, then read it into a String and continues
        if text.is_a?(File)
            text = File.read(text)
        else
            text = text.dup
        end
        
        # We need no leading or trailing spaces, because that can confuse the TTS engines, leading to strange utterances
        text.gsub!(/^ +/, '')
        text.gsub!(/$ +/, '')
        
        # First, get the name (or names!) of the TTS engine, for the pronunciation script
        engine = engine_name()
        
        # Assemble the command to run, as an array
        command = ["echo \"#{text}\""]
        if @pronunciation_command != nil and @pronunciation_command != ""
            command.push "|#{@pronunciation_command}"
        end
        command.push "|#{@say_command}"
        if @fade_in != nil
            command.push "--fade_in #{@fade_in}"
        end
        if @fade_out != nil
            command.push "--fade_out #{@fade_out}"
        end
        if @pre_sentence_silence != nil
            command.push "--pre_sentence_silence #{@pre_sentence_silence}"
        end
        if @sentence_silence != nil
            command.push "--sentence_silence #{@sentence_silence}"
        end
        if @model != nil
            command.push "--model \"#{@model}\""
        end
        if @length_scale != nil
            command.push "--length_scale \"#{@length_scale}\""
        end
        command.push "--out \"#{output_audio}\""
        command.push "--speaker \"#{@speaker}\""
        command.push "--filters #{@pre_filters}"
        command = command.join(" ")
        
        if SETTINGS["voice.say.info"]
            puts "'#{engine}' speaking for file '#{output_audio}': #{text}"
        end
        # Read the line
        if SETTINGS["voice.say.debug"]
            puts "Command: #{command}"
        end
        system("#{command}")
        unless $?.exitstatus == 0
            raise "TTS engine '#{engine}' failed!"
        end
        
        return self
    end
    
    # Runs the voice conversion engine to convert the voice in the input file, storing the result as the output file
    def voice_convert(input_audio, output_audio)
        if vc_command == nil or vc_command == ""
            if SETTINGS["voice.vc.debug"]
                puts "SoX filtering in place of voice conversion: '#{input_audio}' -> '#{output_audio}'"
            end
            system("sox \"#{input_audio}\" \"#{output_audio}\" #{@vc_filters}")
            unless $?.exitstatus == 0
                raise "SoX VC filtering error!"
            end
            return self
        end
        unless File.exist?(input_audio)
            raise "Input audio file doesn't exist: '#{input_audio}'"
        end
        
        # First, get the name (or names!) of the VC engine, just for display
        engine = vc_name()
        if SETTINGS["voice.vc.info"]
            puts "'#{engine}' performing filtering: '#{input_audio}' -> '#{output_audio}'"
        end
        
        # Run the voice conversion
        system("#{@vc_command} --in \"#{input_audio}\" --out \"#{output_audio}\" --filters #{@vc_filters}")
        unless $?.exitstatus == 0
            raise "VC engine '#{engine}' failed!"
        end
        
        return self
    end
    
    # Runs the enhance engine to improve the quality of the input file, storing the result as the output file
    def enhance(input_audio, output_audio)
        if enhance_command == nil or enhance_command == ""
            if SETTINGS["voice.enhance.debug"]
                puts "SoX performing enhancement filtering: '#{input_audio}' -> '#{output_audio}'"
            end
            system("sox \"#{input_audio}\" \"#{output_audio}\" #{@post_filters}")
            unless $?.exitstatus == 0
                raise "SoX enhance filtering error!"
            end
            return self
        end
        unless File.exist?(input_audio)
            raise "Input audio file doesn't exist: '#{input_audio}'"
        end
        
        # First, get the name (or names!) of the enhancement engine, just for display
        engine = enhance_name()
        if SETTINGS["voice.enhance.info"]
            puts "'#{engine}' performing enhancement: '#{input_audio}' -> '#{output_audio}'"
        end
        
        # Run the voice conversion
        system("#{@enhance_command} --in \"#{input_audio}\" --out \"#{output_audio}\" --filters #{@post_filters}")
        unless $?.exitstatus == 0
            raise "Enhance engine '#{engine}' failed!"
        end
        
        return self
    end
end



#  ___________________
# /                   \
# |  VoiceLine Class  |
# \___________________/
# Holds all the data for a complete line, including name of line, voice name and the test to say
class VoiceLine
    def initialize(file_name, voice_name, text)
        self.file_name = file_name
        self.voice_name = voice_name
        self.text = text
    end
    
    
    def file_name()
        @file_name
    end
    
    def file_name=(file_name)
        @file_name = String(file_name)
    end
    
    def voice_name()
        @voice_name
    end
    
    def voice_name=(voice_name)
        @voice_name = String(voice_name)
    end
    
    def voice()
        v = VOICES[self.voice_name]
        if v == nil
            raise "Voice '#{self.voice_name}' doesn't exist!"
        end
        return v
    end
    
    def sound_effect?()
        v = VOICES[self.voice_name]
        if v == nil
            return false
        end
        return v.sound_effect?
    end
    
    def will_vc?()
        v = VOICES[self.voice_name]
        if v == nil
            return false
        end
        return v.will_vc?
    end
    
    def will_enhance?()
        v = VOICES[self.voice_name]
        if v == nil
            return false
        end
        return v.will_enhance?
    end
    
    def text()
        @text
    end
    
    def text=(text)
        @text = String(text)
    end
    
    def audio_exist?(audio_dir, audio_ext: "flac")
        return File.exist?("#{audio_dir}/#{self.file_name}.#{audio_ext}")
    end
    
    def say(out_dir, audio_ext: "flac")
        unless Dir.exist?(out_dir)
            raise "Output directory for speaking doesn't exist: '#{out_dir}'"
        end
        self.voice.say(self.text, "#{out_dir}/#{self.file_name}.#{audio_ext}")
    end
    
    def voice_convert(raw_dir, out_dir, audio_ext: "flac")
        unless Dir.exist?(out_dir)
            raise "Output directory for voice conversion doesn't exist: '#{out_dir}'"
        end
        if self.voice.will_vc?
            unless File.exist?("#{raw_dir}/#{self.file_name}.#{audio_ext}")
                raise "Missing raw say audio file: '#{raw_dir}/#{self.file_name}.#{audio_ext}'"
            end
            self.voice.voice_convert("#{raw_dir}/#{self.file_name}.#{audio_ext}", "#{out_dir}/#{self.file_name}.#{audio_ext}")
        end
    end
    
    def enhance(raw_dir, vc_dir, out_dir, audio_ext: "flac")
        unless Dir.exist?(out_dir)
            raise "Output directory for voice enhancement doesn't exist: '#{out_dir}'"
        end
        if self.voice.will_enhance?
            if File.exist?("#{vc_dir}/#{self.file_name}.#{audio_ext}")
                self.voice.enhance("#{vc_dir}/#{self.file_name}.#{audio_ext}", "#{out_dir}/#{self.file_name}.#{audio_ext}")
            elsif File.exist?("#{raw_dir}/#{self.file_name}.#{audio_ext}")
                self.voice.enhance("#{raw_dir}/#{self.file_name}.#{audio_ext}", "#{out_dir}/#{self.file_name}.#{audio_ext}")
            else
                raise "Missing raw say audio file '#{raw_dir}/#{self.file_name}.#{audio_ext}' and voice converted audio file '#{vc_dir}/#{self.file_name}.#{audio_ext}'!"
            end
        end
    end
    
    def best_audio(raw_dir, vc_dir, enhance_dir, audio_ext: "flac")
        if File.exist?("#{enhance_dir}/#{self.file_name}.#{audio_ext}")
            return "#{enhance_dir}/#{self.file_name}.#{audio_ext}"
        elsif File.exist?("#{vc_dir}/#{self.file_name}.#{audio_ext}")
            return "#{vc_dir}/#{self.file_name}.#{audio_ext}"
        elsif File.exist?("#{raw_dir}/#{self.file_name}.#{audio_ext}")
            return "#{raw_dir}/#{self.file_name}.#{audio_ext}"
        else
            return nil
        end
    end
    
    def vc_uptodate?(raw_dir, vc_dir, audio_ext: "flac")
        return FileUtils.uptodate?("#{vc_dir}/#{self.file_name}.#{audio_ext}", ["#{raw_dir}/#{self.file_name}.#{audio_ext}"])
    end
    
    def enhance_uptodate?(raw_dir, vc_dir, enhance_dir, audio_ext: "flac")
        # If the VC file exists, compare to that
        if File.exist?("#{vc_dir}/#{self.file_name}.#{audio_ext}")
            return FileUtils.uptodate?("#{enhance_dir}/#{self.file_name}.#{audio_ext}", ["#{vc_dir}/#{self.file_name}.#{audio_ext}"])
        # Otherwise, compare to the tts file
        else
            return FileUtils.uptodate?("#{enhance_dir}/#{self.file_name}.#{audio_ext}", ["#{raw_dir}/#{self.file_name}.#{audio_ext}"])
        end
    end
    
    def to_str()
        return "[#{self.voice_name}] #{self.text}".strip()
    end
    
    def self.from_str(file_name, data)
        data = String(data).gsub(/\n/, " ")
        # Isolate the voice
        voice = data.gsub(/\n/, " ").scan(/\[[a-zA-Z_ ]*\]/)
        if voice.size() < 1
            raise "No voice specified!"
        elsif voice.size() > 1
            raise "Only one voice can be specified!"
        end
        voice = voice[0].gsub("[", "").gsub("]", "")
        # Remove the voice name from the text and eliminate pointless whitespace
        text = data.gsub(/\n/, " ").gsub(/\[[a-zA-Z_ ]*\]/, "").gsub(/^ */, "").gsub(/ *$/, "")
        
        VoiceLine.new(file_name, voice, text)
    end
    
    def self.read(in_dir, file_name, txt_ext: ".txt")
        data = File.read("#{in_dir}/#{file_name}.txt")
        self.from_str(file_name, data)
    end
    
    # Write the String representation of this VoiceLine to a file for later retrieval
    def write(out_dir, txt_ext: ".txt")
        unless Dir.exist?(out_dir)
            raise "Output directory for line text doesn't exist: '#{out_dir}'"
        end
        File.write("#{out_dir}/#{self.file_name}.txt", self.to_str())
    end
    
end



#  _________________
# /                 \
# |  Voice Methods  |
# \_________________/
# Copies one of the voices from the global voice hash, to make a nother by altering its properties
def copy_voice(dst_name, src_name, say_command: nil, pronunciation_command: nil, model: nil, speaker: nil,
            pre_filters: nil, length_scale: nil, vc_command: nil, vc_filters: nil, enhance_command: nil,
            post_filters: nil, fade_in: nil, fade_out: nil, pre_sentence_silence: nil, sentence_silence: nil,
            sound_effect: nil, clean_filters: false)
    if not VOICES.key?(src_name)
        raise "Voice not found!"
    end
    src = VOICES[src_name]
    dst = src.dup
    
    # For all named parameters, nil indicates no change, but supplying a value indicates replacement
    unless say_command == nil
        dst.say_command = say_command
    end
    unless pronunciation_command == nil
        dst.pronunciation_command = pronunciation_command
    end
    unless model == nil
        dst.model = model
    end
    unless speaker == nil
        dst.speaker = speaker
    end
    unless length_scale == nil
        dst.length_scale = length_scale
    end
    unless vc_command == nil
        dst.vc_command = vc_command
    end
    unless enhance_command == nil
        dst.enhance_command = enhance_command
    end
    unless fade_in == nil
        dst.fade_in = fade_in
    end
    unless fade_out == nil
        dst.fade_out = fade_out
    end
    unless pre_sentence_silence == nil
        dst.pre_sentence_silence = pre_sentence_silence
    end
    unless sentence_silence == nil
        dst.sentence_silence = sentence_silence
    end
    unless sound_effect == nil
        dst.sound_effect = sound_effect
    end
    
    # If clean filters are requested, existing filters are replaced when new filters are specified
    if clean_filters
        unless pre_filters == nil
            dst.pre_filters = pre_filters
        end
        unless vc_filters == nil
            dst.vc_filters = vc_filters
        end
        unless post_filters == nil
            dst.post_filters = post_filters
        end
    # If not, then they're additive, rather than replacements, getting tacked on to the end of existing filters
    else
        unless pre_filters == nil
            dst.pre_filters = "#{src.pre_filters} #{pre_filters}"
        end
        unless vc_filters == nil
            dst.vc_filters = "#{src.vc_filters} #{vc_filters}"
        end
        unless post_filters == nil
            dst.post_filters = "#{src.post_filters} #{post_filters}"
        end
    end
    
    VOICES[dst_name] = dst
end

# Tests the named voice using three Harvard sentences, producing audio at tts_file, vc_file and enhance_file
def test_voice(name, tts_file, vc_file: nil, enhance_file: nil, count: 3, text: nil)
    unless name.is_a?(String)
        raise "name MUST be a String!"
    end
    
    voice = VOICES[name]
    if voice == nil
        raise "Voice '#{name}' not found!"
    end
    if text == nil
        text = harvard_lines(count)
    end
    voice.say(text, tts_file)
    if (not vc_file == nil) and voice.will_vc?
        voice.voice_convert(tts_file, vc_file)
    else
        vc_file = nil
    end
    if enhance_file != nil and voice.will_enhance?
        if vc_file != nil
            voice.enhance(vc_file, enhance_file)
        else
            voice.enhance(tts_file, enhance_file)
        end
    end
end

def clone_voices(voice_dir, glob_pattern, base_voice,
            voice_prefix: nil, voice_suffix: nil, speaker_prefix: nil, speaker_suffix: nil,
            say_command: nil, pronunciation_command: nil, model: nil,
            pre_filters: nil, length_scale: nil, vc_command: nil, vc_filters: nil, enhance_command: nil,
            post_filters: nil, fade_in: nil, fade_out: nil, pre_sentence_silence: nil, sentence_silence: nil,
            sound_effect: nil, clean_filters: false)
    unless Dir.exist?(voice_dir)
        raise "Voice sample directory '#{voice_dir}' doesn't exist!"
    end
    if voice_prefix == nil
        voice_prefix = ""
    end
    if voice_suffix == nil
        voice_suffix = ""
    end
    if speaker_prefix == nil
        speaker_prefix = ""
    end
    if speaker_suffix == nil
        speaker_suffix = ""
    end
    base_voice = String(base_voice)
    files = Dir.glob(glob_pattern, base: voice_dir)
    files.each do |file|
        # We're replacing dashes with underlines, because dashes can't be used in voice names from audio scripts
        voice_name = File.basename(file, File.extname(file)).gsub("-", "_").gsub("'", "_").gsub("__", "_")
        copy_voice("#{voice_prefix}#{voice_name}#{voice_suffix}", base_voice,
                speaker: "#{speaker_prefix}#{voice_dir}/#{file}#{speaker_suffix}",
                say_command: say_command, pronunciation_command: pronunciation_command, model: model,
                pre_filters: pre_filters, length_scale: length_scale, vc_command: vc_command, vc_filters: vc_filters,
                enhance_command: enhance_command, post_filters: post_filters, fade_in: fade_in, fade_out: fade_out,
                pre_sentence_silence: pre_sentence_silence, sentence_silence: sentence_silence,
                sound_effect: sound_effect, clean_filters: clean_filters)
    end
end
