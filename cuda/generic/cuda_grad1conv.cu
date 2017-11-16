// nvcc -std=c++11 -Xcompiler -fPIC -shared -o cuda_grad1conv.so cuda_grad1conv.cu

#include "GpuConv2D.cu"

#define CALL_SCALARRADIALKER(TYPE,DIMPOINT,DIMVECT) \
	if(dimPoint==DIMPOINT && dimVect==DIMVECT) \
	{ \
		typedef ScalarRadialKernel<TYPE,DIMPOINT,DIMVECT,RadialFun> Ker; \
		struct Ker::sGrad1 funeval; \
		return GpuConv2D(Ker(RadialFun(Sigma)),funeval, nx, ny, gamma_h, alpha_h, x_h, y_h, beta_h); \
	}

// here we give the list of possible values for DIMVECT
#define CALL_SCALARRADIALKER_DIMVECT(TYPE,DIMPOINT) \
	CALL_SCALARRADIALKER(TYPE,DIMPOINT,1) \
	CALL_SCALARRADIALKER(TYPE,DIMPOINT,2) \
	CALL_SCALARRADIALKER(TYPE,DIMPOINT,3)
	
// here we give the list of possible values for DIMPOINT
#define CALL_SCALARRADIALKER_DIMPOINT_DIMVECT(TYPE) \
	CALL_SCALARRADIALKER_DIMVECT(TYPE,1) \
	CALL_SCALARRADIALKER_DIMVECT(TYPE,2) \
	CALL_SCALARRADIALKER_DIMVECT(TYPE,3)

#define DECLARE_EXTERNC_SCALARRADIAL_Gauss(TYPE) \
extern "C" int GaussGpuGrad1Conv(TYPE ooSigma2, TYPE* alpha_h, TYPE* x_h, TYPE* y_h, TYPE* beta_h, TYPE* gamma_h, int dimPoint, int dimVect, int nx, int ny) \
{ \
	TYPE Sigma = sqrt(1/ooSigma2); \
	typedef GaussFunction<TYPE> RadialFun; \
	CALL_SCALARRADIALKER_DIMPOINT_DIMVECT(TYPE) \
	cout << "These dimensions are not implemented, but you just need to copy-paste one line and recompile." << endl; \
	return -1; \
}

#define DECLARE_EXTERNC_SCALARRADIAL_Cauchy(TYPE) \
extern "C" int CauchyGpuGrad1Conv(TYPE ooSigma2, TYPE* alpha_h, TYPE* x_h, TYPE* y_h, TYPE* beta_h, TYPE* gamma_h, int dimPoint, int dimVect, int nx, int ny) \
{ \
	TYPE Sigma = sqrt(1/ooSigma2); \
	typedef CauchyFunction<TYPE> RadialFun; \
	CALL_SCALARRADIALKER_DIMPOINT_DIMVECT(TYPE) \
	cout << "These dimensions are not implemented, but you just need to copy-paste one line and recompile." << endl; \
	return -1; \
}

#define DECLARE_EXTERNC_SCALARRADIAL_Laplace(TYPE) \
extern "C" int LaplaceGpuGrad1Conv(TYPE ooSigma2, TYPE* alpha_h, TYPE* x_h, TYPE* y_h, TYPE* beta_h, TYPE* gamma_h, int dimPoint, int dimVect, int nx, int ny) \
{ \
	TYPE Sigma = sqrt(1/ooSigma2); \
	typedef LaplaceFunction<TYPE> RadialFun; \
	CALL_SCALARRADIALKER_DIMPOINT_DIMVECT(TYPE) \
	cout << "These dimensions are not implemented, but you just need to copy-paste one line and recompile." << endl; \
	return -1; \
}

#define DECLARE_EXTERNC_SCALARRADIAL_Energy(TYPE) \
extern "C" int EnergyGpuGrad1Conv(TYPE ooSigma2, TYPE* alpha_h, TYPE* x_h, TYPE* y_h, TYPE* beta_h, TYPE* gamma_h, int dimPoint, int dimVect, int nx, int ny) \
{ \
	TYPE Sigma = sqrt(1/ooSigma2); \
	typedef EnergyFunction<TYPE> RadialFun; \
	CALL_SCALARRADIALKER_DIMPOINT_DIMVECT(TYPE) \
	cout << "These dimensions are not implemented, but you just need to copy-paste one line and recompile." << endl; \
	return -1; \
}

#define DECLARE_EXTERNC_SCALARRADIAL_Sum4Gauss(TYPE) \
extern "C" int Sum4GaussGpuGrad1Conv(TYPE ooSigma2, TYPE* alpha_h, TYPE* x_h, TYPE* y_h, TYPE* beta_h, TYPE* gamma_h, int dimPoint, int dimVect, int nx, int ny) \
{ \
	TYPE Sigma = sqrt(1/ooSigma2); \
	typedef Sum4GaussFunction<TYPE> RadialFun; \
	CALL_SCALARRADIALKER_DIMPOINT_DIMVECT(TYPE) \
	cout << "These dimensions are not implemented, but you just need to copy-paste one line and recompile." << endl; \
	return -1; \
}

#define DECLARE_EXTERNC_SCALARRADIAL_Sum4Cauchy(TYPE) \
extern "C" int Sum4CauchyGpuGrad1Conv(TYPE ooSigma2, TYPE* alpha_h, TYPE* x_h, TYPE* y_h, TYPE* beta_h, TYPE* gamma_h, int dimPoint, int dimVect, int nx, int ny) \
{ \
	TYPE Sigma = sqrt(1/ooSigma2); \
	typedef Sum4CauchyFunction<TYPE> RadialFun; \
	CALL_SCALARRADIALKER_DIMPOINT_DIMVECT(TYPE) \
	cout << "These dimensions are not implemented, but you just need to copy-paste one line and recompile." << endl; \
	return -1; \
}



#if (UseCudaOnDoubles) 
	DECLARE_EXTERNC_SCALARRADIAL_Gauss(double)
	DECLARE_EXTERNC_SCALARRADIAL_Cauchy(double)
	DECLARE_EXTERNC_SCALARRADIAL_Laplace(double)
	DECLARE_EXTERNC_SCALARRADIAL_Energy(double)
	DECLARE_EXTERNC_SCALARRADIAL_Sum4Gauss(double)
	DECLARE_EXTERNC_SCALARRADIAL_Sum4Cauchy(double)
#else
	DECLARE_EXTERNC_SCALARRADIAL_Gauss(float)
	DECLARE_EXTERNC_SCALARRADIAL_Cauchy(float)
	DECLARE_EXTERNC_SCALARRADIAL_Laplace(float)
	DECLARE_EXTERNC_SCALARRADIAL_Energy(float)
	DECLARE_EXTERNC_SCALARRADIAL_Sum4Gauss(float)
	DECLARE_EXTERNC_SCALARRADIAL_Sum4Cauchy(float)
#endif