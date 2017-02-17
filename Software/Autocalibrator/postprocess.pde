



void postProcess(IntList peaks)
{
  FloatList floatPeaks=new FloatList();
  for (int i=0; i<peaks.size (); i++)
    floatPeaks.append(peaks.get(i));
  postProcess(floatPeaks, numSlices);
}

FloatList postProcess(FloatList candidates, int expectedPeaks)
{
  FloatList output = new FloatList();
  if (expectedPeaks < 3) //if we have less than 3 expected peaks, the code below this is useless. Just return what we have.
    output = candidates;
  else
  {
    //finally, lets do a check to make sure that the peaks are evenly distributed, removing or replacing any that are not;
    //so first we do a diff comparison between all of them.
    //then remove any where the differences were more than 15% of the rest and do it again.
    FloatList differences = new FloatList();
    for (int i = 0; i < candidates.size () -1; i ++)
    {
      differences.append(candidates.get(i + 1) - candidates.get(i));
    }
    
    
    //this method below is not a good one because it is susceptible to drift.
    //filter the peaks by going one to the next and determining the outliers like that.
 /*   int medianIndex = 0;
    //float medianDiff = findOutliers(differences, allowedDeviation,  medianIndex);
    float medianDiff = findMedian(differences);

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
   */ 
  }

  int missingElements = expectedPeaks - output.size(); //add any missing.
  for (int i = 0; i < missingElements; i++)
  {
    output.append(badValue);
  }

  return output;
}

float findMedian(FloatList[] f)
{
  FloatList allValues = new FloatList();
  for (int i = 0; i < f.length; i++)
  {
    for (int l = 0; l < f[i].size(); l++)
      allValues.append( f[i].get(l));
  }

  allValues.sort();

  int medianElement = round(allValues.size()/2);
  return allValues.get(medianElement);
}

/*
float findOutliers(FloatList data, float allowedDeviation, int medianIndex)
{
  if (data.size() < 3) //there is no point to doing this with a tiny amount of data points.
  {
    medianIndex = 0;
    return data.get(0);
  }
  

  //returns the median difference. outlying values are given in 'outliers'
  float[] sorted=sort(data.array());

  int medianElement = round(sorted.length/2);
  float median = sorted[medianElement];

  FloatList badElements = new FloatList();
  for (int i=0; i<sorted.length; i++)
  {
    float f=sorted[i];
    float diff = f > median ? f - median : median - f;
    if (diff > median * allowedDeviation)
      badElements.append(f);
  }


  medianIndex = 0;
  for (int d = 0; d < data.size (); d++)
  {
    if (data.get(d) == median)
      medianIndex = d;
  }

  return median;
}
*/

boolean checkPeak(int first, int middle, int last, int threshold)
{
  return (middle - first > threshold && middle - last > threshold);
}       

float findPeakInDataPoints(IntList dataPoints, int[] allData, float bias)
{
  // use a weighted average to find the peak
  double total = 0;
  double div = 0;
  for (int i=0; i<dataPoints.size (); i++)
  {
    int d=dataPoints.get(i);
    double pow = pow(allData[d], bias);
    total += d * pow;
    div += pow;
  }
  return (float)(total/div);
}