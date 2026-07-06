



#  ________________________________
# /                                \
# |  Review Methods and Constants  |
# \________________________________/
# These are immutable return values
REVIEW_EXIT=:exit
REVIEW_YES=:yes
REVIEW_REDO=:redo

# FIX ME?: Make the dialog box command selectable?
# With a little care, that night allow using an actual GUI variant
def review_audio(audio_file, backtitle: "", question: "Are you happy with the sound?", height: 7, width: 60)
    while true
        system("mpv --no-audio-display \"#{audio_file}\"")
        if $?.exitstatus != 0
            raise "MPV failed to play audio file '#{audio_file}'!"
        end
        
        if backtitle != ""
            switches = "--backtitle \"#{backtitle}\""
        end
        
        # This reworks the yes no dialog with an extra button and relabels everything to "Replay", "Yes" and "Redo"
        system("dialog --keep-tite --keep-window #{switches} --yes-label \"Replay\" --extra-button --extra-label \"Yes\" --nolabel \"Redo\" --default-button \"extra\" --yesno \"#{question}\" #{height} #{width}")
        
        # Potential responses from dialog, based on the above command
        # 0 = Replay
        # 3 = Yes
        # 1 = Redo
        # 255 = Exit (ESC key was hit)
        response = $?.exitstatus
        if response == 3
            return REVIEW_YES
        elsif response == 1
            return REVIEW_REDO
        elsif response == 255
            return REVIEW_EXIT
        elsif response != 0
            raise "Unexpected return code from dialog: '#{response}'"
        end
    end
end
