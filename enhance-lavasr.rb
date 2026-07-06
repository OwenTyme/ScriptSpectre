#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/ysharma3501/LavaSR

require "tmpdir"

$filters="norm -8"
$prompt=nil
$model=nil

# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-filter.rb"


Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    
    system("#{FILTER_COMMAND} \"#{File.absolute_path($input)}\" --out \"#{File.absolute_path(audiofile)}\" >\"#{logfile}\" 2>&1")
    if $?.exitstatus != 0
        warn File.read(logfile)
        raise "LavaSR failed!"
    end
    
    system("sox \"#{audiofile}\" \"#{$output}\" #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end

