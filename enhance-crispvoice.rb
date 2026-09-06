#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/Francium-Tech/CrispVoice

require "tmpdir"

$filters="norm -8"
$prompt=nil
$model="natural"

# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-filter.rb"


Dir.mktmpdir do |temp|
    audiofile="#{temp}/audiofile.wav"
    logfile="#{temp}/log.txt"
    
    if $model == nil
        system("#{FILTER_COMMAND} \"#{File.absolute_path($input)}\" \"#{File.absolute_path(audiofile)}\" >\"#{logfile}\" 2>&1")
    else
        system("#{FILTER_COMMAND} --preset \"#{$model}\" \"#{File.absolute_path($input)}\" \"#{File.absolute_path(audiofile)}\" >\"#{logfile}\" 2>&1")
    end
    if $?.exitstatus != 0
        warn File.read(logfile)
        raise "CrispVoice failed!"
    end
    
    system("sox \"#{audiofile}\" \"#{$output}\" #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end

