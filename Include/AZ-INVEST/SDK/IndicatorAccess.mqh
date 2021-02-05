class CIndicatorAccess
{
   private:
   
   public:

   void CIndicatorAccess();   
   void ~CIndicatorAccess();
      
   int Lowest(double &seriesArray[], int count=WHOLE_ARRAY, int start=0);
   int Highest(double &seriesArray[], int count=WHOLE_ARRAY, int start=0);
   
};

void CIndicatorAccess::CIndicatorAccess(void)
{
}

void CIndicatorAccess::~CIndicatorAccess(void)
{
}

int CIndicatorAccess::Lowest(double &seriesArray[], int count=WHOLE_ARRAY, int start=0)
{
   return ArrayMinimum(seriesArray, start, MathMin(count, ArraySize(seriesArray)));
}

int CIndicatorAccess::Highest(double &seriesArray[], int count=WHOLE_ARRAY, int start=0)
{
   return ArrayMaximum(seriesArray, start, MathMin(count, ArraySize(seriesArray)));
}