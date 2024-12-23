//+------------------------------------------------------------------+
//|                                                          pd5.mq5 |
//|                                    	Copyright 2024, Ali Behrouzi |
//|                                       https://github.com/alibh97 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Ali Behrouzi"
#property link      "https://github.com/alibh97"
#property version   "1.00"
#property description "Indicator showing pullbacks."
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

//---plots
#property indicator_label1 "UpwardPullback"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 1
#property indicator_style1 STYLE_SOLID

#property indicator_label2 "DownwardPullback"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrYellow
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID

//--- input parameters
input int MaxPullbackAge = 100; // maximum pullback age in days

//--- indiactor buffers
double UpwardPullbackBuffer[];
double DownwardPullbackBuffer[];

//--- Global Variables for upward
bool upwardTrend = false;
int lastUpgoingValidIndex = -1;
int upwardStartIndex = -1;
double lastSupport = 0.0;
bool findPullback=false;

//--- Global Variables for downward
bool downwardTrend = false;
int lastDowngoingValidIndex = -1;
int downwardStartIndex = -1;
double lastResistance = 0.0;
bool findDownwardPullback=false;

struct Pullback
{
   int index;
   double price;
   bool touched;
};

Pullback likelyUpwardPullback;
Pullback validUpwardPullbacks[];

Pullback likelyDownwardPullback;
Pullback validDownwardPullbacks[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- indicator buffers mapping
   SetIndexBuffer(0,UpwardPullbackBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DownwardPullbackBuffer,INDICATOR_DATA);
   
   //--- set arrow codes
   PlotIndexSetInteger(0,PLOT_ARROW,242);// up for upward pullabck
   PlotIndexSetInteger(1,PLOT_ARROW,241);// down for downward pullabck
   
   //--- set empty values
   ArrayInitialize(UpwardPullbackBuffer,EMPTY_VALUE);
   ArrayInitialize(DownwardPullbackBuffer,EMPTY_VALUE);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
    // Check if enough bars are present
    if(rates_total < 3)
        return(rates_total);
   
   // *** Upward Pullback identification Loop *** 
   int start=(prev_calculated>0)? prev_calculated -1 : 2 ;
   int end = rates_total;
   
   for(int i=start; i < end ; i++)
   {
      // check if this is too old , do not process to find pullback
      datetime candleTime = time[i];
      if(time[rates_total - 1] - candleTime > MaxPullbackAge * 86400)
         continue;
         
      // if an upgoind trend has been started before 
      if(upwardTrend)
      {  
  
        // Print("in upwardTrend at:",candleTime);
         if(low[i]<low[lastUpgoingValidIndex]) // if a candle breaks down the low of last upgoing candle the we go in phase of finding pulback
         {
           // Print("in upwardTrend and low[i]<low[lastUpgoingValidIndex] at:",candleTime);
            if(high[i]>= high[lastUpgoingValidIndex])
            {  
              // Print("in upwardTrend and low[i]<low[lastUpgoingValidIndex] and high[i]>= high[lastUpgoingValidIndex] at:",candleTime);
               lastUpgoingValidIndex=i;
            }   
               
            // cancle upward trend
            upwardTrend=false;
            upwardStartIndex=-1;
            
            // store likely upward pullback
            likelyUpwardPullback.index=i;
            likelyUpwardPullback.price=low[i];
            likelyUpwardPullback.touched=false;
            
            findPullback=true; // start finding pull back
         }
         // update last upgoing candle index
         else if(high[i]>= high[lastUpgoingValidIndex])
         {
          //  Print("in upwardTrend and high[i]>= high[lastUpgoingValidIndex] at:",candleTime);
            
            lastUpgoingValidIndex=i;
         }
         
      }
      // if we are in finding pullback Phase
      else if(findPullback)
      {
       //  Print("in findPullback at:",candleTime);
         // first scenario, part 1, if we broke the last support, so the upward trend is broken and finding pullback is cancled
         if(low[i]<lastSupport)
         {
           // Print("in findPullback and low[i]<lastSupport at:",candleTime);
            if(high[i] >= high[lastUpgoingValidIndex])
            {
              // Print("in findPullback and low[i]<lastSupport and high[i] >= high[lastUpgoingValidIndex] at:",candleTime);
               if(close[i]> open[i])
               {
                 // Print("in findPullback and low[i]<lastSupport and high[i] >= high[lastUpgoingValidIndex] and i-- at:",candleTime);
                  i--;   
               }  
            }
            
            findPullback=false;
            lastUpgoingValidIndex=-1; // we no longer seek for a candle to break the high of last upgoing valid candle
               

         }
         // first scenario, part2, if we are seeing downward candles, we should keep updating pullback
         else if(low[i]<likelyUpwardPullback.price)
         {
           // Print("in findPullback and low[i]<likelyUpwardPullback.price at:",candleTime);
            likelyUpwardPullback.index=i;
            likelyUpwardPullback.price=low[i];
            
            if(high[i] >= high[lastUpgoingValidIndex])
            {
              // Print("in findPullback and low[i]<likelyUpwardPullback.price and high[i] >= high[lastUpgoingValidIndex] at:",candleTime);
               lastUpgoingValidIndex=i;
            }
            
         }
         // second way, if high be higher than high of last upgoing valid candle, then we have a valid upward pullback
         else if(high[i]> high[lastUpgoingValidIndex])
         {
          //   Print("in findPullback and high[i]> high[lastUpgoingValidIndex] at:",candleTime);
             
             if(close[i] > open[i]) // first check if it is an upgoing candle
             {
                Print("Upward Pullback has been founded at :",time[likelyUpwardPullback.index]," with pullback price:",likelyUpwardPullback.price);
                Print("lastUpgoingValidCandle at :",time[lastUpgoingValidIndex]," with price:",high[lastUpgoingValidIndex]);
                Print("Fixed at :",time[i]," with Price:",high[i]);
                PlaySound("alert.wav");
               // Print("in findPullback and high[i]> high[lastUpgoingValidIndex] and close[i] > open[i] at:",candleTime);
                lastUpgoingValidIndex=-1; // we again need to seek for a upward trend
                findPullback=false;
                // Add to array
                int size=ArraySize(validUpwardPullbacks);
                int newSize=size+1;
                ArrayResize(validUpwardPullbacks,newSize);
                validUpwardPullbacks[size] = likelyUpwardPullback;
                
                //plot pullback
                UpwardPullbackBuffer[likelyUpwardPullback.index]=likelyUpwardPullback.price;
               // Print(likelyUpwardPullback.index);

                i--;        
             }
             lastUpgoingValidIndex=i;

         }
         
      }
      // Check for at least two consecutive upgoing candles, because we are not in upward trend nor in finding pullback phase
      else if(high[i-1] >= high[i-2] && high[i] >= high[i-1])
      {
        // Print("in high[i-1] >= high[i-2] && high[i] >= high[i-1] at:",candleTime );
         if(close[i] > open[i] && close[i-1] > open[i-1]) // check if both candles are upgoing candles
         {  
           // Print("in high[i-1] >= high[i-2] && high[i] >= high[i-1] and close[i] > open[i] && close[i-1] > open[i-1] at:",candleTime );
            upwardTrend = true;  // set the trend to be upgoing
            lastUpgoingValidIndex = i; // store last upgoing valid candle index
            
            upwardStartIndex = i-1;    // store a candle before upward start candle
            
            // Calculate last support
            double low2 = low[upwardStartIndex];
            double low1 = low[upwardStartIndex -1];
            double low0 = low[upwardStartIndex -2];
            lastSupport = MathMin(MathMin(low2, low1), low0);
         }

      }

   }
   
   // *** Downward Pullback identification Loop *** 
   for(int j=start; j < end ; j++)
   {
      // check if this is too old , do not process to find pullback
      datetime candleTime = time[j];
      if(time[rates_total - 1] - candleTime > MaxPullbackAge * 86400)
         continue;
         
      // if a downgoind trend has been started before 
      if(downwardTrend)
      {  
  
        // Print("in upwardTrend at:",candleTime);
         if(high[j]>high[lastDowngoingValidIndex]) // if a candle breaks up the high of last downgoing candle the we go in phase of finding downward pulback
         {
           // Print("in upwardTrend and low[i]<low[lastUpgoingValidIndex] at:",candleTime);
            if(low[j]<= low[lastDowngoingValidIndex])
            {  
              // Print("in upwardTrend and low[i]<low[lastUpgoingValidIndex] and high[i]>= high[lastUpgoingValidIndex] at:",candleTime);
               lastDowngoingValidIndex=j;
            }   
               
            // cancle downward trend
            downwardTrend=false;
            downwardStartIndex=-1;
            
            // store likely downward pullback
            likelyDownwardPullback.index=j;
            likelyDownwardPullback.price=high[j];
            likelyDownwardPullback.touched=false;
            
            findDownwardPullback=true; // start finding downward pull back
         }
         // update last downgoing candle index
         else if(low[j]<= low[lastDowngoingValidIndex])
         {
          //  Print("in upwardTrend and high[i]>= high[lastUpgoingValidIndex] at:",candleTime);
            
            lastDowngoingValidIndex=j;
         }
         
      }
      // if we are in finding downward pullback Phase
      else if(findDownwardPullback)
      {
       //  Print("in findPullback at:",candleTime);
         // first scenario, part 1, if we broke the last resistance, so the downward trend is broken and finding downward pullback is cancled
         if(high[j]>lastResistance)
         {
           // Print("in findPullback and low[i]<lastSupport at:",candleTime);
            if(low[j] <= low[lastDowngoingValidIndex])
            {
              // Print("in findPullback and low[i]<lastSupport and high[i] >= high[lastUpgoingValidIndex] at:",candleTime);
               if(close[j]< open[j])
               {
                 // Print("in findPullback and low[i]<lastSupport and high[i] >= high[lastUpgoingValidIndex] and i-- at:",candleTime);
                  j--;   
               }  
            }
            
            findDownwardPullback=false;
            lastDowngoingValidIndex=-1; // we no longer seek for a candle to break the low of last downgoing valid candle
               

         }
         // first scenario, part2, if we are seeing upward candles, we should keep updating downward pullback
         else if(high[j]>likelyDownwardPullback.price)
         {
           // Print("in findPullback and low[i]<likelyUpwardPullback.price at:",candleTime);
            likelyDownwardPullback.index=j;
            likelyDownwardPullback.price=high[j];
            
            if(low[j] <= low[lastDowngoingValidIndex])
            {
              // Print("in findPullback and low[i]<likelyUpwardPullback.price and high[i] >= high[lastUpgoingValidIndex] at:",candleTime);
               lastDowngoingValidIndex=j;
            }
            
         }
         // second way, if low be lower than low of last downgoing valid candle, then we have a valid downward pullback
         else if(low[j]< low[lastDowngoingValidIndex])
         {
          //   Print("in findPullback and high[i]> high[lastUpgoingValidIndex] at:",candleTime);
             
             if(close[j] < open[j]) // first check if it is an downgoing candle
             {
                Print("Downward Pullback has been founded at :",time[likelyDownwardPullback.index]," with pullback price:",likelyDownwardPullback.price);
                Print("lastDowngoingValidCandle at :",time[lastDowngoingValidIndex]," with price:",low[lastDowngoingValidIndex]);
                Print("Fixed at :",time[j]," with Price:",low[j]);
                PlaySound("alert.wav");
               // Print("in findPullback and high[i]> high[lastUpgoingValidIndex] and close[i] > open[i] at:",candleTime);
                lastDowngoingValidIndex=-1; // we again need to seek for a downward trend
                findDownwardPullback=false;
                // Add to array
                int sizee=ArraySize(validDownwardPullbacks);
                int newSizee=sizee+1;
                ArrayResize(validDownwardPullbacks,newSizee);
                validDownwardPullbacks[sizee] = likelyDownwardPullback;
                
                //plot pullback
                DownwardPullbackBuffer[likelyDownwardPullback.index]=likelyDownwardPullback.price;
               // Print(likelyUpwardPullback.index);

                j--;        
             }
             lastDowngoingValidIndex=j;

         }
         
      }
      // Check for at least two consecutive downgoing candles, because we are not in downward trend nor in finding downward pullback phase
      else if(low[j-1] <= low[j-2] && low[j] <= low[j-1])
      {
        // Print("in high[i-1] >= high[i-2] && high[i] >= high[i-1] at:",candleTime );
         if(close[j] < open[j] && close[j-1] < open[j-1]) // check if both candles are downgoing candles
         {  
           // Print("in high[i-1] >= high[i-2] && high[i] >= high[i-1] and close[i] > open[i] && close[i-1] > open[i-1] at:",candleTime );
            downwardTrend = true;  // set the trend to be downgoing
            lastDowngoingValidIndex = j; // store last downgoing valid candle index
            
            downwardStartIndex = j-1;    // store a candle before downward start candle
            
            // Calculate last resistance
            double high2 = high[downwardStartIndex];
            double high1 = high[downwardStartIndex -1];
            double high0 = high[downwardStartIndex -2];
            lastResistance = MathMax(MathMax(high2, high1), high0);
         }

      }

   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
