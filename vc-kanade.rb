#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/frothywater/kanade-tokenizer

require "tmpdir"

# The default model choice
$model="frothywater/kanade-25hz-clean"
$filters="norm -8"

# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-filter.rb"


Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    
    system("#{FILTER_COMMAND} --in \"#{$input}\" --out \"#{audiofile}\" --prompt \"#{$prompt}\" --model \"#{$model}\" >\"#{logfile}\" 2>&1")
    if $?.exitstatus != 0
        warn File.read(logfile)
        raise "Kanade Tokenizer failed!"
    end
    
    system("sox \"#{audiofile}\" \"#{$output}\" #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end

