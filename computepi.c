#include <stdio.h>
#include <immintrin.h>
#include <omp.h>
#include "computepi.h"

double compute_pi_baseline(size_t N)
{
    double pi = 0.0;
    double dt = 1.0 / N;                // dt = (b-a)/N, b = 1, a = 0
    for (size_t i = 0; i < N; i++) {
        double x = (double) i / N;      // x = ti = a+(b-a)*i/N = i/N
        pi += dt / (1.0 + x * x);       // integrate 1/(1+x^2), i = 0....N
    }
    return pi * 4.0;
}

double compute_pi_openmp(size_t N, int threads)
{
    double pi = 0.0;
    double dt = 1.0 / N;
    double x;
    #pragma omp parallel num_threads(threads)
    {
        #pragma omp for private(x) reduction(+:pi)
        for (size_t i = 0; i < N; i++) {
            x = (double) i / N;
            pi += dt / (1.0 + x * x);
        }
    }
    return pi * 4.0;
}

double compute_pi_avx(size_t N)
{
    double pi = 0.0;
    double dt = 1.0 / N;
    register __m256d ymm0, ymm1, ymm2, ymm3, ymm4;
    ymm0 = _mm256_set1_pd(1.0);
    ymm1 = _mm256_set1_pd(dt);
    ymm2 = _mm256_set_pd(dt * 3, dt * 2, dt * 1, 0.0);
    ymm4 = _mm256_setzero_pd();             // sum of pi

    for (int i = 0; i <= N - 4; i += 4) {
        ymm3 = _mm256_set1_pd(i * dt);      // i*dt, i*dt, i*dt, i*dt
        ymm3 = _mm256_add_pd(ymm3, ymm2);   // x = i*dt+3*dt, i*dt+2*dt, i*dt+dt, i*dt+0.0
        ymm3 = _mm256_mul_pd(ymm3, ymm3);   // x^2 = (i*dt+3*dt)^2, (i*dt+2*dt)^2, ...
        ymm3 = _mm256_add_pd(ymm0, ymm3);   // 1+x^2 = 1+(i*dt+3*dt)^2, 1+(i*dt+2*dt)^2, ...
        ymm3 = _mm256_div_pd(ymm1, ymm3);   // dt/(1+x^2)
        ymm4 = _mm256_add_pd(ymm4, ymm3);   // pi += dt/(1+x^2)
    }
    double tmp[4] __attribute__((aligned(32)));
    _mm256_store_pd(tmp, ymm4);             // move packed float64 values to  256-bit aligned memory location
    pi += tmp[0] + tmp[1] + tmp[2] + tmp[3];
    return pi * 4.0;
}

double compute_pi_avx_unroll(size_t N)
{
    double pi = 0.0;
    double dt = 1.0 / N;
    register __m256d ymm0, ymm1, ymm2, ymm3, ymm4,
             ymm5, ymm6, ymm7, ymm8, ymm9,
             ymm10,ymm11, ymm12, ymm13, ymm14;
    ymm0 = _mm256_set1_pd(1.0);
    ymm1 = _mm256_set1_pd(dt);
    ymm2 = _mm256_set_pd(dt * 3, dt * 2, dt * 1, 0.0);
    ymm3 = _mm256_set_pd(dt * 7, dt * 6, dt * 5, dt * 4);
    ymm4 = _mm256_set_pd(dt * 11, dt * 10, dt * 9, dt * 8);
    ymm5 = _mm256_set_pd(dt * 15, dt * 14, dt * 13, dt * 12);
    ymm6 = _mm256_setzero_pd();             // first sum of pi
    ymm7 = _mm256_setzero_pd();             // second sum of pi
    ymm8 = _mm256_setzero_pd();             // third sum of pi
    ymm9 = _mm256_setzero_pd();             // fourth sum of pi

    for (int i = 0; i <= N - 16; i += 16) {
        ymm14 = _mm256_set1_pd(i * dt);

        ymm10 = _mm256_add_pd(ymm14, ymm2);
        ymm11 = _mm256_add_pd(ymm14, ymm3);
        ymm12 = _mm256_add_pd(ymm14, ymm4);
        ymm13 = _mm256_add_pd(ymm14, ymm5);

        ymm10 = _mm256_mul_pd(ymm10, ymm10);
        ymm11 = _mm256_mul_pd(ymm11, ymm11);
        ymm12 = _mm256_mul_pd(ymm12, ymm12);
        ymm13 = _mm256_mul_pd(ymm13, ymm13);

        ymm10 = _mm256_add_pd(ymm0, ymm10);
        ymm11 = _mm256_add_pd(ymm0, ymm11);
        ymm12 = _mm256_add_pd(ymm0, ymm12);
        ymm13 = _mm256_add_pd(ymm0, ymm13);

        ymm10 = _mm256_div_pd(ymm1, ymm10);
        ymm11 = _mm256_div_pd(ymm1, ymm11);
        ymm12 = _mm256_div_pd(ymm1, ymm12);
        ymm13 = _mm256_div_pd(ymm1, ymm13);

        ymm6 = _mm256_add_pd(ymm6, ymm10);
        ymm7 = _mm256_add_pd(ymm7, ymm11);
        ymm8 = _mm256_add_pd(ymm8, ymm12);
        ymm9 = _mm256_add_pd(ymm9, ymm13);
    }

    double tmp1[4] __attribute__((aligned(32)));
    double tmp2[4] __attribute__((aligned(32)));
    double tmp3[4] __attribute__((aligned(32)));
    double tmp4[4] __attribute__((aligned(32)));

    _mm256_store_pd(tmp1, ymm6);
    _mm256_store_pd(tmp2, ymm7);
    _mm256_store_pd(tmp3, ymm8);
    _mm256_store_pd(tmp4, ymm9);

    pi += tmp1[0] + tmp1[1] + tmp1[2] + tmp1[3] +
          tmp2[0] + tmp2[1] + tmp2[2] + tmp2[3] +
          tmp3[0] + tmp3[1] + tmp3[2] + tmp3[3] +
          tmp4[0] + tmp4[1] + tmp4[2] + tmp4[3];
    return pi * 4.0;
}