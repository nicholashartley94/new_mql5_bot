//+------------------------------------------------------------------+
//|                                                          svm.mqh |
//|                                    Copyright 2022, Fxalgebra.com |
//|                        https://www.mql5.com/en/users/omegajoctan |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Omega Joctan"
#property link      "https://www.mql5.com/en/users/omegajoctan"

#include <MALE5\preprocessing.mqh>
#include <MALE5\matrix_utils.mqh>
#include <MALE5\metrics.mqh>
#include <MALE5\kernels.mqh>

//+------------------------------------------------------------------+
//|  At its core, SVM aims to find a hyperplane that best separates  |
//|  two classes of data points in a high-dimensional space.         |
//|  This hyperplane is chosen to maximize the margin between the    |
//|  two classes, making it the optimal decision boundary.           |
//+------------------------------------------------------------------+

#define RANDOM_STATE 42

#define UNDEFINED_REPLACE 1


class CLinearSVM
  {
   protected:
   
      CMatrixutils      matrix_utils;
      CMetrics          metrics;
      
      CPreprocessing<vector, matrix, double> *normalize_x;
      
      vector            W;
      double            B; 
      
      bool is_fitted_already;
      bool during_training;
      
      struct svm_config 
        {
          uint batch_size;
          double alpha;
          double lambda;
          uint epochs;
        };

   private:
      svm_config config;
   
   protected:
        
      
                        double hyperplane(vector &x);
                        
                        int sign(double var);
                        vector sign(const vector &vec);
                        matrix sign(const matrix &mat);
                        
   public:
                        CLinearSVM(uint batch_size=32, double alpha=0.001, uint epochs= 1000,double lambda=0.1);
                       ~CLinearSVM(void);
                        
                        void fit(matrix &x, vector &y);
                        int predict(vector &x);
                        vector predict(matrix &x);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

CLinearSVM::CLinearSVM(uint batch_size=32, double alpha=0.001, uint epochs= 1000,double lambda=0.1)
 {   
    is_fitted_already = false;
    during_training = false;
    
    config.batch_size = batch_size;
    config.alpha = alpha;
    config.lambda = lambda;
    config.epochs = epochs;
 }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

CLinearSVM::~CLinearSVM(void)
 {
   delete (normalize_x);
 }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CLinearSVM::hyperplane(vector &x)
 {
   return x.MatMul(W) - B;   
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CLinearSVM::predict(vector &x)
 { 
   if (!is_fitted_already)
     {
       Print("Err | The model is not trained, call the fit method to train the model before you can use it");
       return 1000;
     }
   
   vector temp_x = x;
   if (!during_training)
     normalize_x.Normalization(temp_x); //Normalize a new input data when we are not running the model in training 
     
   return sign(hyperplane(temp_x));
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector CLinearSVM::predict(matrix &x)
 {
   vector v(x.Rows());
   
   for (ulong i=0; i<x.Rows(); i++)
     v[i] = predict(x.Row(i));
     
   return v;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CLinearSVM::fit(matrix &x, vector &y)
 {
   matrix X = x;
   vector Y = y;
  
   ulong rows = X.Rows(),
         cols = X.Cols();
   
   if (X.Rows() != Y.Size())
      {
         Print("Support vector machine Failed | FATAL | X m_rows not same as yvector size");
         return;
      }
   
   W.Resize(cols);
   B = 0;
    
   normalize_x = new CPreprocessing<vector, matrix, double>(X, NORM_STANDARDIZATION, false); //Normalizing independent variables
     
//---

  if (rows < config.batch_size)
    {
      Print("The number of samples/rows in the dataset should be less than the batch size");
      return;
    }
   
    matrix temp_x;
    vector temp_y;
    matrix w, b;
    
    vector preds = {};
    vector loss(config.epochs);
    during_training = true;

    for (uint epoch=0; epoch<config.epochs; epoch++)
      {
        
         for (uint batch=0; batch<=(uint)MathFloor(rows/config.batch_size); batch+=config.batch_size)
           {              
              temp_x = matrix_utils.Get(X, batch, (config.batch_size+batch)-1);
              temp_y = matrix_utils.Get(Y, batch, (config.batch_size+batch)-1);
              
              #ifdef DEBUG_MODE:
                  Print("X\n",temp_x,"\ny\n",temp_y);
              #endif 
              
               for (uint sample=0; sample<temp_x.Rows(); sample++)
                  {                                        
                     // yixiw-b≥1
                     
                      if (temp_y[sample] * hyperplane(temp_x.Row(sample))  >= 1) 
                        {
                          this.W -= config.alpha * (2 * config.lambda * this.W); // w = w + α* (2λw - yixi)
                        }
                      else
                         {
                           this.W -= config.alpha * (2 * config.lambda * this.W - ( temp_x.Row(sample) * temp_y[sample] )); // w = w + α* (2λw - yixi)
                           
                           this.B -= config.alpha * temp_y[sample]; // b = b - α* (yi)
                         }  
                  }
           }
        
        //--- Print the loss at the end of an epoch
       
         is_fitted_already = true;  
         
         preds = this.predict(X);
         
         loss[epoch] = preds.Loss(Y, LOSS_BCE);
        
         printf("---> epoch [%d/%d] Loss = %f Accuracy = %f",epoch+1,config.epochs,loss[epoch],metrics.confusion_matrix(Y, preds, false));
         
        #ifdef DEBUG_MODE:  
          Print("W\n",W," B = ",B);  
        #endif   
      }
    
    during_training = false;
    
    return;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CLinearSVM::sign(double var)
 {
   //Print("Sign input var = ",var);
   
   if (var == 0)
    return (0);
   else if (var < 0)
    return -1;
   else 
    return 1; 
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector CLinearSVM::sign(const vector &vec)
 {
   vector ret = vec;
   
   for (ulong i=0; i<vec.Size(); i++)
     ret[i] = sign((int)vec[i]);
   
   return ret;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
matrix CLinearSVM::sign(const matrix &mat)
 { 
   matrix ret = mat;
   
   for (ulong i=0; i<mat.Rows(); i++)
     for (ulong j=0; j<mat.Cols(); j++)
        ret[i][j] = sign((int)mat[i][j]); 
        
   return ret;
 }
 
//+------------------------------------------------------------------+
//|                                                                  |
//|                                                                  |
//|             SVM DUAL | for non linear problems                   |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

class CDualSVM: protected CLinearSVM
  {
private:
   
   __kernels__       *kernel;
   
   struct dual_svm_config: svm_config //Inherit configs from Linear SVM
    {  
       kernels kernel;
       uint degree;
       double sigma;
       double beta;
    };
   
   dual_svm_config config;
   
   matrix X;
   vector Y;
   
   vector y_labels;
   vector model_alpha;
   
   int decision_function(vector &x);

   matrix VectorToMatrix(vector &v)
    {
      matrix ret_m;
      vector temp_v = v;
      
      temp_v.Swap(ret_m);
      
      return ret_m;
    }
      
    double MatrixToDBL(matrix &mat)
    {   
      if (mat.Rows()>1 || mat.Cols()>1)
       {
         Print(__FUNCTION__," Can't convert matrix to double as this is not a 1x1 matrix");
         return 0;
       }
      return mat[0][0];
    }
          
public:
                     CDualSVM(kernels KERNEL, double alpha, double beta, uint degree, double sigma, uint batch_size=32, uint epochs= 1000);
                    ~CDualSVM(void);
                    
                    void fit(matrix &x, vector &y);
                    vector predict(matrix &x);
                    int predict(vector &x);

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDualSVM::CDualSVM(kernels KERNEL,
                   double alpha, 
                   double beta, 
                   uint  degree, 
                   double sigma,
                   uint batch_size=32, 
                   uint epochs= 1000
                   )
 {
    kernel = new __kernels__(KERNEL, alpha, beta, degree, sigma);
   
    config.kernel = KERNEL;
    config.alpha = alpha; 
    config.beta = beta;
    config.degree = degree; 
    config.sigma = sigma;
    config.batch_size = batch_size;
    config.epochs = epochs;
    
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDualSVM::~CDualSVM(void)
 {
   delete (kernel);
   delete (normalize_x);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDualSVM::decision_function(vector &x)
 { 
   vector tempx =x;
   matrix x_;
   tempx.Swap(x_);
   
   //Print("x\n",this.X," x_ ",x_);
   
   matrix kernel_res = this.kernel.KernelFunction(this.X, x_);
   
   //printf("alpha (%dx%d) y_label (%dx%d) kernel_res =(%dx%d)",VectorToMatrix(model_alpha).Rows(),VectorToMatrix(model_alpha).Cols(), VectorToMatrix(y_labels).Rows(), VectorToMatrix(y_labels).Cols(),kernel_res.Rows(),kernel_res.Cols());
   
   return sign(MatrixToDBL(VectorToMatrix(model_alpha * this.Y).MatMul(kernel_res)));
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int CDualSVM::predict(vector &x)
 { 
   if (!is_fitted_already)
     {
       Print("Err | The model is not trained, call the fit method to train the model before you can use it");
       return 1000;
     }
   
   if (x.Size() <=0)
     {
       Print(__FUNCTION__," Err invalid x size ");
       return 1e3;
     }
   return decision_function(x);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vector CDualSVM::predict(matrix &x)
 {
   vector v(x.Rows());
   
   for (ulong i=0; i<x.Rows(); i++)
     v[i] = predict(x.Row(i));
     
   return v;
 }
//+------------------------------------------------------------4------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDualSVM::fit(matrix &x,vector &y)
 {
   X = x;
   Y = y;
   

   y_labels = this.matrix_utils.Classes(Y);
   
   
   ulong rows = X.Rows(), 
         cols = X.Cols();
         
   model_alpha = matrix_utils.Zeros(rows);
   
   
   if (X.Rows() != Y.Size())
      {
         Print("Support vector machine Failed | FATAL | X m_rows not same as yvector size");
         return;
      }
   
   W.Resize(cols);
   B = 0;
   
   normalize_x = new CPreprocessing<vector, matrix, double>(X, NORM_STANDARDIZATION, false);
     
//---

  
  if (rows < config.batch_size)
    {
      Print("The number of samples/rows in the dataset should be less than the batch size");
      return;
    }
   
    matrix temp_x;
    vector temp_y;
    matrix w, b;
    
    vector preds = {};
    vector loss(config.epochs);
    vector ones(rows);
    ones.Fill(1); 
    
    for (uint epoch=0; epoch<config.epochs; epoch++)
      {
        vector gradient = {};
        
         for (uint batch=0; batch<=(uint)MathFloor(rows/config.batch_size); batch+=config.batch_size)
           {
            /*
              temp_x = matrix_utils.Get(X, batch, (config.batch_size+batch)-1);
              temp_y = matrix_utils.Get(Y, batch, (config.batch_size+batch)-1);
              
              #ifdef DEBUG_MODE:
                  Print("X\n",temp_x,"\ny\n",temp_y);
              #endif 
              
              for (uint sample=0; sample<temp_x.Rows(); sample++)
              */
                {
                   //printf("outer alpha =(%dx%d) y_outer =(%dx%d)",model_alpha.Outer(model_alpha).Rows(),model_alpha.Outer(model_alpha).Cols(),Y.Outer(Y).Rows(),Y.Outer(Y).Cols());
                   
                   gradient = ones - (model_alpha.Outer(model_alpha) * Y.Outer(Y) * this.kernel.KernelFunction(X, X)).Sum();
                          
                   model_alpha += config.alpha * gradient;
                   model_alpha.Clip(0, INT_MAX);
               }
           }
           
        //--- Print the loss at the end of an epoch
       
         is_fitted_already = true;  
         
         //preds = this.predict(X);
         
         loss[epoch] = preds.Loss(this.Y, LOSS_BCE);
        
         printf("---> epoch [%d/%d] Loss = %f ",epoch+1,config.epochs,loss[epoch]);
         
        #ifdef DEBUG_MODE:  
          Print("W\n",W," B = ",B);  
        #endif   
        
      }
    
   Print("Optimal Lagrange Multipliers (alpha):", model_alpha);
      
    return;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

class CDualSVMONNX
  {
private:
      CPreprocessing<vectorf, matrixf, float> *normalize_x;
      CMatrixutils matrix_utils;
      
      struct data_struct
       {
         ulong rows,
               cols;
       } df;
      
      
      void PrintTypeInfo(const long num,const string layer,const OnnxTypeInfo& type_info);
      
public:  
                     CDualSVMONNX(void);
                    ~CDualSVMONNX(void);
      
                     long onnx_handle;              
                     
                     void SendDataToONNX(matrixf &data, string csv_name = "DualSVMONNX-data.csv", bool common_dir=false, string csv_header="", bool save_params=true);
                     bool LoadONNX(const uchar &onnx_buff[], ENUM_ONNX_FLAGS flags=ONNX_NO_CONVERSION);
                     vectorf Predict(vectorf &inputs);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDualSVMONNX::CDualSVMONNX(void)
 {
   
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDualSVMONNX::SendDataToONNX(matrixf &data, string csv_name = "DualSVMONNX-data.csv", bool common_dir=false, string csv_header="", bool save_params=true)
 {
    df.cols = data.Cols();
    df.rows = data.Rows();
    
    if (df.cols == 0 || df.rows == 0)
      {
         Print(__FUNCTION__," data matrix invalid size ");
         return;
      }
    
    matrixf split_x;
    vectorf  split_y;
    
    matrix_utils.XandYSplitMatrices(data, split_x, split_y);
    
    normalize_x = new CPreprocessing<vectorf,matrixf,float>(split_x, NORM_MIN_MAX_SCALER, save_params);
    
    
    matrixf new_data = split_x;
    new_data.Resize(data.Rows(), data.Cols());
    new_data.Col(split_y, data.Cols()-1);
    
    if (csv_header == "")
      {
         for (ulong i=0; i<df.cols; i++)
           csv_header += "COLUMN "+string(i) + (i==df.cols-1 ? "" : ","); //do not put delimiter on the last column
      }
    
    matrix_utils.WriteCsv(csv_name, new_data, csv_header, common_dir, 8);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDualSVMONNX::LoadONNX(const uchar &onnx_buff[], ENUM_ONNX_FLAGS flags=ONNX_NO_CONVERSION)
 {
   onnx_handle =  OnnxCreateFromBuffer(onnx_buff, flags); //creating onnx handle buffer 
   
   if (onnx_handle == INVALID_HANDLE)
    {
       Print(__FUNCTION__," OnnxCreateFromBuffer Error = ",GetLastError());
       return false;
    }
   
//---
   
   const long inputs[] = {1,4};
   
   if (!OnnxSetInputShape(onnx_handle, 0, inputs)) //Giving the Onnx handle the input shape
     {
       Print(__FUNCTION__," Failed to set the input shape Err=",GetLastError());
       return false;
     }
   
   long outputs_0[] = {1};
   if (!OnnxSetOutputShape(onnx_handle, 0, outputs_0)) //giving the onnx handle the output shape
     {
       Print(__FUNCTION__," Failed to set the output shape Err=",GetLastError());
       return false;
     }
     
   long outputs_1[] = {1,2};
   if (!OnnxSetOutputShape(onnx_handle, 1, outputs_1)) //giving the onnx handle the output shape
     {
       Print(__FUNCTION__," Failed to set the output shape Err=",GetLastError());
       return false;
     }

   return true;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDualSVMONNX::~CDualSVMONNX(void)
 {
   delete (normalize_x);
   
   if (onnx_handle != 0)
      OnnxRelease(onnx_handle);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
vectorf CDualSVMONNX::Predict(vectorf &inputs)
 {
    vectorf outputs(1);
    vectorf x_output(2);
    
    //vectorf temp_inputs = inputs;
    
    //normalize_x.Normalization(temp_inputs); //Normalize the input features
    
    
    if (!OnnxRun(onnx_handle, ONNX_DEFAULT, inputs, outputs, x_output))
      {
         Print("Failed to get predictions from onnx Err=",GetLastError());
         return outputs;
      }
      
   return outputs;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void CDualSVMONNX::PrintTypeInfo(const long num,const string layer,const OnnxTypeInfo& type_info)
  {
   Print("   type ",EnumToString(type_info.type));
   Print("   data type ",EnumToString(type_info.type));

   if(type_info.tensor.dimensions.Size()>0)
     {
      bool   dim_defined=(type_info.tensor.dimensions[0]>0);
      string dimensions=IntegerToString(type_info.tensor.dimensions[0]);
      
      
      for(long n=1; n<type_info.tensor.dimensions.Size(); n++)
        {
         if(type_info.tensor.dimensions[n]<=0)
            dim_defined=false;
         dimensions+=", ";
         dimensions+=IntegerToString(type_info.tensor.dimensions[n]);
        }
      Print("   shape [",dimensions,"]");
      //--- not all dimensions defined
      if(!dim_defined)
         PrintFormat("   %I64d %s shape must be defined explicitly before model inference",num,layer);
      //--- reduce shape
      uint reduced=0;
      long dims[];
      for(long n=0; n<type_info.tensor.dimensions.Size(); n++)
        {
         long dimension=type_info.tensor.dimensions[n];
         //--- replace undefined dimension
         if(dimension<=0)
            dimension=UNDEFINED_REPLACE;
         //--- 1 can be reduced
         if(dimension>1)
           {
            ArrayResize(dims,reduced+1);
            dims[reduced++]=dimension;
           }
        }
      //--- all dimensions assumed 1
      if(reduced==0)
        {
         ArrayResize(dims,1);
         dims[reduced++]=1;
        }
      //--- shape was reduced
      if(reduced<type_info.tensor.dimensions.Size())
        {
         dimensions=IntegerToString(dims[0]);
         for(long n=1; n<dims.Size(); n++)
           {
            dimensions+=", ";
            dimensions+=IntegerToString(dims[n]);
           }
         string sentence="";
         if(!dim_defined)
            sentence=" if undefined dimension set to "+(string)UNDEFINED_REPLACE;
         PrintFormat("   shape of %s data can be reduced to [%s]%s",layer,dimensions,sentence);
        }
     }
   else
      PrintFormat("no dimensions defined for %I64d %s",num,layer);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

