#!/usr/bin/env ruby

# NOTE: This script was designed to use this: https://github.com/resemble-ai/resemble-enhance

require "tmpdir"

$filters="norm -8"
$prompt=nil
$model=nil

# Run the plugin script, to process command-line arguments and setup global variables to match
require "#{File.dirname(__FILE__)}/plugin-filter.rb"


Dir.mktmpdir do |temp|
    indir="#{temp}/in"
    outdir="#{temp}/out"
    logfile="#{temp}/log.txt"
    FileUtils.mkdir(indir)
    FileUtils.mkdir(outdir)
    
    system("sox \"#{$input}\" \"#{indir}/wave.wav\"")
    if $?.exitstatus != 0
        raise "Sox input failure!"
    end
    
    system("#{FILTER_COMMAND} \"#{indir}\" \"#{outdir}\" >\"#{logfile}\" 2>&1")
    if $?.exitstatus != 0
        warn File.read(logfile)
        raise "Resemble Enhance failed!"
    end
    
    system("sox \"#{outdir}/wave.wav\" \"#{$output}\" #{$filters}")
    if $?.exitstatus != 0
        raise "SoX output failure!"
    end
end

