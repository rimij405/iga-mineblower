/* DisarmTone class - by Ian Effendi
 Uses Minim UGens to implement a synthesis chain that generates
 a disarm mine sound tone.  Implements Instrument interface
 by providing noteOn() and noteOff methods, even though the NoteOff is
 never called because when the envelope runs out, it unpatches from out.
 
 triggerDisarmTone() in Audio creates a DisarmTone object and calls noteOn()
 to start pinging.  Main tab calls aud.triggerDisarmTone()
 Note: AudioOutput object set up in Audio class
 */
class DisarmTone
{
  Oscil waveformA; // Osc for first sound.
  Damp dampA;
  Delay delayA;
  
  Oscil waveformB; // Osc for second sound.
  Damp dampB;
  Delay delayB;  
    
  DisarmTone()         // Constructor creates an object for the pings
  {
    createToneA();
    createToneB();
  }

  void createToneA() {
    waveformA = new Oscil( 1000, 0.4, Waves.SINE );  // 1000 Hz, kinda loud
    dampA = new Damp( 0.01, 0.08, 0.9 );         // Attack, decay time, amp
    delayA = new Delay( 0.75, 0.5, true, true ); // Delay with feedback
    waveformA.patch(dampA).patch(delayA); // Chain together
  }
  
  void createToneB() {
    waveformB = new Oscil( 400, 0.5, Waves.SQUARE );  // 1000 Hz, kinda loud
    dampB = new Damp( 0.08, 0.13, 0.9 );         // Attack, decay time, amp
    delayB = new Delay( 1.75, 0.5, true, true ); // Delay with feedback
    waveformB.patch(dampB).patch(delayB); // Chain together
  }
  
  void noteOn()      // Called from main to start pinging
  {
    dampA.activate();
    delayA.patch(aud.out);
    dampA.unpatchAfterDamp(aud.out);
    
    dampB.activate();
    delayB.patch(aud.out);
    dampB.unpatchAfterDamp(aud.out);    
  }

  void noteOff()     // Not needed with the Delay envelope
  {
    dampA.unpatchAfterDamp(aud.out);
    dampB.unpatchAfterDamp(aud.out);
  }
}
