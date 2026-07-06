#!/bin/bash

# The name for the script was chosen to make it as close to unique as possible
killable_process_name="96ad2bf3c18d.rb"

say_pid=$(pgrep ${killable_process_name})

text="$(xclip -quiet -out -selection primary |sed 's|^Error\: target STRING not available$||')"

if [ -z "${say_pid}" ] && [ -n "${text}" ] ; then
    echo "${text}" |"${0%/*}/${killable_process_name}"
else
    # Keep killing say-pipe.sh scripts until there are none
    while [ -n "${say_pid}" ] ; do
        # kill the script playing audio
        pkill ${killable_process_name}
        # Also kill the SoX play command
        pkill play
        
        # Sleep for a bit, then try again, until no pid is produced
        sleep 0.01
        say_pid=$(pgrep ${killable_process_name})
    done
fi
