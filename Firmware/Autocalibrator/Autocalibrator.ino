/* TSL2591 Digital Light Sensor */
/* Dynamic Range: 600M:1 */
/* Maximum Lux: 88K */

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include "Adafruit_TSL2591.h"
#define LOW_GAIN 7
#define MEDIUM_GAIN 8
#define HIGH_GAIN 9
#define MAX_GAIN 10

// connect SCL to analog 5
// connect SDA to analog 4
// connect Vin to 3.3-5V DC
// connect GROUND to common ground

Adafruit_TSL2591 tsl = Adafruit_TSL2591(2591); // pass in a number for the sensor identifier (for your use later)


/**************************************************************************/
/*
    Configures the gain and integration time for the TSL2591
*/
/**************************************************************************/
void configureSensor(void)
{
  setGain(MAX_GAIN);
  setIntegrationTime(1);  //100ms
}

/**************************************************************************/
/*
    Program entry point for the Arduino sketch
*/
/**************************************************************************/
void setup(void)
{
  Serial.begin(115200);
  pinMode(2, INPUT_PULLUP);
  pinMode(3, INPUT_PULLUP);
  pinMode(4, INPUT_PULLUP);
  pinMode(5, INPUT_PULLUP);
  if (!tsl.begin())
  {
    Serial.println("No sensor found ... check your wiring?");
     while (1);
  }

  configureSensor();
}


unsigned int readId()
{
  unsigned int a = 0;
  a |= !digitalRead(2);
  a |= (!digitalRead(3)) << 1;
  a |= (!digitalRead(4)) << 2;
  a |= (!digitalRead(5)) << 3;
  return a;
}

/**************************************************************************/
/*
    Shows how to perform a basic read on visible, full spectrum or
    infrared light (returns raw 16-bit ADC values)
*/
/**************************************************************************/
void simpleRead(void)
{
  // Simple data read example. Just read the infrared, fullspecrtrum diode
  // or 'visible' (difference between the two) channels.
  // This can take 100-600 milliseconds! Uncomment whichever of the following you want to read
  //uint16_t x = tsl.getLuminosity(TSL2591_VISIBLE);
  uint16_t x = tsl.getLuminosity(TSL2591_FULLSPECTRUM);
  //uint16_t x = tsl.getLuminosity(TSL2591_INFRARED);

  //Serial.print("[ "); Serial.print(millis()); Serial.print(" ms ] ");
  //Serial.print("Luminosity: ");
  Serial.println(x, DEC);
}


/**************************************************************************/
/*
    Arduino loop function, called once 'setup' is complete (your own code
    should go here)
*/
/************************************************
**************************/
void loop()
{
  if (Serial.available() > 0)
    respondToQuery(Serial.read());
}

void respondToQuery(char a)
{
  if (a == 'i')
    Serial.println(readId());
  if (a == ' ')
    simpleRead();
  if ((a >= 1) && (a <= 6))
    setIntegrationTime(a);
  if ((a >= LOW_GAIN) && (a <= HIGH_GAIN))
    setGain(a);

}

void setIntegrationTime(int integrationTime)
{

  // Changing the integration time gives you a longer time over which to sense light
  // longer timelines are slower, but are good in very low light situtations!
  if (integrationTime == 1)
    tsl.setTiming(TSL2591_INTEGRATIONTIME_100MS);  // shortest integration time (bright light)
  if (integrationTime == 2)
    tsl.setTiming(TSL2591_INTEGRATIONTIME_200MS);
  if (integrationTime == 3)
    tsl.setTiming(TSL2591_INTEGRATIONTIME_300MS);
  if (integrationTime == 4)
    tsl.setTiming(TSL2591_INTEGRATIONTIME_400MS);
  if (integrationTime == 5)
    tsl.setTiming(TSL2591_INTEGRATIONTIME_500MS);
  if (integrationTime == 6)
    tsl.setTiming(TSL2591_INTEGRATIONTIME_600MS);  // longest integration time (dim light)
  Serial.println(integrationTime);
}

void setGain(int gain)
{
  // You can change the gain on the fly, to adapt to brighter/dimmer light situations
  switch (gain) {
    case (LOW_GAIN):
      tsl.setGain(TSL2591_GAIN_LOW);    // 1x gain (bright light)
      break;
    case (MEDIUM_GAIN):
      tsl.setGain(TSL2591_GAIN_MED);      // 25x gain
      break;
    case (HIGH_GAIN):
      tsl.setGain(TSL2591_GAIN_HIGH);   // 428x gain
      break;
    case (MAX_GAIN):
      tsl.setGain(TSL2591_GAIN_MAX);   // 9876x gain
      break;
  }
  Serial.println(gain);
}


