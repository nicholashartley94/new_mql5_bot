//+------------------------------------------------------------------+
//|                                                 kohonen maps.mqh |
//|                                    Copyright 2022, Fxalgebra.com |
//|                        https://www.mql5.com/en/users/omegajoctan |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Fxalgebra.com"
#property link      "https://www.mql5.com/en/users/omegajoctan"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <MALE5\matrix_utils.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

class CKohonenMaps
  {
   protected:
     CMatrixutils matrix_utils; 
     
      uint    n; //number of features
      uint    m; //number of clusters
      ulong   rows;

      double  Euclidean_distance(const vector &v1, const vector &v2);
      string  CalcTimeElapsed(double seconds);
      
   private:
      matrix     Matrix;
      matrix     c_matrix; //Clusters
      matrix     w_matrix; //Weights matrix
      vector     w_vector; //weights vector
      matrix     o_matrix; //Output layer matrix
   
   public:
                  CKohonenMaps(matrix &matrix_,uint random_state=42, uint clusters=2, double alpha=0.01, uint epochs=100);
                 ~CKohonenMaps(void);
                 
                  uint KOMPredCluster(vector &v);
                  vector KOMPredCluster(matrix &matrix_);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CKohonenMaps::CKohonenMaps(matrix &matrix_,uint random_state=42, uint clusters=2, double alpha=0.01, uint epochs=100)
 {
   Matrix = matrix_;
   
   n = (uint)matrix_.Cols();
   rows = matrix_.Rows();
   m = clusters;
   
   w_vector = matrix_utils.Random(0.0, 1.0, int(n*m), random_state);
   
   w_matrix = matrix_utils.VectorToMatrix(w_vector,n);
   
   //Print("w Matrix\n",w_matrix);
   
   vector D(m); //Euclidean distance btn clusters
   
   
   double epoch_start = GetMicrosecondCount()/(double)1e6, epoch_stop=0; 
   
   for (uint iteration=0; iteration<epochs; iteration++)
    {
      for (ulong i=0; i<n; i++)
       {
         for (ulong j=0; j<m; j++)
           {
             D[j] = Euclidean_distance(Matrix.Col(i),w_matrix.Row(j));
           }
         
         #ifdef DEBUG_MODE  
            Print("Euc distance ",D," Winning cluster ",D.ArgMin());
         #endif 
         
   //--- weights update
         
         ulong min = D.ArgMin();
         
         vector w_new =  w_matrix.Row(min) + (alpha * (Matrix.Col(min) - w_matrix.Row(min)));
         
         w_matrix.Row(w_new, min);
         
         //Print("New w_Matrix\n ",w_matrix);
       }
       
    }  //end of training
  
  epoch_stop =GetMicrosecondCount()/(double)1e6;
  
  #ifdef DEBUG_MODE
      printf("Finished Training | %sElapsed ", CalcTimeElapsed(epoch_stop-epoch_start));
      Print("weights\n",w_matrix);
  #endif 
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CKohonenMaps::~CKohonenMaps(void)
 {
   ZeroMemory(Matrix);
   ZeroMemory(c_matrix); 
   ZeroMemory(w_matrix); 
   ZeroMemory(w_vector); 
   ZeroMemory(o_matrix); 
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

double CKohonenMaps:: Euclidean_distance(const vector &v1, const vector &v2)
  {
   double dist = 0;

   if(v1.Size() != v2.Size())
      Print(__FUNCTION__, " v1 and v2 not matching in size");
   else
     {
      double c = 0;
      for(ulong i=0; i<v1.Size(); i++)
         c += MathPow(v1[i] - v2[i], 2);

      dist = MathSqrt(c);
     }

   return(dist);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint CKohonenMaps::KOMPredCluster(vector &v)
 {
   vector D(m); //Euclidean distance btn clusters
   
   for (ulong j=0; j<m; j++)
       D[j] = Euclidean_distance(v, w_matrix.Row(j));
          
    return((uint)D.ArgMin());
 }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

vector CKohonenMaps::KOMPredCluster(matrix &matrix_)
 {   
   vector v(n);
   
   for (ulong i=0; i<n; i++)
      v[i] = KOMPredCluster(Matrix.Col(i));
      
    return(v);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

string CKohonenMaps::CalcTimeElapsed(double seconds)
 {
  string time_str = "";
  
  uint minutes=0, hours=0;
  
   if (seconds >= 60)
     time_str = StringFormat("%d Minutes and %.3f Seconds ",minutes=(int)round(seconds/60.0), ((int)seconds % 60));     
   if (minutes >= 60)
     time_str = StringFormat("%d Hours %d Minutes and %.3f Seconds ",hours=(int)round(minutes/60.0), minutes, ((int)seconds % 60));
   else
     time_str = StringFormat("%.3f Seconds ",seconds);
     
   return time_str;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+