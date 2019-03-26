Background music tracks used by the background music CrossFade object
The placeholder tunes are loopable excerpts from outsider music masterpieces.
The xFade() method crossfades between the currently playing track and
a new one.
In addition to reading the actual tunes from the mp3 files listed below,
the file BackgndGains.txt contains gain levels for the 6 tunes, one per
line in the same order as the files.

The 6 placeholder tracks and their uses:
Backgnd0.mp3 - Jail House Rock by Eilert Pilarm (Instruction screen)
Backgnd1.mp3 - The Touchy by Luie Luie (Initial background music)
Backgnd2.mp3 - Night Rider by Kenneth Higney (Background after Yellow Sub)
Backgnd3.mp3 - Thermopylae by Robert Graettinger (Background after Depth Charge)
Backgnd4.mp3 - Stout Hearted Men by Shooby Taylor (Win music)
Backgnd5.mp3 - They Told Me by Jandek (Lose music)

Note: These placeholder files are mp3s, which means they won't loop seamlessly, due to the initial 5 ms or so of silence inserted as an artifact of the fft windowing needed for the mp3 codec.  If you need your background tracks to loop seamlessly, use wav or aiff files, and change the extension parameter in the call to the constructor in the Au tab from "mp3" to "wav" or whatever non-compressed file format you are using.  Uncompressed files will loop seamlessly at the expense of being 10 times bigger.