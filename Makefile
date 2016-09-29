CC = gcc
CFLAGS = -O0 -std=gnu99 -Wall -fopenmp -mavx
EXECUTABLE = \
	time_test_baseline time_test_openmp_2 time_test_openmp_4 \
	time_test_avx time_test_avxunroll \
	time_test_leibniz time_test_leibniz_openmp_2 time_test_leibniz_openmp_4 \
	time_test_leibniz_avx time_test_leibniz_avxunroll \
	time_test_euler time_test_euler_openmp_2 time_test_euler_openmp_4 \
	time_test_euler_avx time_test_euler_avxunroll \
	benchmark_clock_gettime compare_error_rate

GIT_HOOKS := .git/hooks/pre-commit
METHOD ?= BASELINE

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

default: $(GIT_HOOKS) computepi.o
	$(CC) $(CFLAGS) computepi.o time_test.c -DBASELINE -o time_test_baseline -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DOPENMP_2 -o time_test_openmp_2 -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DOPENMP_4 -o time_test_openmp_4 -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DAVX -o time_test_avx -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DAVXUNROLL -o time_test_avxunroll -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ -o time_test_leibniz -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_OPENMP_2 -o time_test_leibniz_openmp_2 -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_OPENMP_4 -o time_test_leibniz_openmp_4 -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_AVX -o time_test_leibniz_avx -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_AVXUNROLL -o time_test_leibniz_avxunroll -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DEULER -o time_test_euler -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DEULER_OPENMP_2 -o time_test_euler_openmp_2 -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DEULER_OPENMP_4 -o time_test_euler_openmp_4 -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DEULER_AVX -o time_test_euler_avx -lm
	$(CC) $(CFLAGS) computepi.o time_test.c -DEULER_AVXUNROLL -o time_test_euler_avxunroll -lm
	$(CC) $(CFLAGS) computepi.o benchmark_clock_gettime.c -D$(METHOD) -o benchmark_clock_gettime -lm
	$(CC) $(CFLAGS) computepi.o methods_error_rate.c -o methods_error_rate -lm

.PHONY: clean default

%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

check: default
	time ./time_test_baseline
	time ./time_test_openmp_2
	time ./time_test_openmp_4
	time ./time_test_avx
	time ./time_test_avxunroll
	time ./time_test_leibniz
	time ./time_test_leibniz_openmp_2
	time ./time_test_leibniz_openmp_4
	time ./time_test_leibniz_avx
	time ./time_test_leibniz_avxunroll
	time ./time_test_euler
	time ./time_test_euler_openmp_2
	time ./time_test_euler_openmp_4
	time ./time_test_euler_avx
	time ./time_test_euler_avxunroll

gencsv: default
	for i in `seq 1000 5000 1000000`; do \
		printf "%d " $$i;\
		./benchmark_clock_gettime $$i; \
	done > result_clock_gettime.csv

plot: gencsv
	gnuplot scripts/runtime.gp

gencsv-methods: default
	for i in `seq 1000 5000 1000000`; do \
		printf "%d " $$i;\
		./methods_error_rate $$i; \
	done > methods_error_rate.csv

plot-methods: gencsv-methods
	gnuplot scripts/methods_error_rate.gp

clean:
	rm -f $(EXECUTABLE) *.o *.s *.png *.csv
