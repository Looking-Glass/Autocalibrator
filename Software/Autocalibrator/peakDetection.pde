int[] numHorizontalPeaks, numDiagonalPeaks;
  float badValue = -9999f; //what value do we return in the array when we think there is a missing element there?

void findBestDezPeaks()
{
  int[] data;
  numHorizontalPeaks=new int[numPorts];
  numDiagonalPeaks=new int[numPorts];
  ///    find Dez peaks by scan through all possible settings and looking for the most peaks
  for (allowedDeviation=0; allowedDeviation<.2; allowedDeviation+=.05)
    for (minPeakFreq=5; minPeakFreq<30; minPeakFreq+=5)
      for (minPeakAmplitude=5; minPeakAmplitude<50; minPeakAmplitude+=5)
      {
        //        println(allowedDeviation+" "+minPeakFreq+" "+minPeakAmplitude);
        for (int j=0; j<numPorts; j++)
        {
          data=new int[horizontalScanLength];
          for (int i=0; i<data.length; i++)
            data[i]=horizontalScan[i][j];
          data=lowPass(data,10);  //try putting the data through a low-pass filter first
          peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
          num=0;
          if (peaks.size()>numHorizontalPeaks[j])   
          {    
            numHorizontalPeaks[j]=peaks.size();
            bestHorizontalSettings[j]=new PVector(allowedDeviation, minPeakFreq, minPeakAmplitude);
            dezHorizontalPeaks[j]=peaks;
          }
          data=new int[diagonalScanLength];
          for (int i=0; i<data.length; i++)
            data[i]=diagonalScan[i][j];
          data=lowPass(data, 10 );  //try putting the data through a low-pass filter first
          peaks=getPeaksFromData(minPeakAmplitude, minPeakFreq, numSlices, allowedDeviation, data);
          num=0;
          for (int k=0; k<peaks.size (); k++)
            if (peaks.get(k)>0)
              num++;
          if (num>numDiagonalPeaks[j])   
          {    
            bestDiagonalSettings[j]=new PVector(allowedDeviation, minPeakFreq, minPeakAmplitude);
            numDiagonalPeaks[j]=num;
            dezDiagonalPeaks[j]=peaks;
          }
        }
      }
}


FloatList getPeaksFromData(int minPeakAmplitude, int minPeakFreq, int expectedPeaks, float allowedDeviation, int[] data)
{

  //first lets bottom out the data. This will help with figuring out the center of the peaks later.
  int minVal = 100000;
  for (int i=0; i<data.length; i++)
  {
    if (i < minVal)
      minVal = i;
  }
  for (int i = 0; i < data.length; i++)
  {
    data[i] -= minVal;
  }


  //then, we will filter out what parts of the data count as a part of a peak.
  int halfFreq = round((float)minPeakFreq/2);
  int first = 0;
  int last = 0;
  IntList peakData = new IntList(); //store here any values that meet basic peak criteria
  for (int i = 0; i < data.length; i++)
  {
    first = i - halfFreq;
    last = i + halfFreq;

    if (first < 0 && last >= data.length)
      println("Data set is too small to analyze using a minPeakFreq of " + minPeakFreq);

    if (first < 0) //near start of analysis
    {
      if (checkPeak(0, data[i], data[last], minPeakAmplitude))
        peakData.append(i);
    } 
    else if (last >= data.length) //near end of analysis
    {
      if (checkPeak(data[first], data[i], 0, minPeakAmplitude))
        peakData.append(i);
    } 
    else //normal path
    {
//      println(first+" "+last+" "+minPeakAmplitude+" "+halfFreq+" "+minPeakFreq);
      if (checkPeak(data[first], data[i], data[last], minPeakAmplitude))
        peakData.append(i);
    }
  }

  if (peakData.size() == 0) //sanity check
  {
//    println("Could not find any peaks in the given data. Is the sensor broken? Printing raw data to log...");
    //    println(data);
    FloatList error=new FloatList();
    for (int i=0; i<numSlices; i++)
      error.append(-1);
    return error; //could not find peaks
  }


  //now we know what parts of the data are part of peaks. Let's arrange them into groups (peaks).
  //maxAllowedMissingDataPoints will be used to separate out the peaks from each other.
  ArrayList noisyPeaks=new ArrayList<IntList>();
  int maxAllowedMissingDataPoints =  round(minPeakFreq / 5);
  if (maxAllowedMissingDataPoints < 5)
    maxAllowedMissingDataPoints = 5;
  int currentPeak = 0;
  noisyPeaks.add(new IntList());
  for (int d = 0; d < peakData.size ()-1; d++)
  {
    ((IntList)noisyPeaks.get(currentPeak)).append(peakData.get(d));

    if (peakData.get(d + 1) - peakData.get(d) >= maxAllowedMissingDataPoints)
    {
      noisyPeaks.add(new IntList());
      currentPeak++;
    }
  }

  //lets, ignore any peaks with very few data points (which are probably noise)
  ArrayList peaks=new ArrayList<IntList>();
  for (int p = 0; p < noisyPeaks.size (); p++)
  {
    if (((IntList)noisyPeaks.get(p)).size() >= 3)   //# is the amount of data points needed to consider a peak
      peaks.add(noisyPeaks.get(p));
  }


  //now lets do a biased average of the data contained in each peak, and prepare to return that as our final values.
  FloatList candidates = new FloatList();
  for (int i=0; i<peaks.size (); i++)
  {
    candidates.append(findPeakInDataPoints((IntList)peaks.get(i), data, 10));
  }
  
  return candidates;
  //return postProcessPeaks(candidates);  //originally, the code would continue like this

}