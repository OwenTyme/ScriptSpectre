#!/usr/bin/ruby
# DO NOT change the shebang to use env, because that prevents ruby from changing it's process title!

# The entire point of this script is to launch say.rb with a unique process title that can be safely killed, by name
Process.setproctitle(File.basename(__FILE__))
require "#{File.dirname(__FILE__)}/say.rb"

