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
        if (showDezPost)
        {
          stroke(255, 0, 255);
          for (int i=0; i<dezHorizontalPost[selectedIndex].size (); i++)
            line(map(dezHorizontalPost[selectedIndex].get(i), 0, horizontalScanLength, 0, width), 0, map(dezHorizontalPost[selectedIndex].get(i), 0, horizontalScanLength, 0, width), height);
        }
        if (showDezPeaks)
        {
          stroke(0, 0, 255);
          for (int i=0; i<dezHorizontalPeaks[selectedIndex].size (); i++)
            line(map(dezHorizontalPeaks[selectedIndex].get(i), 0, horizontalScanLength, 0, width), 0, map(dezHorizontalPeaks[selectedIndex].get(i), 0, horizontalScanLength, 0, width), height);

          fill(255);
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
          stroke(255, 0, 0);
          for (int i=0; i<diagonalScanLength-1; i++)
            line(map(i, 0, diagonalScanLength, 0, width), displayHeight(diagonalLowPass[i][selectedIndex], selectedIndex), map(i+1, 0, diagonalScanLength, 0, width), displayHeight(diagonalLowPass[i+1][selectedIndex], selectedIndex));
          for (int i=0; i<diagonalPeaks[selectedIndex].size (); i++)
            line(map(diagonalPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), 0, map(diagonalPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), height);
          stroke(0, 255, 0);
          for (int i=0; i<diagonalScanLength-1; i++)
            line(map(i, 0, diagonalScanLength, 0, width), displayHeight(scale*diagonalDerivative[i][selectedIndex], selectedIndex), map(i+1, 0, diagonalScanLength, 0, width), displayHeight(scale*diagonalDerivative[i+1][selectedIndex], selectedIndex));
        } 
            if(showDezPost)
            {
          stroke(255, 0, 255);
          for (int i=0; i<dezDiagonalPost[selectedIndex].size (); i++)
            line(map(dezDiagonalPost[selectedIndex].get(i), 0, diagonalScanLength, 0, width), 0, map(dezDiagonalPost[selectedIndex].get(i), 0, diagonalScanLength, 0, width), height);
            }
        if (showDezPeaks)
        {
          stroke(0, 0, 255);
          for (int i=0; i<dezDiagonalPeaks[selectedIndex].size(); i++)
            line(map(dezDiagonalPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), 0, map(dezDiagonalPeaks[selectedIndex].get(i), 0, diagonalScanLength, 0, width), height);
          fill(255);
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
    text("sensor:  ("+(selectedIndex%3)+", "+(selectedIndex/3)+" )", 10, 10);
    text("press 1 to toggle derivative peaks, 2 to toggle dez peaks", 10, 50);
    fill(0, 0, 255);
    if (showDezPeaks)
      text("dez peaks", 10, 70);
    fill(255, 0, 0);
    if (showDerivativePeaks)
      text("derivative peaks", 10, 90);
  }
}