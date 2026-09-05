#!/usr/bin/env ruby

# This simple script produces random harvard lines and sends them to std-out
# All command-line parameters are assumed to be integers, indicating the number of lines
# If none are specified, it displays three lines

# We'll need some settings from the config file
require "#{File.dirname(__FILE__)}/config.rb"

# And this is what we actually need
require "#{RUBY_DIR}/harvard.rb"

if ARGV.length == 0
    ARGV.push("3")
end

while ARGV.length > 0
    count=Integer(ARGV.shift)
    
    puts harvard_lines(count)
end

