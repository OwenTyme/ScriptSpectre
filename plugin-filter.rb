#!/usr/bin/env ruby

=begin
Note to VC/filter engine plugin authors: before requiring this script, set your desired defaults for global variables!

The following variables used can have defaults set:
$model
$filters
$prompt

Setting $prompt to nil indicates that the --prompt switch should be disabled

=end


require "#{File.dirname(__FILE__)}/config.rb"

if ARGV.length == 0
ARGV.push("--help")
end

launched_from = caller.last.gsub(/:.*/, "")

# Set FILTER_COMMAND, if there's a reasonable option
engine=File.basename(launched_from.chomp(File.extname(launched_from)))
if engine.start_with?("vc-")
    engine.delete_prefix!("vc-")
    FILTER_COMMAND=VC_COMMANDS[engine]
elsif engine.start_with?("enhance-")
    engine.delete_prefix!("enhance-")
    FILTER_COMMAND=ENHANCE_COMMANDS[engine]
elsif engine.start_with?("filter-")
    engine.delete_prefix!("filter-")
    FILTER_COMMAND=FILTER_COMMANDS[engine]
end



$input=nil
$output=nil
useprompt=true
# This allows the prompt to be set by the calling script
if not defined?($prompt)
    $prompt = nil
# Setting $prompt to nil disables the --prompt switch, which is useful for enhancement scripts
elsif $prompt == nil
    useprompt = false
end
usemodel=true
# This allows the model to be set by the calling script
if not defined?($model)
    $model = nil
# Setting $model to nil disables the --model switch
elsif $model == nil
    usemodel = false
end


while ARGV.length > 0
    arg=ARGV.shift
    if arg == "-i" or arg == "--in"
        $input=ARGV.shift
        if $input == nil || $input == ""
            raise "Missing file argument for '--in' switch!"
        end
    elsif arg == "-o" or arg == "--out"
        $output=ARGV.shift
        if $output == nil or $output == ""
            raise "Missing file argument for '--out' switch!"
        end
    elsif usemodel and arg == "-m" or arg == "--model"
        $model=ARGV.shift
        if $model == nil or $model == ""
            raise "Missing argument for '--model' switch!"
        end
    elsif useprompt and arg == "-p" or arg == "--prompt"
        $prompt=ARGV.shift
        if $prompt == nil or $prompt == ""
            raise "Missing file argument for '--prompt' switch!"
        end
    elsif arg == "--filters"
        $filters=ARGV.join(" ")
        ARGV.clear
    elsif arg == "-h" or arg == "--help"
        puts        "Usage: #{File.basename(launched_from)} [OPTIONS] CHAPTERS..."
        puts        ""
        puts        "    -i --in AUDIOFILE     The audio file to use for input (required)"
        puts        "    -o --out AUDIOFILE    The audio file to write to (required)"
        if useprompt
            puts    "    -p --prompt AUDIOFILE The audio file to use as a prompt (required)"
        end
        if usemodel
            puts    "    -m --model MODEL      The model to use, which is engine-specific"
        end
        puts        "    --filters FILTERS...  "
        puts        "    -h --help             Display this help message"
        puts        ""
        exit
    # Fail with a non-zero exit code for unexpected switches
    else
        raise "Unknown option or parameter: #{arg}"
    end
end

if $input == nil
    raise "'--in' switch is required!"
end

if $output == nil
    raise "'--out' switch is required!"
end

if useprompt and $prompt == nil
    raise "'--prompt' switch is required!"
end

