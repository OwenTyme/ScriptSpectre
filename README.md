# Script Spectre

Script Spectre is a set of [Ruby](https://www.ruby-lang.org) programs (and some very reluctant Python wrapper scripts) to somewhat automate the process of turning an audio script, in ODT format, into an audiobook, using text to speech (TTS) software.

The basis of the name comes from thinking of TTS engines as disembodied voices, making the software like a ghost that reads a script.


## Notes on Audio Scripts

Currently, audio scripts should be in ODT format, a limitation I intend to remove in the future, using a tagging system that uses square brackets, curly brackets and angle brackets for three distinct purposes:

First, square brackets are for enclosing the name of a voice or sound effect, like this `[narrator]` or `[sound_effect]`.  Please note: only alphanumeric and underscore characters can be used between square brackets within an audio script.  However, other characters, like dashes, can be added to voice or sound effect names that aren't intended for direct use in an audio script.  for example, [common.rb](common.rb) uses them in the names of base voices for TTS engines, because they're generally not useful on their own and require the addition of more data in order to be functional.

Curly brackets serve a very specific purpose: pronunciation replacement.  When a word is followed by another word in curly brackets, the version in curly brackets is fed to the TTS engine in place of the preceding word.  For example, the word 'read' has multiple pronunciations for the same spelling.  `read{red}` is used to force 'read' to be pronounced the same as 'red'.  This allows the author of an audio script to retain the true spelling, for the sake of reading and editing, while the correct pronunciation is used at runtime.

Finally, angle brackets have special meaning to the turbo model of [Chatterbox](https://github.com/resemble-ai/chatterbox), which get replaced during pronunciation processing with square bracket, if certain words are between them.  The words are then treated as instructions for para-liguistic effects.  The supported list is as follows: `<clear throat> <sigh> <shush> <cough> <groan> <sniff> <gasp> <chuckle> <laugh>`.  Interestingly enough, when multiple tags of the same type are in a row, they sometimes combine for greater intensity.  Laughter can be extended by stringing them together, for example.  That also works with coughing, but in general, these tags are best used sparingly.  If there's too many in a sentence, Chatterbox tends to malfunction.

For some example uses of all of the above, see [the example audio script](example/audiobook.odt), along with the [build file](example/build.rb) that produces audio from it.

There's also an alternate example use in the [util directory](util), which includes a script for reading aloud and another for reading selected text from a user's screen, with a second activation causing it to kill the reading script.


## Dependencies

The following software must be installed and available on the command-line, in order to function at all:

* [Pandoc](https://pandoc.org/) - Used to convert ODT files to markdown, then into plain text and version 3.6.4 is known to work.
* [Ruby](https://www.ruby-lang.org) - Primary scripting language for this project and version 3.0.2 was used.
* [Sed](https://www.gnu.org/software/sed/) - Used for some text processing between calls to Pandoc, but future versions may remove this dependency
* [SoX - Sound eXchange](https://sourceforge.net/projects/sox/) - Used for audio transcoding/filtering and version 14.4.2 is known to work.


### TTS Engines (Required)

In order for this software to do any real work, at least one TTS engine must also be installed and correctly pointed at via `config-user.rb`:

* [Chatterbox](https://github.com/resemble-ai/chatterbox)
* [Kitten](https://github.com/KittenML/KittenTTS)
* [Parler](https://github.com/huggingface/parler-tts)
* [Piper](https://github.com/rhasspy/piper)
* [Pocket TTS](https://github.com/kyutai-labs/pocket-tts)
* [qwentts.cpp](https://github.com/ServeurpersoCom/qwentts.cpp)
* [VoxCPM](https://github.com/OpenBMB/VoxCPM)

It is possible to connect other TTS engines (or alternative versions of them), but these are the engines I've been able to get working reliably and which are of value to me.

How they're installed is up to you, but for the python software, I've found Conda to be the most reliable approach to creating isolated installs of AI software, but your mileage may vary.


### Voice Conversion/Resynthesizers/Filters

This software can optionally run a step for voice conversion (VC), which is also referred to as the filtering step, because more often than not the same mechanism is used for filtering noise, by plugging in other software.

To do any voice conversion work, at least one of these will have to be installed:

* [Chatterbox](https://github.com/resemble-ai/chatterbox) - Most don't seem to realize it, but Chatterbox includes a voice changer
* [Kanade Tokenizer](https://github.com/frothywater/kanade-tokenizer) - This includes a rather useful voice resynthesizer that can remove all sorts of noise from a sample, including reverb.  However, Kanade Tokenizer really tends to mess up whispered samples, making them into a raspy mess.  Note: Kanade Tokenizer writes audio files at 44.1 Khz.
* [MioCodec](https://github.com/Aratako/MioCodec) - This fork of Kanade Tokenizer handles whispers better, but I've found when it's used as a resyntesizer, it doesn't do quite as good a job.  Note: MioCodec writes audio files at 44.1 Khz.

Again, as with the TTS engines, how these are installed and connected is up to you.


### Speech Enhancement

The final stage in producing an audiobook with this software involves speech enhancement, to either improve audio quality or simply upscale it to a higher sample rate.

The following options for speech enhancement can be installed and used, which can also be used during the VC/filter stage:

* [LavaSR](https://github.com/ysharma3501/LavaSR) - 48 Khz upscaler that can optionally also do a little noise removal.  This is the upscaler I prefer.
* [Resemble Enhance](https://github.com/resemble-ai/resemble-enhance) - 44.1 Khz up-scaler and noise remover.  This works rather well for audio enhancement, but every once in a while (about 1% of the time), it distorts a word, instead of making it clearer.  However, I've found that when the denoiser is used without the enhancement engine, it does an excellent job, without distorting words.  My recommendation: use this for noise removal only, then upscale with LavaSR.

Again, how these are installed and connected is up to you.
