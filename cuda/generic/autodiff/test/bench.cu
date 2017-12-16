#include <iostream>
#include <assert.h>
#include <cuda.h>
#include <vector>
#include <algorithm>
#include <benchmark/benchmark.h>

// use manuaml timing for GPU based functions
#include <chrono>
#include <ctime>

using namespace std;

/////////////////////////////////////////////////////////////////////////////////////
//                      The function to be benchmarked                            //
/////////////////////////////////////////////////////////////////////////////////////

// Some convenient functions
float floatrand() {
    return ((float)rand())/RAND_MAX-.5;    // random value between -.5 and .5
}

template < class V > void fillrandom(V& v) {
    generate(v.begin(), v.end(), floatrand);    // fills vector with random values
}

// Signature of the generic function:
extern "C" int GpuConv(float*, int, int, float*, float**);

void main_generic(int Nx) {

    int Ny= Nx /2 ;

    int dimPoint = 3;
    int dimVect = 3;

    vector<float> vf(Nx*dimPoint);
    fillrandom(vf);
    float *f = vf.data();

    vector<float> vx(Nx*dimPoint);
    fillrandom(vx);
    float *x = vx.data();
    
    vector<float> vy(Ny*dimPoint);
    fillrandom(vy);
    float *y = vy.data();
    
    vector<float> vu(Nx*dimVect);
    fillrandom(vu);
    float *u = vu.data();
    
    vector<float> vv(Ny*dimVect);
    fillrandom(vv);
    float *v = vv.data();

    // wrap variables
    vector<float*> vargs(4);
    vargs[0]=x;
    vargs[1]=y;
    vargs[2]=u;
    vargs[3]=v;
    float **args = vargs.data();

    float params[1];
    float Sigma = 1;
    params[0] = 1.0/(Sigma*Sigma);

    GpuConv(params, Nx, Ny, f, args);

}

extern "C" int GaussGpuGrad1Conv(float ooSigma2, float* alpha_h, float* x_h, float* y_h, float* beta_h, float* gamma_h, int dimPoint, int dimVect, int nx, int ny) ;

void main_specific(int Nx) {

    int Ny= Nx /2 ;

    int dimPoint = 3;
    int dimVect = 3;

    vector<float> vf(Nx*dimVect);
    fillrandom(vf);
    float *f = vf.data();

    vector<float> vx(Nx*dimPoint);
    fillrandom(vx);
    float *x = vx.data();
    
    vector<float> vy(Ny*dimPoint);
    fillrandom(vy);
    float *y = vy.data();
    
    vector<float> vu(Nx*dimVect);
    fillrandom(vu);
    float *u = vu.data();
    
    vector<float> vv(Ny*dimVect);
    fillrandom(vv);
    float *v = vv.data();
    
    float Sigma =1;
    float ooSigma2 = 1.0/(Sigma*Sigma);

    GaussGpuGrad1Conv(ooSigma2, u, x, y, v, f, 3,3,Nx,Ny);

}

/////////////////////////////////////////////////////////////////////////////////////
//                          Call the benchmark                                     //
/////////////////////////////////////////////////////////////////////////////////////


// The zeroth benchmark : simply to avoid warm up the GPU...
static void BM_dummy(benchmark::State& state) {
    for (auto _ : state)
        main_generic(1000);
}
BENCHMARK(BM_dummy);// Register the function as a benchmark


// A first Benchmark:
static void cuda_specific(benchmark::State& state) {
    int Nx = state.range(0);

    for (auto _ : state) {
        auto start = chrono::high_resolution_clock::now();
        //----------- the function to be benchmarked ------------//
        main_specific(Nx); 
        //------------------------------------------------------//
        auto end   = chrono::high_resolution_clock::now();

        auto elapsed_seconds = chrono::duration_cast<chrono::duration<double>>( end - start); 
        state.SetIterationTime(elapsed_seconds.count());
    }
}
// set range of the parameter to be tested : [ 8, 64, 512, 4k, 8k ]
BENCHMARK(cuda_specific)->Range(8, 8<<10)->UseManualTime();// Register the function as a benchmark

// A second one: 
static void cuda_generic(benchmark::State& state) {
    int Nx = state.range(0);

    for (auto _ : state) {
        auto start = chrono::high_resolution_clock::now();
        //----------- the function to be benchmarked ------------//
        main_generic(Nx);
        //------------------------------------------------------//
        auto end   = chrono::high_resolution_clock::now();

        auto elapsed_seconds = chrono::duration_cast<chrono::duration<double>>( end - start); 
        state.SetIterationTime(elapsed_seconds.count());
    }
}
// set range of the parameter to be tested : [ 8, 64, 512, 4k, 8k ]
BENCHMARK(cuda_generic)->Range(8, 8<<10)->UseManualTime();// Register the function as a benchmark


BENCHMARK_MAIN();// generate the benchmarks
