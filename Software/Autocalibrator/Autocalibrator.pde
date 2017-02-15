import processing.serial.*;
int num=1;
boolean settingUpSensors;
PVector pos;
int numPorts;
boolean firstRun=true;
StringList serialPorts;
Serial port;
int[][] horizontalScan;
int[][] diagonalScan;

int[][] horizontalLowPass;
int[][] diagonalLowPass;
int[][] horizontalDerivative;
int[][] diagonalDerivative;
int locality=1;
FloatList[] horizontalLocalityPeaks, diagonalLocalityPeaks;
int horizontalScanLength=1080; 
int diagonalScanLength=3050; //(1920+1080)
boolean displayData=false;
boolean scanning=false;
int position=0;
float b=0;
int[] min;
int[] max;
int run;
PVector location;
int state=0;
int index=0;
Serial[] ports;
int selectedIndex=0;
int integrationTime=100;
int skip=10;
int numSlices=10;
boolean selectedData=false;
boolean showDezPeaks=false;
boolean showDerivativePeaks=false;
boolean showLocality=true;
FloatList[] horizontalPeaks;
FloatList[] diagonalPeaks;

int[][] dezHorizontalPeaks;
int[][] dezDiagonalPeaks;
int lastFrame;
int minPeakInc=5;
int minFreqInc=5;
int minPeakFreq=50;
int minPeakAmplitude= 15;
float allowedDeviation=.8;
PVector[] bestHorizontalSettings;
PVector[] bestDiagonalSettings;
boolean fancyPeaks=true;

boolean derivativePeaks=false;
int scale=25;

void setup()
{
  size(displayWidth, displayHeight);
  String[] lines=loadStrings(dataPath("run.txt"));
  run=int(lines[0])+1;
  println(run);
  loadData("run 40.csv");
  setupSensors();
}

void loadData(String filename)
{
  numPorts=9;
  String[] strings=loadStrings(dataPath(filename));
  String[] parts;
  min=new int[numPorts];
  max=new int[numPorts];
  diagonalScan=new int[diagonalScanLength][numPorts];
  horizontalScan=new int[horizontalScanLength][numPorts];
  diagonalLowPass=new int[diagonalScanLength][numPorts];
  horizontalLowPass=new int[horizontalScanLength][numPorts];
  diagonalDerivative=new int[diagonalScanLength][numPorts];

  dezHorizontalPeaks=new int[numSlices][numPorts];
  dezDiagonalPeaks=new int[numSlices][numPorts];

  horizontalDerivative=new int[horizontalScanLength][numPorts];
  horizontalPeaks=new FloatList[numPorts];
  diagonalPeaks=new FloatList[numPorts];
  for (int j=0; j<numPorts; j++)
  {
    parts=strings[j*2].split(",");
    for (int i=0; i<diagonalScanLength; i++)
      diagonalScan[i][j]=int(parts[i]);
    parts=strings[j*2+1].split(",");
    for (int i=0; i<horizontalScanLength; i++)
      horizontalScan[i][j]=int(parts[i]);
  }
  if (fancyPeaks)
    fancyPeaks();
  else
    simplePeaks();
  //    findPeaks();

  /*
  for (int i=0; i<horizontalPeaks[0].size (); i++)
   print(horizontalPeaks[0].get(i)+" ");
   println();
   */
  state=4;  //tap out
  displayData=true;
}

void simplePeaks()
{
  horizontalLocalityPeaks=new FloatList[numPorts];
  diagonalLocalityPeaks=new FloatList[numPorts];
  int[] data;
  IntList peaks;
  for (int j=0; j<numPorts; j++)
  {
    data=new int[horizontalScanLength];
    for (int i=0; i<data.length; i++)
      data[i]=horizontalScan[i][j];
    peaks=bruteForce(data, locality);
    horizontalLocalityPeaks[j]=new FloatList();
    for (int k=0; k<peaks.size (); k++)
      horizontalLocalityPeaks[j].append(peaks.get(k));
    data=new int[diagonalScanLength];
    for (int i=0; i<data.length; i++)
      data[i]=diagonalScan[i][j];
    peaks=bruteForce(data, locality);
    diagonalLocalityPeaks[j]=new FloatList();
    for (int k=0; k<peaks.size (); k++)
      diagonalLocalityPeaks[j].append(peaks.get(k));
  }
}

void fancyPeaks()
{
  int[] data;
  float[] peaks;
  int[] numHorizontalPeaks=new int[numPorts];
  int[] numDiagonalPeaks=new int[numPorts];
  bestHorizontalSettings=new PVector[numPorts];
  bestDiagonalSettings=new PVector[numPorts];
  diagonalLowPass=new int[diagonalScanLength][numPorts];
  horizontalLowPass=new int[horizontalScanLength][numPorts];
  diagonalDerivative=new int[diagonalScanLength][numPorts];

  //  dezHorizontalPeaks=new int[numSlices][numPorts];
  //  dezDiagonalPeaks=new int[numSlices][numPorts];
  dezHorizontalPeaks=new FloatList[numPorts];
  dezDiagonalPeaks=new FloatList[numPorts];

  dezPostProcessedHorizontalPeaks=new FloatList[numPorts];
  dezPostProcessedDiagonalPeaks=new FloatList[numPorts];



  horizontalDerivative=new int[horizontalScanLength][numPorts];
  horizontalPeaks=new FloatList[numPorts];
  diagonalPeaks=new FloatList[numPorts];



  for (int i=0; i<numPorts; i++)
  {
    bestHorizontalSettings[i]=new PVector();
    bestDiagonalSettings[i]=new PVector();
  }  
  int num;




  ///     scan through all possible peaks
  for (allowedDeviation=0; allowedDeviation<.2; allowedDeviation+=.05)
    for (minPeakFreq=5; minPeakFreq<30; minPeakFreq++)
      for (minPeakAmplitude=5; minPeakAmplitude<50; minPeakAmplitude++)
      {
        //        println(allowedDeviation+" "+minPeakFreq+" "+minPeakAmplitude);
        for (int j=0; j<numPorts; j++)
        {
          data=new int[horizontalScanLength];
          for (int i=0; i<data.length; i++)
            data[i]=horizontalScan[i][j];
          data=lowPass(data);
          peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
          num=0;
          for (int k=0; k<numSlices; k++)
            if (peaks[k]>0)
              num++;
          if (num>numHorizontalPeaks[j])   
          {    
            numHorizontalPeaks[j]=num;
            bestHorizontalSettings[j]=new PVector(allowedDeviation, minPeakFreq, minPeakAmplitude);
            for (int peak=0; peak<numSlices; peak++)
              dezHorizontalPeaks[peak][j]=(int)peaks[peak];
          }
          data=new int[diagonalScanLength];
          for (int i=0; i<data.length; i++)
            data[i]=diagonalScan[i][j];
          data=lowPass(data);
          peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
          num=0;
          for (int k=0; k<numSlices; k++)
            if (peaks[k]>0)
              num++;
          if (num>numDiagonalPeaks[j])   
          {    
            bestDiagonalSettings[j]=new PVector(allowedDeviation, minPeakFreq, minPeakAmplitude);
            numDiagonalPeaks[j]=num;
            for (int peak=0; peak<numSlices; peak++)
              dezDiagonalPeaks[peak][j]=(int)peaks[peak];
          }
        }
      }
  //


  /*
  
   for (allowedDeviation=0; allowedDeviation<.2; allowedDeviation+=.05)
   for (minPeakFreq=5; minPeakFreq<30; minPeakFreq++)
   for (minPeakAmplitude=5; minPeakAmplitude<50; minPeakAmplitude++)
   {
   //        println(allowedDeviation+" "+minPeakFreq+" "+minPeakAmplitude);
   for (int j=0; j<numPorts; j++)
   {
   data=new int[horizontalScanLength];
   for (int i=0; i<data.length; i++)
   data[i]=horizontalScan[i][j];
   data=lowPass(data);
   peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
   num=0;
   for (int k=0; k<numSlices; k++)
   if (peaks[k]>0)
   num++;
   if (num>numHorizontalPeaks[j])   
   {    
   numHorizontalPeaks[j]=num;
   bestHorizontalSettings[j]=new PVector(allowedDeviation, minPeakFreq, minPeakAmplitude);
   for (int peak=0; peak<numSlices; peak++)
   dezHorizontalPeaks[peak][j]=(int)peaks[peak];
   }
   data=new int[diagonalScanLength];
   for (int i=0; i<data.length; i++)
   data[i]=diagonalScan[i][j];
   data=lowPass(data);
   peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
   num=0;
   for (int k=0; k<numSlices; k++)
   if (peaks[k]>0)
   num++;
   if (num>numDiagonalPeaks[j])   
   {    
   bestDiagonalSettings[j]=new PVector(allowedDeviation, minPeakFreq, minPeakAmplitude);
   numDiagonalPeaks[j]=num;
   for (int peak=0; peak<numSlices; peak++)
   dezDiagonalPeaks[peak][j]=(int)peaks[peak];
   }
   }
   }
   */
  //
}

void findPeaks()
{
  bestHorizontalSettings=new PVector[numPorts];
  bestDiagonalSettings=new PVector[numPorts];
  diagonalLowPass=new int[diagonalScanLength][numPorts];
  horizontalLowPass=new int[horizontalScanLength][numPorts];
  diagonalDerivative=new int[diagonalScanLength][numPorts];

  dezHorizontalPeaks=new int[numSlices][numPorts];
  dezDiagonalPeaks=new int[numSlices][numPorts];

  horizontalDerivative=new int[horizontalScanLength][numPorts];
  horizontalPeaks=new FloatList[numPorts];
  diagonalPeaks=new FloatList[numPorts];
  int[] data;
  float[] peaks;
  for (int j=0; j<numPorts; j++)
  {
    data=new int[horizontalScanLength];
    for (int i=0; i<data.length; i++)
      data[i]=horizontalScan[i][j];
    peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
    for (int peak=0; peak<numSlices; peak++)
      dezHorizontalPeaks[peak][j]=(int)peaks[peak];
    data=new int[diagonalScanLength];
    for (int i=0; i<data.length; i++)
      data[i]=diagonalScan[i][j];
    peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
    for (int peak=0; peak<numSlices; peak++)
      dezDiagonalPeaks[peak][j]=(int)peaks[peak];
  }


  for (int j=0; j<numPorts; j++)
  {
    data=new int[horizontalScanLength];
    //    println(data.length);
    for (int i=0; i<data.length; i++)
      data[i]=horizontalScan[i][j];  



    IntList unfilteredPeaks=processData(lowPass(data));
    horizontalPeaks[j]=new FloatList();
    for (int i=0; i<unfilteredPeaks.size (); i++)
      horizontalPeaks[j].append((int)unfilteredPeaks.get(i));
    //horizontalPeaks[j]=justPeaks(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);   
    //    horizontalPeaks[j]=derivativeFilter(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, unfilteredPeaks);
    for (int i=0; i<data.length; i++)
    {
      horizontalLowPass[i][j]=secondPass[i];
      horizontalDerivative[i][j]=filteredDerivative[i];
    }
    data=new int[diagonalScanLength];
    for (int i=0; i<data.length; i++)
      data[i]=diagonalScan[i][j];
    //    diagonalPeaks[j]=processData(data);
    unfilteredPeaks=processData(lowPass(data));
    /*
    unfilteredPeaks=processData(data);
     diagonalPeaks[j]=derivativeFilter(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, unfilteredPeaks);
     */
    diagonalPeaks[j]=new FloatList();
    for (int i=0; i<unfilteredPeaks.size (); i++)
      diagonalPeaks[j].append((int)unfilteredPeaks.get(i));
    //diagonalPeaks[j]=justPeaks(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
    for (int i=0; i<data.length; i++)
    {
      diagonalLowPass[i][j]=secondPass[i];
      diagonalDerivative[i][j]=filteredDerivative[i];
    }
  }
}


void draw()
{
  background(0);
  if (frameCount<5)  //read in data for the first 20 frames, just to filter out any funky startup values
  {
    if (state==0)
      getData();
  } else
    if (!scanning)  //after thost first 20 frames, set scanning to true and start reading data for reals
    scanning=true;

  if (scanning)
  {
    if (state==0)  //horizontal
    {
      drawGradientLine(position, 0, 20);
      getData();
      position+=skip;
      if (position>=horizontalScanLength)
      {
        position=0;
        state++;
        lastFrame=frameCount;
      }
    } else if (state==1)  //diagonal
    {
      drawGradientLine(position, -1, 40);      
      getData();
      if (frameCount>lastFrame+5)
        position+=skip;
      if (position>=diagonalScanLength)
      {
        position=0;
        state++;
      }
    } else if (state==2)
    {
      exportCSV();
      state++;
    } else if (state==3)
    {
      findPeaks();
      state++;
    }
  }
  if (!scanning||displayData)
  {
    for (int j=0; j<numPorts; j++)
    {
      min[j]=100000;
      max[j]=1;
    }
    if (state==0)
    {
      for (int j=0; j<numPorts; j++)
        for (int i=0; i<horizontalScanLength; i++)
        {
          if (horizontalScan[i][j]!=0)
            if (horizontalScan[i][j]<min[j])
              min[j]=horizontalScan[i][j];
          if (horizontalScan[i][j]>max[j])
            max[j]=horizontalScan[i][j];
        }
      /*
      for (int j=0; j<numPorts; j++)
       for (int i=0; i<horizontalScanLength-1; i++)
       {
       stroke(50, 0, 0);
       line(map(i, 0, horizontalScanLength, 0, width), displayHeight(horizontalScan[i][j], j), map(i+1, 0, horizontalScanLength, 0, width), displayHeight(horizontalScan[i+1][j],j));
       }
       */
      stroke(50, 0, 0);
      for (int i=0; i<horizontalScanLength-1; i++)
        line(map(i, 0, horizontalScanLength, 0, width), displayHeight(horizontalScan[i][selectedIndex], selectedIndex), map(i+1, 0, horizontalScanLength, 0, width), displayHeight(horizontalScan[i+1][selectedIndex], selectedIndex));
    }
    if (state==1)
    {
      for (int j=0; j<numPorts; j++)
        for (int i=0; i<diagonalScanLength; i++)
        {
          if (diagonalScan[i][j]!=0)
            if (diagonalScan[i][j]<min[j])
              min[j]=diagonalScan[i][j];
          if (diagonalScan[i][j]>max[j])
            max[j]=diagonalScan[i][j];
        }
      /*
      for (int j=0; j<numPorts; j++)
       for (int i=0; i<diagonalScanLength-1; i++)
       {
       stroke(50, 0, 0);
       line(map(i, 0, diagonalScanLength, 0, width), displayHeight(diagonalScan[i][j],j), map(i+1, 0, diagonalScanLength, 0, width), displayHeight(diagonalScan[i+1][j], j));
       }
       */
      stroke(50, 0, 0);
      for (int i=0; i<diagonalScanLength-1; i++)
        line(map(i, 0, diagonalScanLength, 0, width), displayHeight(diagonalScan[i][selectedIndex], selectedIndex), map(i+1, 0, diagonalScanLength, 0, width), displayHeight(diagonalScan[i+1][selectedIndex], selectedIndex));
    }
    if (state==4)
    {
      if (selectedData)
      {
        for (int j=0; j<numPorts; j++)
          for (int i=0; i<horizontalScanLength; i++)
          {
            if (horizontalScan[i][j]!=0)
              if (horizontalScan[i][j]<min[j])
                min[j]=horizontalScan[i][j];
            if (horizontalScan[i][j]>max[j])
              max[j]=horizontalScan[i][j];
          }
        stroke(255);
        for (int i=0; i<horizontalScanLength-1; i++)
          line(map(i, 0, horizontalScanLength, 0, width), displayHeight(horizontalScan[i][selectedIndex], selectedIndex), map(i+1, 0, horizontalScanLength, 0, width), displayHeight(horizontalScan[i+1][selectedIndex], selectedIndex));
        stroke(255, 255, 0);
        if (showDerivativePeaks)        
        {
          for (int i=0; i<horizontalPeaks[selectedIndex].size (); i++)
            line(map(horizontalPeaks[selectedIndex].get(i), 0, horizontalScanLength, 0, width), 0, map(horizontalPeaks[selectedIndex].get(i), 0, horizontalScanLength, 0, width), height);
          stroke(0, 255, 0);
          for (int i=0; i<horizontalScanLength-1; i++)
            line(map(i, 0, horizontalScanLength, 0, width), displayHeight(horizontalLowPass[i][selectedIndex], selectedIndex), map(i+1, 0, horizontalScanLength, 0, width), displayHeight(horizontalLowPass[i+1][selectedIndex], selectedIndex));
          stroke(255, 0, 0);
          for (int i=0; i<horizontalScanLength-1; i++)
            line(map(i, 0, horizontalScanLength, 0, width), displayHeight(scale*horizontalDerivative[i][selectedIndex], selectedIndex), map(i+1, 0, horizontalScanLength, 0, width), displayHeight(scale*horizontalDerivative[i+1][selectedIndex], selectedIndex));
        } 
        if (showDezPeaks)
        {
          stroke(0, 0, 255);
          for (int i=0; i<numSlices; i++)
            line(map(dezHorizontalPeaks[i][selectedIndex], 0, horizontalScanLength, 0, width), 0, map(dezHorizontalPeaks[i][selectedIndex], 0, horizontalScanLength, 0, width), height);
          fill(255);
          for (int i=0; i<numSlices; i++)
            text(dezHorizontalPeaks[i][selectedIndex], 10, 50+20*i);
          if (fancyPeaks)
            text(bestHorizontalSettings[selectedIndex].x+" "+bestHorizontalSettings[selectedIndex].y+" "+bestHorizontalSettings[selectedIndex].z, width-200, 50);
        }
        if (showLocality)
        {
          stroke(255, 0, 255);
          for (int i=0; i<horizontalLocalityPeaks[selectedIndex].size (); i++)
            line(map(horizontalLocalityPeaks[selectedIndex].get(i), 0, horizontalScanLength, 0, width), 0, map(horizontalLocalityPeaks[selectedIndex].get(i), 0, horizontalScanLength, 0, width), height);   
          fill(255);
          text("locality:  "+locality, width-200, 100);
        }
        fill(255);
        text(((int)map(mouseX, 0, width, 0, horizontalScanLength-1))+", "+horizontalScan[(int)map(mouseX, 0, width, 0, horizontalScanLength-1)][selectedIndex], 10, 30);
      } else
      {
        for (int j=0; j<numPorts; j++)
          for (int i=0; i<diagonalScanLength; i++)
          {
            if (diagonalScan[i][j]!=0)
              if (diagonalScan[i][j]<min[j])
                min[j]=diagonalScan[i][j];
            if (diagonalScan[i][j]>max[j])
              max[j]=diagonalScan[i][j];
          }
        stroke(255);
        for (int i=0; i<diagonalScanLength-1; i++)
          line(map(i, 0, diagonalScanLength, 0, width), displayHeight(diagonalScan[i][selectedIndex], selectedIndex), map(i+1, 0, diagonalScanLength, 0, width), displayHeight(diagonalScan[i+1][selectedIndex], selectedIndex));
        if (showDerivativePeaks)
        {        
          stroke(255, 255, 0);
          //  for (int i=0; i<diagonalPeaks[selectedIndex].size (); i++)
          //    line(diagonalPeaks[selectedIndex].get(i), 0, diagonalPeaks[selectedIndex].get(i), height);
          stroke(0, 255, 0);
          for (int i=0; i<diagonalScanLength-1; i++)
            line(map(i, 0, diagonalScanLength, 0, width), displayHeight(diagonalLowPass[i][selectedIndex], selectedIndex), map(i+1, 0, diagonalScanLength, 0, width), displayHeight(diagonalLowPass[i+1][selectedIndex], selectedIndex));
          for (int i=0; i<diagonalPeaks[selectedIndex].size (); i++)
            line(map(diagonalPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), 0, map(diagonalPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), height);
          stroke(255, 0, 0);
          for (int i=0; i<diagonalScanLength-1; i++)
            line(map(i, 0, diagonalScanLength, 0, width), displayHeight(scale*diagonalDerivative[i][selectedIndex], selectedIndex), map(i+1, 0, diagonalScanLength, 0, width), displayHeight(scale*diagonalDerivative[i+1][selectedIndex], selectedIndex));
        } 
        if (showDezPeaks)
        {
          stroke(0, 0, 255);
          for (int i=0; i<numSlices; i++)
            line(map(dezDiagonalPeaks[i][selectedIndex], 0, diagonalScanLength, 0, width), 0, map(dezDiagonalPeaks[i][selectedIndex], 0, diagonalScanLength, 0, width), height);
          fill(255);
          for (int i=0; i<numSlices; i++)
            text(dezDiagonalPeaks[i][selectedIndex], 10, 50+20*i);
          if (fancyPeaks)
            text(bestDiagonalSettings[selectedIndex].x+" "+bestDiagonalSettings[selectedIndex].y+" "+bestDiagonalSettings[selectedIndex].z, width-200, 50);
        }
        fill(255);
        text(((int)map(mouseX, 0, width, 0, diagonalScanLength-1))+", "+diagonalScan[(int)map(mouseX, 0, width, 0, diagonalScanLength-1)][selectedIndex], 10, 30);
      }
      if (showLocality)
      {
        stroke(255, 0, 255);
        for (int i=0; i<diagonalLocalityPeaks[selectedIndex].size (); i++)
          line(map(diagonalLocalityPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), 0, map(diagonalLocalityPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), height);   
        fill(255);
        text("locality:  "+locality, width-200, 100);
      }
      if (!derivativePeaks)
      {
        fill(255);
        text("minPeakFreq:  "+minPeakFreq, width-200, 10);
        text("minPeakAmplitude:  "+minPeakAmplitude, width-200, 30);
      }
    }
    fill(255, 0, 0);
    text(selectedIndex, 10, 10);
  }
}

void keyPressed()
{
  if (key==' ')
    displayData=!displayData;
  //  if (key=='s')
  //    exportCSV();
  if (keyCode==UP)
    selectedIndex++;
  if (selectedIndex>=numPorts)
    selectedIndex=0;
  if (keyCode==DOWN)
    selectedIndex--;
  if (selectedIndex<0)
    selectedIndex=numPorts-1;
  if (keyCode==ENTER)
    selectedData=!selectedData;
  if (key=='w')
    minPeakAmplitude+=minPeakInc;
  if (key=='s')
  {
    minPeakAmplitude-=minPeakInc;
    if (minPeakAmplitude<1)
      minPeakAmplitude=1;
  }

  if (key=='d')
    minPeakFreq+=minFreqInc;
  if (key=='a')
    minPeakFreq-=minFreqInc;
  if (key=='f')
    findPeaks();
  if (key=='1')
    showDerivativePeaks=!showDerivativePeaks;
  if (key=='2')
    showDezPeaks=!showDezPeaks;
  if (key=='+')
    locality++;
  if (key=='-')
    if (locality>0)
      locality--;
  simplePeaks();        

  if (key=='~')
  {
    print("int[] data={");
    if (selectedData)
      for (int i=0; i<horizontalScanLength; i++)
        print(horizontalScan[i][selectedIndex]+",");
    else
      for (int i=0; i<diagonalScanLength; i++)
      print(diagonalScan[i][selectedIndex]+",");
    println("};");
  }
}

void exportCSV()
{

  PrintWriter output;

  output=createWriter(dataPath("run "+run+".csv"));
  for (int j=0; j<numPorts; j++)
  {
    for (int i=0; i<diagonalScanLength; i++)
      output.print(diagonalScan[i][j]+",");      
    output.println();
    for (int i=0; i<horizontalScanLength; i++)
      output.print(horizontalScan[i][j]+",");      
    output.println();
  }
  output.flush();
  output.close();

  //update the run number in run.txt, so we don't write over old data
  output=createWriter(dataPath("run.txt"));
  output.println(run);
  output.flush();
  output.close();
}



int displayHeight(int num, int index)
{
  return((int)map(num, min[index], max[index], 800, 0));
}

void mouseClicked()
{
  location=new PVector(mouseX, mouseY);
}

void setupSensors()
{
  if (state==0) {
    settingUpSensors=true; 

    serialPorts=new StringList(); 
    for (int i=0; i<Serial.list ().length; i++)
    {
      if (Serial.list()[i].indexOf("tty.wch")!=-1)
      {
        serialPorts.append(Serial.list()[i]); 
        println(num+" "+serialPorts.get(num-1)); 
        num++;
      }
    }
    numPorts=serialPorts.size(); 
    Serial[] tempPorts=new Serial[numPorts];
    ports=new Serial[numPorts];
    for (int i=0; i<numPorts; i++)
      tempPorts[i]=new Serial(this, serialPorts.get(i), 115200);
    delay(3000);
    String[] mappedPorts=new String[numPorts];
    for (int i=0; i<numPorts; i++)
    {
      //    tempPorts[i].write((int)(integrationTime/100));
      tempPorts[i].write(1);
      tempPorts[i].write(10);  //max gain
    }
    delay(100);
    for (int i=0; i<numPorts; i++)
      tempPorts[i].clear();  
    for (int i=0; i<numPorts; i++)
      tempPorts[i].write("i");    
    delay(250);
    for (int i=0; i<numPorts; i++)  
    {
      String s=tempPorts[i].readStringUntil('\n').trim();
      println(s);
      int index=int(s);
      mappedPorts[index-1]=serialPorts.get(i);
      tempPorts[i].stop();
    }  

    for (int i=0; i<numPorts; i++)
    {
      println((i+1)+":  "+mappedPorts[i]);
      ports[i]=new Serial(this, mappedPorts[i], 115200);
    }

    horizontalScan=new int[horizontalScanLength][numPorts];
    diagonalScan=new int[diagonalScanLength][numPorts];  
    for (int j=0; j<numPorts; j++)
      for (int i=0; i<horizontalScanLength; i++)
      {
        horizontalScan[i][j]=0;    
        diagonalScan[i][j]=0;
      }
    min=new int[numPorts];
    max=new int[numPorts];
  }
}

void getData()
{
  println("sending data");
  int[] returnedValues=new int[numPorts];
  for (int i=0; i<numPorts; i++)
  {
    ports[i].write(' ');
    returnedValues[i]=-1;
  }
  delay(150);
  for (int i=0; i<numPorts; i++)
  {
    println(i);    
    while (returnedValues[i]==-1)
    {
      String val=ports[i].readStringUntil('\n');
      if (val!=null)
      {
        val=val.trim();
        returnedValues[i]=int(val);
        ports[i].clear();
      } else
      {
        ports[i].write(' ');
        delay(150);
      }
    }
  }
  for (int i=0; i<numPorts; i++)
  {
    if (state==0) //horizontal
    {
      horizontalScan[position][i]=returnedValues[i];
      if (position>=skip)    //interpolation
        for (int j=1; j<skip; j++)
        {
          println(position+" "+(position-j)+" "+j);
          horizontalScan[position-j][i]=horizontalScan[position][i]*(skip-j)/skip+horizontalScan[position-skip][i]*j/skip;
        }
    }
    if (state==1)
    {  //diagonal
      diagonalScan[position][i]=returnedValues[i];
      if (position>=skip)    //interpolation
        for (int j=1; j<skip; j++)
          diagonalScan[position-j][i]=diagonalScan[position][i]*(skip-j)/skip+diagonalScan[position-skip][i]*j/skip;
    }
  }
}


void drawGradientLine(int pos, float m, int gradientWidth)
{
  strokeWeight(1); 
  stroke(255); 
  stroke(255);
  if (m==1)
  {
    line(0, height-pos, width, width*m+height-pos); 
    for (int i=1; i<gradientWidth; i++)
    {
      // x=0
      //y=mx+b=b

      //x=width
      //y=m*width+b
      stroke(255*(gradientWidth-i)/gradientWidth); 
      line(0, -i+height-pos, width, width*m-i+height-pos); 
      line(0, +i+height-pos, width, width*m+i+height-pos);
    }
  } else
  {  
    line(0, pos, width, width*m+pos); 
    for (int i=1; i<gradientWidth; i++)
    {
      // x=0
      //y=mx+b=b

      //x=width
      //y=m*width+b
      stroke(255*(gradientWidth-i)/gradientWidth); 
      line(0, pos-i, width, width*m+pos-i); 
      line(0, pos+i, width, width*m+pos+i);
    }
  }
}

