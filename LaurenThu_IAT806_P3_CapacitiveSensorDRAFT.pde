/* Lauren Thu - IAT806 - April 15
 Project 3: Make Something COOL!
 Plant Capacitance/Music Dual 7Visualizer
 I wanted to do something less literal for this project. This is
 a plant capacitance and music visualizer. You must have an arduino loaded with
 the appropriate code on it for this to work (see arduino file). Connect your arduino to a plant
 with a paper clip or alumium foil and the lines will respond when you touch the plant (with frequency
 sound as well). Talk or play music into the microphone, and the sphere will visually respond.
 This is intended for projection in a dark room, at an installation or
 music show.
 References for code are cited in my project paper.
 
 */

import ddf.minim.*; //sound library
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import processing.serial.*; //arduino reading library


Serial myPort; //gets the serial numbers from arduino
float capacitanceValue = 0;
float avgAmplitude = 0;


Minim minim; //setting up minim audio
AudioOutput out;
AudioInput micInput; //for microphone input
Oscillator osc; //for frequency output


void setup() {
  size(2400, 1590, P3D); //enters 3D space for sphere drawing
  minim = new Minim(this); //audio library setup to pull frequency from

  // Setup audio output and oscillator
  out = minim.getLineOut();
  osc = new SineWave(600, 0.5, out.sampleRate());  // Sound for lines/capacitance
  osc.portamento(500);  // Smooth transitions between frequency changes
  out.addSignal(osc);  // Add the oscillator to the output

  // Get the audio input from the default microphone, stereo input
  micInput = minim.getLineIn(Minim.STEREO, 1500); //buffer size changes to smooth ball effect


  //  println(Serial.list()); // Print available serial ports, don't really need this but good for debugging


  myPort = new Serial(this, Serial.list()[0], 9600); //for arduino
  myPort.bufferUntil('\n'); // Read until newline character
}


void draw() {
  background(0);

  pushMatrix();
  translate(0, 0, -100); // Move the drawing of lines slightly back in Z to ensure the 3D shape draws in front

  //drawing lines
  for (int y = 0; y < height; y += 20) {
    for (int x = 0; x < width; x += 20) {
      float angle = noise(x * 0.005, y * 0.005, frameCount * 0.01) * TWO_PI; //perlin noise
      float lineLength = map(capacitanceValue*2, 0, 100, 5, 200); //line length changes in response to capacitance value
      float endX = x + cos(angle) * lineLength; //this has to do with the waviness of the lines
      float endY = y + sin(angle) * lineLength;
      stroke(noise(frameCount * 0.01) * 255, noise(frameCount * 0.01) * 100, 200); //line strokes being filtered by Perlin noise
      line(x, y, endX, endY); //draw the line
    }
  }

  popMatrix();

  updateAudioAnalysis();
  drawMorphingSphere(map(avgAmplitude, 0, 0.1, 100, 200), .1); //sphere changes size in response to sound
}

void updateAudioAnalysis() { //checking mic input
  avgAmplitude = 0;
  for (int i = 0; i < micInput.bufferSize() - 1; i++) { //not quite sure how buffersize works in sound but checking it changes amplitude
    avgAmplitude += abs(micInput.left.get(i)) + abs(micInput.right.get(i));
  }
  avgAmplitude /= (micInput.bufferSize() * 2);
}

void serialEvent(Serial myPort) { //for arduino
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    capacitanceValue = float(inString); // Convert string to float so that capacitance values are smooth
    float newFreq = map(capacitanceValue, 0, 1000, 200, 800);  // Map capacitance to frequency range
    osc.setFreq(newFreq);  // frequency sound related to lines/capacitance
  }
}


void drawMorphingSphere(float baseRadius, float noiseScale) {
  translate(width / 2, height / 2, 50);  // Center the shape in the view
  rotateY(frameCount * 0.01);  // Add some rotation for visual effect

  noFill();
  stroke(255);

  for (float lat = 0; lat <= PI; lat += PI / 18) { //had to adjust this to close the sphere shape, just trial and error
    beginShape(TRIANGLE_STRIP); //create a sphere of triangle strips to have vertices
    for (float lon = 0; lon <= TWO_PI; lon += PI / 18) {
      for (int i = 0; i <= 1; i++) {
        float currentLat = lat + i * PI / 18;
        // Modify the radius with noise and mic input
      //  float noiseValue = (noise(sin(currentLat) * 0.1, cos(lon) * 0.1, frameCount * 0.02) + noise(sin(currentLat) * 0.1, cos(lon) * 0.1, (frameCount - 1) * 0.02)) / 2; //trying to soften sphere changes,
        //but I'm not sure where to actually use this, so it's commented out
        float tempRadius = baseRadius + noiseScale * noise(sin(currentLat) * 2.5, cos(lon) * 2.5, frameCount * 0.5) * avgAmplitude * 20000; //this is the Perlin noise for the surface of the sphere
        float x = sin(currentLat) * cos(lon) * tempRadius; //temporary radius because it changes 
        float y = sin(currentLat) * sin(lon) * tempRadius;
        float z = cos(currentLat) * tempRadius;
        vertex(x, y, z);
      }
    }
    endShape(CLOSE);
  }
}



void stop() {
  // Ensure audio resources are closed properly
  out.close();
  minim.stop();
  super.stop();
}
