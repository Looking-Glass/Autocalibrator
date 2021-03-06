int numPoints;
int[] buffer, secondPass, derivative, filteredDerivative;
LowPass lp;
boolean showSecond=true, showOriginal, showDerivative=true, showPeaks=true;
int fileIndex=0;
int derivativeScale=25;
FloatList peaks;
int to, from;

FloatList processData(int[] rawData)
{
  return processData(rawData, 25, 20);
}


FloatList processData(int[] rawData, int filterDegree, int derivativeFilterDegree)
{
  peaks=new FloatList();
  int numPoints=rawData.length;

  buffer=new int[numPoints];
  secondPass=new int[numPoints];
  derivative=new int[numPoints];
  filteredDerivative=new int[numPoints];

  secondPass=lowPass(rawData, filterDegree);  //phase-correct low-pass
  for (int i=0; i<numPoints-1; i++)
    derivative[i]=secondPass[i+1]-secondPass[i];
  filteredDerivative=lowPass(derivative, derivativeFilterDegree);    
  for (int i=0; i<numPoints-1; i++)
  {
    if ((filteredDerivative[i+1]<=0)&&(filteredDerivative[i]>0))
      peaks.append(i+1);
  }  
  return peaks;
}


void findDerivativePeaks()
{
  int[] data;
  for(int i=0;i<numPorts;i++)
    {
      data=new int[horizontalScanLength];
      for(int j=0;j<horizontalScanLength;j++)
        data[j]=horizontalScan[j][i];
      horizontalPeaks[i]=processData(data);
      data=new int[diagonalScanLength];
      for(int j=0;j<diagonalScanLength;j++)
        data[j]=diagonalScan[j][i];
      diagonalPeaks[i]=processData(data);
    }
}

IntList bruteForce(int[] data, int locality)
{
  IntList peaks=new IntList();
  for (int i=locality; i<data.length-locality; i++)
  {
    if ((data[i-locality]<data[i])&&(data[i+locality]<data[i]))
      peaks.append(i);
  }
  IntList removeList=new IntList();
  for (int i=0; i<peaks.size (); i++)
    for (int j=0; j<peaks.size (); j++)
  {
    if ((sqrt(pow(i-j, 2))<locality)&&(i!=j))
      if (data[peaks.get(i)]>data[peaks.get(j)])
      removeList.append(j);
  }
  for (int i=0; i<removeList.size (); i++)
  {
    peaks.remove(i);
    for (int j=i; j<removeList.size (); j++)
      removeList.set(j, removeList.get(j)-1);
  }
  return peaks;
}



int[] lowPass(int[] data, int filterDegree)
{
  int numPoints=data.length;

  buffer=new int[numPoints];
  secondPass=new int[numPoints];
  lp=new LowPass(filterDegree);
  for (int i=0; i<numPoints; i++)
  {
    lp.input(data[i]);
    buffer[i]=(int)lp.output;
  }
  lp=new LowPass(filterDegree);
  for (int i=numPoints-1; i>=0; i--)
  {
    lp.input(buffer[i]);
    secondPass[i]=(int)lp.output;
  }
  return secondPass;
}


FloatList derivativeFilter(int minPeakAmplitude, int minPeakFreq, int expectedPeaks, float allowedDeviation, IntList candidates)
{
  float badValue = -9999f; //what value do we return in the array when we think there is a missing element there?
  FloatList output = new FloatList();
  if (expectedPeaks < 3) //if we have less than 3 expected peaks, the code below this is useless. Just return what we have.
  {
    for (int i=0; i<candidates.size (); i++)
      output.append(candidates.get(i));
  } else
  {
    //finally, lets do a check to make sure that the peaks are evenly distributed, removing or replacing any that are not;
    //so first we do a diff comparison between all of them.
    //then remove any where the differences were more than 15% of the rest and do it again.
    FloatList differences = new FloatList();
    for (int i = 0; i < candidates.size () -1; i ++)
    {
      differences.append(candidates.get(i + 1) - candidates.get(i));
    }
    float[] outliers=new float[0];
    int medianIndex = 0;
    float medianDiff = findOutliers(differences, allowedDeviation, outliers, medianIndex);

    //now lets go through them again, this time having some statistical info in hand (median values)                  
    float startingOffset = candidates.get(medianIndex) % medianDiff; //as best we can know, the medianDiff and medianIndex are well placed data, so lets use them as a base point to check the rest.

    //compare our found peaks to where we expect them to be based on the median info. namely, at a mostly steady distance from each other (within allowedDeviation).                    
    for (int i = 0; i < expectedPeaks; i++)
    {
      float expectedVal = startingOffset + (i * medianDiff);
      boolean foundMatch = false;
      for (int c = 0; c < candidates.size (); c++)
      {
        float testDiff = candidates.get(c) > expectedVal ? candidates.get(c) - expectedVal : expectedVal - candidates.get(c);
        if (testDiff <= medianDiff * allowedDeviation)
        {
          output.append(candidates.get(c));
          foundMatch = true;
          break;
        }
      }

      if (!foundMatch)
        output.append(badValue);
    }
  }

  int missingElements = expectedPeaks - output.size(); //add any missing.
  for (int i = 0; i < missingElements; i++)
    output.append(badValue);

  return output;
}


class LowPass {
  ArrayList buffer;
  int len;
  float output;

  LowPass(int len) {
    this.len = len;
    buffer = new ArrayList(len);
    for (int i = 0; i < len; i++) {
      buffer.add(new Float(0.0));
    }
  }

  void input(float v) {
    buffer.add(new Float(v));
    buffer.remove(0);

    float sum = 0;
    for (int i=0; i<buffer.size (); i++) {
      Float fv = (Float)buffer.get(i);
      sum += fv.floatValue();
    }
    output = sum / buffer.size();
  }
}

