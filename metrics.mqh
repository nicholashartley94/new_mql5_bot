//+------------------------------------------------------------------+
//|                                                      metrics.mqh |
//|                                    Copyright 2022, Fxalgebra.com |
//|                        https://www.mql5.com/en/users/omegajoctan |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Fxalgebra.com"
#property link      "https://www.mql5.com/en/users/omegajoctan"
//+------------------------------------------------------------------+
//| defines                                                          |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#include <MALE5\MatrixExtend.mqh>

struct roc_curve_struct
 {
   vector TPR,
          FPR, 
          Thresholds;
 };

struct confusion_matrix_struct
 { 
   matrix MATRIX;
   vector CLASSES;
   vector TP, 
          TN, 
          FP, 
          FN;
 };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Metrics
  {
protected:
   static int SearchPatterns(vector &True, int value_A, vector &B, int value_B);

   static confusion_matrix_struct confusion_matrix(vector &True, vector &Preds);
   
public:

   Metrics(void);
   ~Metrics(void);

   //--- Regression metrics

   static double r_squared(vector &True, vector &Pred);
   static double adjusted_r(vector &True, vector &Pred, uint indep_vars = 1);

   static double rss(vector &True, vector &Pred);
   static double mse(vector &True, vector &Pred);
   static double rmse(vector &True, vector &Pred);
   static double mae(vector &True, vector &Pred);

   //--- Classification metrics

   static double accuracy_score(vector &True, vector &Pred);
   
   static vector accuracy(vector &True, vector &Preds);
   static vector precision(vector &True, vector &Preds);
   static vector recall(vector &True, vector &Preds);
   static vector f1_score(vector &True, vector &Preds);
   static vector specificity(vector &True, vector &Preds);
   
   static roc_curve_struct roc_curve(vector &True, vector &Preds);
   static void classification_report(vector &True, vector &Pred, bool report_show = true);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Metrics::Metrics(void)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Metrics::~Metrics(void)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Metrics::r_squared(vector &True, vector &Pred)
  {
   return(Pred.RegressionMetric(True, REGRESSION_R2));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Metrics::adjusted_r(vector &True, vector &Pred, uint indep_vars = 1)
  {
   if(True.Size() != Pred.Size())
     {
      Print(__FUNCTION__, " Vector True and P are not equal in size ");
      return(0);
     }

   double r2 = r_squared(True, Pred);
   ulong N = Pred.Size();

   return(1 - ((1 - r2) * (N - 1)) / (N - indep_vars - 1));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
confusion_matrix_struct Metrics::confusion_matrix(vector &True, vector &Preds)
 {
  confusion_matrix_struct confusion_matrix; 
   
  vector classes = MatrixExtend::Unique(True);
  confusion_matrix.CLASSES = classes;
  
//--- Fill the confusion matrix
   
   matrix MATRIX(classes.Size(), classes.Size());
   MATRIX.Fill(0.0);
   
   for(ulong i = 0; i < classes.Size(); i++)
      for(ulong j = 0; j < classes.Size(); j++)
         MATRIX[i][j] = SearchPatterns(True, (int)classes[i], Preds, (int)classes[j]);
   
   confusion_matrix.MATRIX = MATRIX;
   confusion_matrix.TP = MATRIX.Diag();
   confusion_matrix.FP = MATRIX.Sum(0) - confusion_matrix.TP;
   confusion_matrix.FN = MATRIX.Sum(1) - confusion_matrix.TP;
   confusion_matrix.TN = MATRIX.Sum() - (confusion_matrix.TP + confusion_matrix.FP + confusion_matrix.FN);
     
   return confusion_matrix;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector Metrics::accuracy(vector &True,vector &Preds)
 {
  confusion_matrix_struct conf_m = confusion_matrix(True, Preds);
  
  return (conf_m.TP + conf_m.TN) / conf_m.MATRIX.Sum();
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector Metrics::precision(vector &True,vector &Preds)
 {
   confusion_matrix_struct conf_m = confusion_matrix(True, Preds);

   return conf_m.TP / (conf_m.TP + conf_m.FP + DBL_EPSILON); 
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector Metrics::f1_score(vector &True,vector &Preds)
 {
   vector precision = precision(True, Preds);
   vector recall = recall(True, Preds);
   
   return 2 * precision * recall / (precision + recall + DBL_EPSILON); 
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector Metrics::recall(vector &True,vector &Preds)
 {
   confusion_matrix_struct conf_m = confusion_matrix(True, Preds);

   return conf_m.TP / (conf_m.TP + conf_m.FN + DBL_EPSILON); 
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector Metrics::specificity(vector &True,vector &Preds)
 {
   confusion_matrix_struct conf_m = confusion_matrix(True, Preds);

   return conf_m.TN / (conf_m.TN + conf_m.FP + DBL_EPSILON); 
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
roc_curve_struct Metrics::roc_curve(vector &True,vector &Preds)
 {
   roc_curve_struct roc;
   confusion_matrix_struct conf_m = confusion_matrix(True, Preds);
   
   roc.TPR = recall(True, Preds);
   roc.FPR = conf_m.FP / (conf_m.FP + conf_m.TN + DBL_EPSILON);
   
   return roc;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Metrics::accuracy_score(vector &True, vector &Preds)
  {
   confusion_matrix_struct conf_m = confusion_matrix(True, Preds);
   
   return conf_m.MATRIX.Diag().Sum() / (conf_m.MATRIX.Sum() + DBL_EPSILON);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Metrics::classification_report(vector &True, vector &Pred, bool report_show = true)
  {
  
  vector accuracy = accuracy(True, Pred);
  vector precision = precision(True, Pred);
  vector specificity = specificity(True, Pred);
  vector recall = recall(True, Pred);
  vector f1_score = f1_score(True, Pred); 
  
  
  confusion_matrix_struct conf_m = confusion_matrix(True, Pred);
  
//--- support
   
   ulong size = conf_m.MATRIX.Rows();
   
   vector support(size);
   
   for(ulong i = 0; i < size; i++)
      support[i] = NormalizeDouble(MathIsValidNumber(conf_m.MATRIX.Row(i).Sum()) ? conf_m.MATRIX.Row(i).Sum() : 0, 8);

   int total_size = (int)conf_m.MATRIX.Sum();

//--- Avg and w avg
   
   vector avg, w_avg;
   avg.Resize(5);
   w_avg.Resize(5);

   avg[0] = precision.Mean();

   avg[1] = recall.Mean();
   avg[2] = specificity.Mean();
   avg[3] = f1_score.Mean();

   avg[4] = total_size;

//--- w avg

   vector support_prop = support / double(total_size + 1e-10);

   vector c = precision * support_prop;
   w_avg[0] = c.Sum();

   c = recall * support_prop;
   w_avg[1] = c.Sum();

   c = specificity * support_prop;
   w_avg[2] = c.Sum();

   c = f1_score * support_prop;
   w_avg[3] = c.Sum();

   w_avg[4] = (int)total_size;

//--- Report

   if(report_show)
     {
      string report = "\n[CLS][ACC] \t\t\t\t\tPrecision \tRecall \tSpecificity \tF1 score \tSupport";

      for(ulong i = 0; i < size; i++)
        {
         report += "\n\t[" + string(conf_m.CLASSES[i])+"]["+DoubleToString(accuracy[i], 2)+"]";
         //for (ulong j=0; j<3; j++)

         report += StringFormat("\t\t\t\t\t %.2f \t\t\t %.2f \t\t\t %.2f \t\t\t\t\t %.2f \t\t\t %.1f", precision[i], recall[i], specificity[i], f1_score[i], support[i]);
        }
      
      report += "\n";
      
      report += StringFormat("\nAverage \t\t\t\t\t\t \t %.2f \t\t\t %.2f \t\t\t %.2f \t\t\t\t %.2f \t\t\t %.1f", avg[0], avg[1], avg[2], avg[3], avg[4]);
      report += StringFormat("\nW Avg   \t\t\t\t\t\t \t %.2f \t\t\t %.2f \t\t\t %.2f \t\t\t\t %.2f \t\t\t %.1f", w_avg[0], w_avg[1], w_avg[2], w_avg[3], w_avg[4]);

      Print("Confusion Matrix\n", conf_m.MATRIX);
      Print("\nClassification Report\n", report);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Metrics::rss(vector &True, vector &Pred)
  {
   vector c = True - Pred;
   c = MathPow(c, 2);

   return (c.Sum());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Metrics::mse(vector &True, vector &Pred)
  {
   vector c = True - Pred;
   c = MathPow(c, 2);

   return(c.Sum() / c.Size());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Metrics::SearchPatterns(vector &True, int value_A, vector &B, int value_B)
  {
   int count=0;
   
   for(ulong i = 0; i < True.Size(); i++)
      if(True[i] == value_A && B[i] == value_B)
         count++;

   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Metrics::rmse(vector &True, vector &Pred)
  {
   return Pred.RegressionMetric(True, REGRESSION_RMSE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Metrics::mae(vector &True, vector &Pred)
  {
   return Pred.RegressionMetric(True, REGRESSION_MAE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

