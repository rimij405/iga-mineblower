/* MineBlower Version 5.0 - by Al Biles
 This game was developed for IGME 571/671, Interactive and Game Audio.
 The purpose is to provide a simple 2D game that requires a lot of audio
 assets that can be developed in the class.
 The types of assets are the usual suspects: Foley and ambient sounds,
 dialog and other voice work, interface sounds, and music cues.
 The version distributed to the class has placeholder sounds that
 should be sufficiently annoying to motivate their replacement
 with student-generated audio.
 
 All the placeholder sounds can be replaced by simply changing the files
 in the Audio folder, but there could be opportunities to add additional
 audio triggered by in-game events that are not linked to audio yet,
 although that has become less realistic as the version numbers have
 increased, if you know what I mean.
 
 All of the specialized Audio classes are triggered by in-game events,
 specifically the MultiSound, Crossfade, HorReSeq and VertReMix classes,
 which are classic interactive music mechanisms.
 
 Two "scenes" and a slightly branching dialog sequence provide content
 that uses the specialized classes:
 
 Yellow Submarine scene
    Triggered when player's score >= 600.
    A small Yellow Submarine animation wanders onto the window from
    the right side and moves slowly across the window in the background
    (using the tint() function), accompanied by a cue that uses looping
    horizontal resequencing.  The cues tracks transition based on the x
    location of the sub, and the background music cue is faded out while
    the Yellow Submarine is on the window.  Any eel zaps will trigger the
    zapping music cue on top of the Yellow Submarine cue.
    
 Depth Charge Scene
    Triggered when player's score >= 1200
    A 23-second cue interrupts the background music as a depth charge
    enters the window from the top and tumbles downward in the foreground.
    When the depth charge disappears, the background music returns.
    Since there is no interaction with the depth charge, this scene is
    just a false alarm and an excuse for a lengthy foreground cue that
    holds attention and ramps up the tension.
    
 Torpedo Dialog
    A non-looping horizontal resequencing object implements a slightly
    branching dialog sequence that accompanies the loading, firing,
    and tracking the torpedo.
    
 Ominous Layers
    Vertical remixing is used to provide an ominous chord that builds
    as the sub gets closer to a mine and "unwinds" as the sub gets
    further away from any mine.

 Zap Layers
    Another vertical remixing cue is triggered when the sub touches
    an eel and remains playing as long as the sub is still being zapped,
    and actually for a bit longer.  The cue starts with 5 layers of
    a 2-measure cue of annoyingly energetic music.  As the cue continues,
    layers are faded out until only the last layer is playing.  This
    layer will play until the sub escapes the eel(s).  Background music
    is ducked while this ios happening and restored when the sub escapes.
    The intent is to have a vertical remixing cue that diminishes instead
    of building.
 */
 
import ddf.minim.spi.*;   // Set up the audio library
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

Minim minim;              // Need a global object for the audio interface

// Audio assets object contains all audio assets & specialized methods 
Audio aud = new Audio();  // aud.loadAudio will be called in setup()

// Graphics assets object contains all the animations and still frames
Graphics gr = new Graphics();

Sub sub;                        // Submarine object

int nEels = 9;
Eel [] eels = new Eel [nEels];  // The eels

int nMines = 6;
Mine [] mines = new Mine [nMines]; // The mines
final int MAX_RESET = 2;        // Max number of times each mine can be reset

Torpedo t1;                     // Torpedo object
int nTorpedos = 6;              // Can use the torpedo this many times max

Bubbles b1;                     // Does the bubbles
YellowSub yS;                   // Yellow submarine
int yelSubScr = 600;            // Score that triggers the Yellow Submarine scene
DepthCharge dC;                 // Depth charge
int depChgScr = 1200;           // Score that triggers the Depth charge scene
ZapCue zapQ;                    // Encapsulates the overly complex zap music cue

Score sc;                       // Handles score and health

boolean downPressed = false;    // True when DOWN arrow is pressed
boolean leftPressed = false;    // Ditto LEFT arrow
boolean rightPressed = false;   // Ditto RIGHT arrow
                                // No upPressed - sub is naturally buoyant
boolean showInstruct = false;   // True => Display detailed instructions

int gameState = 0;              // 0 intro, 1 play, 2 sinking, 3 sunk, 4 won
int winWait = 300;              // Give animations time to finish if won

float backOff = 0.0;            // Background hue offset for Perlin noise

void setup()
{
  size(1400, 1000);             // This size works well for # of eels, etc.
  frameRate(30);                // Slow it down a bit
  imageMode(CENTER);
  colorMode(HSB);
  background(129, 60, 220);

  gr.loadGraphics();            // Load up the graphics assets
  minim = new Minim(this);      // Set up the audio interface
  aud.loadAudio();              // Load up the audio assets

  sub = new Sub();              // Create the submarine

  for (int i = 0; i < nEels; i++)  // Create all the eels
    eels[i] = new Eel();
  for (int i = 0; i < nMines; i++) // Create all the mines
    mines[i] = new Mine();
  t1 = new Torpedo(nTorpedos);  // Use the same torpedo multiple times
  b1 = new Bubbles();
  yS = new YellowSub();
  dC = new DepthCharge();
  zapQ = new ZapCue();

  sc = new Score();
  //minim.debugOn();

  aud.bkgdMus.xFade(0);         // Crossfade into background Menu music to start
}

void draw()
{
  if (gameState == 0)           // Game state 0: Show instructions
  {
    if (showInstruct)
      sc.instructions();
    else
      sc.splashScreen();
  }
  
  else if (gameState == 3)      // Game state 3: Game over, sub sunk
  {
    sc.youSankScreen();
  }
  
  else if (gameState == 4 && winWait <= 0) // State 4 & done waiting
  {
    sc.youWonScreen();          // Player actually won!
  }
  
  // Above if/elses handle states where game objects are not updated/drawn
  // The following else handles update and draw for all game objects
  // when the game is still animating.
  
  else // gameState 1 (still in game), 2 (sinking), or 4 (waiting to win)
  {
    if (gameState == 4)             // Game state 4 & Counting down to win
    {
      winWait--;
      if (winWait == 0)
      {
        aud.silenceSitu();          // Wait over - Duck all situational music
        aud.safePlay(aud.winSnd);   // Trigger win sound only once
        aud.bkgdMus.xFade(4);       // Fade in win music cue
      }
    }
    
    // Update for game states 1, 2 & 4: Do next frame /////////////////////////
    
    yS.move();                      // Move the Yellow Submarine if it's active
    b1.move();                      // Animate the bubbles
    dC.move();                      // Move the depth charge if it's active

    aud.maybePing();                // Maybe create an ambient sonar ping
    
    if (sc.score >= yelSubScr)      // Trigger Yellow Submarine scene
      yS.startYelSub();
    aud.yelSub.update();            // Update Horizontal Reseq object
   
    if (sc.score >= depChgScr)      // Trigger Depth charge scene
      dC.drop();

    for (int i = 0; i < nEels; i++) // Animate all the eels
      eels[i].move();

    for (int i = 0; i < nMines; i++) // Animate all the mines
      mines[i].move();

    t1.move();                      // Move the torpedo
    aud.torpDialog.update();        // Update torpedo dialog

    sub.move();                     // Move the sub

    // Maybe trigger a random ambient sub sound at sub's x coord
    if (random(1000.0) < 10.0)
      aud.ambSub.trigRand(sub.loc.x);
    //if (random(1000.0) < 10.0)      // Trigger sounds sequentially
    //  aud.ambSub.trigSeq(random(width));
    
    if (t1.running())               // See if the torpedo hit anything
      checkTorpedo();

    if (! sub.sunk())               // Check mines for sub touches
      checkMines();

    boolean touchedEel = false;
    for (int i = 0; i < nEels; i++) // Check eels for sub touches
    {
      if (sub.eelTouch(eels[i]))
      {
        sub.zap();                  // If touching, zap 'em both
        eels[i].zap();
        touchedEel = true;
      }
      else if (eels[i].zapping())   // Even if not touching
        touchedEel = true;          // Keep zapping until timer runs out
    }
    zapQ.zapCue(touchedEel);        // Update the zap music cue
    
    // Display for game states 1, 2 & 4 ////////////////////////////////
    
    backOff += 0.02;                // Subtle changes in background hue
    float hue = noise(backOff) * 20 + 122;  // ...using Perlin noise
    background(hue, 60, 220);

    // Display objects from back to front
    sc.display();                   // Display the score
    yS.display();                   // Display the yellow submarine
    b1.display();                   // Display the bubbles

    for (int i = 0; i < nMines; i++) // Display all the fading mines
      if (mines[i].inactive())
        mines[i].display();

    for (int i = 0; i < nEels; i++) // Display all the grounded eels
      if (eels[i].grounded())
        eels[i].display();

    t1.display();                   // Display the torpedo
    sub.display();                  // Display the sub

    for (int i = 0; i < nMines; i++) // Display all the active mines
      if (! mines[i].inactive())
        mines[i].display();

    for (int i = 0; i < nEels; i++) // Display all the active eels
      if (! eels[i].grounded())
        eels[i].display();
        
    dC.display();                   // Display the depth charge
  }
}

// See if the torpedo hit anything and act accordingly
void checkTorpedo()
{
  for (int i = 0; i < nEels; i++)   // Check all eels for torpedo touches
  {
    if (eels[i].touch(t1.nose()))
    {
      eels[i].ground();
    }
  }

  boolean hitMine = false;          // Check mines for torpedo touches
  int k = 0;                        // until one is hit or missed them all
  while (! hitMine && k < nMines)
  {
    if (mines[k].touch(t1.nose()))
    {
      mines[k].explode(1);          // 1 => Torpedo caused explosion
      t1.explode();
      sub.blast(mines[k].mineLoc());
      sc.detonatePoints();          // Score points for hitting a mine
      hitMine = true;
    }
    else
      k++;                     // Haven't hit one yet, so check next one
  }
}

// Check all the mines to see if the sub hit one
// Also manage active tracks in Vertical Remixing cue if close enough
void checkMines()
{
  boolean touchMine = false;         // Haven't hit a mine yet
  int i = 0;                         // Offset in the mines array
  float closest = width;             // Distance to closest mine so far
  int nCareLevs = aud.omLayers.snds.length; // Number of "careful" levels
  float carefulDist = 200;                  // Distance where "careful" starts
                                     // Vertical ReMixing Step per level
  float careStep = (carefulDist - mines[0].radius) / nCareLevs;
  
  // Check mines for sub touches until one is hit or missed them all
  while (! touchMine && i < nMines)
  {
    if (mines[i].touch(sub.arm.grab()))
    {
      // If arm touch is careful enough and sub not sinking...
      if (sub.careful() && sub.subState <= 1)
      {
        mines[i].disarm();            // Disarm it and score points
        touchMine = true;
      }
      else
      {
        mines[i].explode(0);          // Too hard or sinking, so blow it up
        sub.blast(mines[i].mineLoc());
        sc.blastPoints();
        touchMine = true;
      }
    }
    else if (sub.mineTouch(mines[i])) // Any sub touch blows it up
    {
      mines[i].explode(0);
      sub.blast(mines[i].mineLoc());
      sc.blastPoints();
      touchMine = true;
    }
    else if (mines[i].mineSt == 0)  // Find closest mine to grab point
    {
      float mDist = mines[i].dist2Arm(sub.arm.grab());
      if (mDist < closest)          // New closest mine
        closest = mDist;
      i++;                          // Check next mine
    }
    else
      i++;             // Sub not close to this mine, so check next one
  }
  
  // Play/update Vert Remix cue if close enough to a mine w/o touching
  if (! touchMine && closest < carefulDist)
  {
    // Get number of tracks (layers) to play
    int nVertTrks = mapCare2Levs(closest, nCareLevs, careStep);
    //println(nVertTrks);
    
    for (int l = 0; l < nCareLevs; l++)
    {
      if (l < nVertTrks)
        aud.omLayers.potUp(l);  // Close enough to play this track
      else
        aud.omLayers.potDn(l);  // Too far away - silence this track
    }
  }
  
  else
  {
    aud.omLayers.duck();    // Too far away for any tracks, so duck them all
  }
}

// Maps distance to closest mine to the number of tracks that should be played
int mapCare2Levs(float closest, int nLevs, float stepSize)
{
  // Subtract radius of mine, divide by step size, subtract from # levels
  int n2Play = nLevs - (int)((closest - stepSize) / stepSize);
  return n2Play;
}


/**** Handlers ******************************************************/

// Handle all key presses, even chords
// DOWN, LEFT & RIGHT keys are "continuous controllers" that apply
// thrust in the appropritate direction as long as the key remains
// pressed, hence the use of booleans.  The '?' key behaves the same
// way, displaying the detailed instructions on the splash screen as
// long as the key remains pressed.
// The rest of the keys trigger actions once when first pressed.
void keyPressed()
{
  if (keyCode == DOWN)
  {
    downPressed = true;
    aud.safeLoop(aud.diveSnd, sub.loc.x);
  }
  if (keyCode == LEFT)
  {
    leftPressed = true;
    aud.safeLoop(aud.reverseSnd, sub.loc.x);
  }
  if (keyCode == RIGHT)
  {
    rightPressed = true;
    aud.safeLoop(aud.forwardSnd, sub.loc.x);
  }
  if (key == 'l')
    t1.loadTorp();
  if (key == 'f')
    sub.fireTorp(t1);
  if (key == '?' && gameState == 0)
    showInstruct = true;
  if (key == 's' && gameState == 0)
  {
    gameState = 1;
    aud.bkgdMus.xFade(1);
  }
  if (key == 'q')
  {
    //minim.debugOff();
    aud.pauseAll(); // Pause or stop all the sounds
    exit();
  }
  if (key == 'd')   // Fast forward score to test depth charge & Yellow Sub
    sc.score = depChgScr;
  if (key == 'y')
    sc.score = yelSubScr;
  /*
  if (key == 'D')
    aud.bkgdMus.duck();
  if (key == 'R')
    aud.bkgdMus.restore();
  */
}

// Detect all key releases and reset booleans
void keyReleased()
{
  if (keyCode == DOWN)
  {
    downPressed = false;
    aud.diveSnd.pause();  // Pause the sound immediately
  }
  if (keyCode == LEFT)
  {
    leftPressed = false;
    aud.reverseSnd.pause();
  }
  if (keyCode == RIGHT)
  {
    rightPressed = false;
    aud.forwardSnd.pause();
  }
  if (key == '?')
    showInstruct = false;
}

void stop()            // Override default stop() method to clean up audio
{
  aud.closeAll();      // Close up all the sounds
  minim.stop();        // Close up minim itself
  super.stop();        // Now call the default stop()
}