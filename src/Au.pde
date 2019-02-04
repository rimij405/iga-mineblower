/* Audio class - by Al Biles
 Declares and loads all audio assets.
 A global Audio object should be created in setup().
 Also provides methods that make life easier for playing or triggering
 sounds from the other classes.
 
 Methods:
 safePlay() - Plays a sound once only if the sound isn't already playing.
 safePlay() has an overload that plays the sound at a given pan loc.
 safeLoop() - Loops a sound only if the sound isn't already playing.
 safeLoop() has an overload that loops the sound at a given pan loc.
 
 tooFarLeft(), Right, Up & Down - Each call safePlay() with the appropriate
 sound when the sub goes too far off the screen in that direction.

 panPlay() - specialized method for playing the torpedo running sound
 by panning it with the torpedo from the sub's location on launch
 to the right edge of the window. From there a call to fadeOut() will
 fade the sound out, as if it is moving away in the distance.
 
 SilenceSitu() - Turns off any active situational music cues.
 PauseAll() & CloseAll() - Turn off & Close all sound-producing objects
 
 This class uses the MultiSound, CrossFade, HorReSeq, VerReMix,
 PingTone & RingFile classes, which are defined in separate tabs.
 These classes depend on patches to the audio hardware that are set up
 here, but are otherwise independent.  However, the actual objects
 instantiated from these classes are set up here in the Audio class.
 The philosphy is to hide as many of the details as possible here and
 require the non-audio classes and the main tab to know only what's
 needed to interact with the audio objects during game play.
 
 To set up an object from the MultiSound, CrossFade, HorReSeq, VertReMix
 or RingFile classes:
 1) Declare an object as a (global) attribute below
 2) Create the object in the Audio() constructor below and...
 3) ...Call any additional setup methods for objects of that class
 4) Add a pauseAll() method call to the pauseAll() method below
 5) Add a closeAll() method call to the closeAll() method below
 6) Insert calls to transition or other methods as needed in other tabs
 7) If it is a music cue or persistant sound, add a call to silence
    or duck all sounds to the silenceSitu() method below
 */
 
class Audio
{
  // AudioPlayers for simple Foley sounds & musical cues (single files)
  AudioPlayer bangSnd;       // Foley for explosion
  AudioPlayer disarmSnd;     // Foley for disarming a mine
  AudioPlayer zapSnd;        // Foley for eel zap
  AudioPlayer groundSnd;     // Foley for torpedo grounding an eel  
  AudioPlayer forwardSnd;    // Looping Foley while right arrow pressed
  AudioPlayer reverseSnd;    // Looping Foley while left arrow pressed
  AudioPlayer diveSnd;       // Looping Foley while down arrow pressed
  AudioPlayer tooLeftSnd;    // Sounds for sub going too far off screen,
  AudioPlayer tooRightSnd;   //   with placeholders as simple voice lines,
  AudioPlayer tooUpSnd;      //   so these could be opportunities for dialogs
  AudioPlayer tooDownSnd;
  AudioPlayer sinkingSnd;    // Foley for sub sinking
  AudioPlayer sunkSnd;       // Foley for sub sunk
  AudioPlayer winSnd;        // Sound for winning game, could be a stinger
  AudioPlayer bubbleSnd;     // Foley for bubbles (localized ambient)
  AudioPlayer torpLoadSnd;   // Foley for loading the torpedo
  AudioPlayer fireSnd;       // Foley for firing torpedo
  AudioPlayer torpRunSnd;    // Foley for torpedo as it is running
  AudioPlayer explodeStinger; // Music Stinger that follows mine exploded by sub
  AudioPlayer disarmStinger; // Music Stinger that follows disarming a mine
  AudioPlayer depChgCue;     // Cue played while depth charge falls

  AudioOutput out;    // Used for PingTone, RingFile and any other UGen chain

  int pingCount = 0;  // Counter in maybePing() to keep random pings at bay
  
  // More complex sound objects that use multiple sounds
  CrossFade bkgdMus;  // CrossFade object used for background music cues

  MultiSound ambSub;  // MultiSound object: Ambient sub sounds that just happen

  HorReSeq yelSub;    // Looping horizontal resequencing object used for music
                      // played in Yellow Submarine scene
                      
  HorReSeq torpDialog; // Non-looping horizontal resequencing object
                       // used for Torpedo dialog in loading, launching, etc.
  
  VertReMix omLayers; // Vertical remixing object for "ominous chord layers"
                      // triggered as sub gets closer and closer to a mine.

  VertReMix zapLayers; // Vertical remixing object for music layers to accompany
                       // the sub being zapped by one or more eels.

  RingFile rF1;       // Ring modulator object used for occasional exclamation

  void loadAudio()    // Called in setup()
  {
    bangSnd = minim.loadFile("Audio/Bang.mp3", 512);
    disarmSnd = minim.loadFile("Audio/Disarm.mp3", 512);
    disarmSnd.setGain(-8.0);                      // Turn it down
    zapSnd = minim.loadFile("Audio/Zap.mp3", 512);
    zapSnd.setGain(-6.0);
    groundSnd = minim.loadFile("Audio/Grounded.mp3", 512);
    forwardSnd = minim.loadFile("Audio/Forward.wav", 512);
    forwardSnd.setGain(-15.0);
    reverseSnd = minim.loadFile("Audio/Reverse.wav", 512);
    reverseSnd.setGain(-15.0);
    diveSnd = minim.loadFile("Audio/Dive.wav", 512);
    diveSnd.setGain(-12.0);
    tooLeftSnd = minim.loadFile("Audio/TooLeft.mp3", 512);
    tooRightSnd = minim.loadFile("Audio/TooRight.mp3", 512);
    tooUpSnd = minim.loadFile("Audio/TooUp.mp3", 512);
    tooDownSnd = minim.loadFile("Audio/TooDown.mp3", 512);
    sinkingSnd = minim.loadFile("Audio/Sinking.mp3", 512);
    sinkingSnd.setGain(-12.0);
    sunkSnd = minim.loadFile("Audio/Sunk.mp3", 512);
    winSnd = minim.loadFile("Audio/Win.mp3", 512);
    bubbleSnd = minim.loadFile("Audio/Bubbles.mp3", 512);
    bubbleSnd.setGain(-12.0);
    torpLoadSnd = minim.loadFile("Audio/TorpLoad.mp3", 512);
    torpLoadSnd.setGain(-6.0);
    fireSnd = minim.loadFile("Audio/TorpFire.mp3", 512);
    fireSnd.setGain(18.0);                            // Turn it up
    torpRunSnd = minim.loadFile("Audio/TorpRun.mp3", 512);
    torpRunSnd.setGain(-3.0);
    disarmStinger = minim.loadFile("Audio/DisarmSting.mp3");
    disarmStinger.setGain(-10.0);
    explodeStinger = minim.loadFile("Audio/ExplodeSting.mp3", 512);
    explodeStinger.setGain(-12.0);
    depChgCue = minim.loadFile("Audio/DepthChgCue.mp3", 512);
    depChgCue.setGain(-10.0);

    out = minim.getLineOut();          // Used for PingTone unit generators
    
    bkgdMus = new CrossFade("Audio/JukeBox/Backgnd", "mp3", 6);
    // Note: Change "mp3" to "wav" if using wav files, which loop seamlessly

    ambSub = new MultiSound("Audio/AmbientSub/Snd", "mp3", 4);
    
    // Looping Horizontal Resequencing cue accompanies Yellow Sub scene
    yelSub = new HorReSeq("Audio/YellowSub/YelSub", "wav", 5, true);
    
    // Non-looping Horizontal Resequencing object handles torpedo dialog
    torpDialog = new HorReSeq("Audio/TorpDialog/TorpLine", "mp3", 8, false);
    
    // Vertical Remixing cue builds an ominous chord - These always loop
    omLayers = new VertReMix("Audio/OmLayers/OmLayer", "wav", 4);
    omLayers.startAll();
    
    // Vertical Remixing Cue starts when sub first touches an eel
    zapLayers = new VertReMix("Audio/ZapLayers/ZapLoop", "wav", 5);
    //zapLayers.startAll();            // Started when zap occurs
    
    // Set up the ring modulator with the file as carrier, modulating
    // frequency of 500 Hz, modulating amplitude (depth) of 2.0.
    rF1 = new RingFile("Audio/RingFeed.mp3", 500, 2.0);
  }

  void pauseAll()  // Called when user types 'q' to quit
  {    
    bangSnd.pause();
    disarmSnd.pause();
    zapSnd.pause();
    groundSnd.pause();
    forwardSnd.pause();
    reverseSnd.pause();
    diveSnd.pause();
    fireSnd.pause();
    tooLeftSnd.pause();
    tooRightSnd.pause();
    tooUpSnd.pause();
    tooDownSnd.pause();
    sinkingSnd.pause();
    sunkSnd.pause();
    winSnd.pause();
    bubbleSnd.pause();
    torpLoadSnd.pause();
    torpRunSnd.pause();
    explodeStinger.pause();
    depChgCue.pause();
    disarmStinger.pause();
    ambSub.pauseAll();
    yelSub.pauseAll();
    torpDialog.pauseAll();
    omLayers.pauseAll();
    zapLayers.pauseAll();
    out.mute();
  }

  void closeAll()  // Called from stop() in main
  {
    bangSnd.close();
    disarmSnd.close();
    zapSnd.close();
    groundSnd.close();
    forwardSnd.close();
    reverseSnd.close();
    diveSnd.close();
    fireSnd.close();
    tooLeftSnd.close();
    tooRightSnd.close();
    tooUpSnd.close();
    tooDownSnd.close();
    sinkingSnd.close();
    sunkSnd.close();
    winSnd.close();
    bubbleSnd.close();
    torpLoadSnd.close();
    torpRunSnd.close();
    explodeStinger.close();
    depChgCue.close();
    disarmStinger.close();
    ambSub.closeAll();
    yelSub.closeAll();
    torpDialog.closeAll();
    omLayers.closeAll();
    zapLayers.closeAll();
  }

/******* Simple sound activation methods ***********************/

  // Play sound once only if it's not already playing
  void safePlay (AudioPlayer snd)
  {
    if (! snd.isPlaying())
    {
      snd.rewind();
      snd.play();
    }
  }

  // Overload to play sound once at loc x mapped to L/R pan
  void safePlay (AudioPlayer snd, float x)
  {
    if (! snd.isPlaying())
    {
      snd.rewind();
      snd.setPan(map(x, 0, width, -1.0, 1.0));
      snd.play();
    }
  }

  // Loop sound only if it's not already playing
  void safeLoop (AudioPlayer snd)
  {
    if (! snd.isPlaying())
    {
      snd.rewind();
      snd.loop();
    }
  }

  // Overload to loop sound at loc x mapped to L/R pan
  void safeLoop (AudioPlayer snd, float x)
  {
    if (! snd.isPlaying())
    {
      snd.rewind();
      snd.setPan(map(x, 0, width, -1.0, 1.0));
      snd.loop();
    }
  }
  
  // Triggered when sub moves too far out of the window
  void tooFarLeft()  // Plays when sub too far left out of the window
  {
    safePlay(tooLeftSnd, 0.0);      // Pan hard left
  }

  void tooFarRight()
  {
    safePlay(tooRightSnd, width);   // Pan hard right
  }

  void tooFarUp(float subX)
  {
    safePlay(tooUpSnd, constrain(subX, 0, width)); // Pan to sub's x coord
  }

  void tooFarDown(float subX)
  {
    safePlay(tooDownSnd, constrain(subX, 0, width)); // Pan to x coord
  }
  
  /****** maybePing() ***************************************************/
  
  // Maybe generate an ambient ping - Creates new PingTone object each time
  // it decides to start a ping echo chain so that more than one can play
  // at the same time. Uses class attribute pingCount. Called from Main tab.
  void maybePing()
  {
    if (pingCount > 0)                // Too soon since previous ping
      pingCount--;
    else if (random (0, 100) < 1.0)   // 1% chance each frame
    {
      pingCount = 50;                 // Wait at least 50 frames
      PingTone pt = new PingTone();   // Create a PingTone Instrument
      pt.noteOn();                    // Send it a noteOn signal
    }
  }
  
  /****** Torpedo running sound methods *******************************/
  
  // Fairly elaborate code to localize the torpedo running sound
  // after the torpedo is a fired.  panPlay() is called when torpedo
  // is fired.  fadeOut() is called when torpedo exits the window.
  //
  // Plays snd beginning at pan location x, panning in real time
  // toward right window edge, given initial torpedo speed launchV
  void panPlay(AudioPlayer snd, float x, float launchV)
  {
    if (! snd.isPlaying())
    {
      float panStart = map(x, 0, width, -1.0, 1.0);  // Where to start pan
      int panTime = figurePanTime(x, launchV);  // How long pan will take
      snd.rewind();
      snd.setGain(0.0);
      snd.shiftPan(panStart, 1.0, panTime);     // Start panning the sound
      snd.play();                               // Start playing the sound
    }
  }

  // Figures how many milliseconds it will take for torpedo to move from
  // x location to right window edge, given initial speed initV
  int figurePanTime(float x, float initV)
  {
    float where = x;       // Starting at x, move where
    float velX = initV;    // Initial velocity
    int nPanFrames = 0;    // Count number of frames
    while (where < width)
    {
      where += velX;       // move to next x location
      velX += t1.a.x;      // Apply drag effect
      nPanFrames++;        // Count the frame
    }
    return int (nPanFrames * 1000 / frameRate);  // Convert to milliseconds
  }

  // Fade out snd over the rest of its playing time
  void fadeOut(AudioPlayer snd)
  {
    if (snd.isPlaying())
    {
      int fadeTime = snd.length() - snd.position();    // How much left
      snd.shiftGain(snd.getGain(), -15.0, fadeTime);   // Fade that long
    }
  }
  
  /****** Called at end game to silence situational music cues ******/
  
  void silenceSitu()
  {
    if (yS.running == 1)
      yelSub.trigTrans(5);  // Finish yellow sub cue if it's playing 
    if (depChgCue.isPlaying())
      depChgCue.pause();    // Interrupt depth chargecue if it's playing
    zapLayers.duck();       // Interrupt zap cue if it's playing
  }
}