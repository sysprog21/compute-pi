CC = gcc
CFLAGS = -O0 -std=gnu99 -Wall -fopenmp -mavx
EXECUTABLE = \
	time_test_baseline time_test_openmp_2 time_test_openmp_4 \
	time_test_avx time_test_avxunroll \
	time_test_leibniz time_test_leibniz_openmp_2 time_test_leibniz_openmp_4 \
	time_test_leibniz_avx time_test_leibniz_avxunroll \
	benchmark_clock_gettime

GIT_HOOKS := .git/hooks/pre-commit
METHOD ?= BASELINE

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

default: $(GIT_HOOKS) computepi.o
	$(CC) $(CFLAGS) computepi.o time_test.c -DBASELINE -o time_test_baseline
	$(CC) $(CFLAGS) computepi.o time_test.c -DOPENMP_2 -o time_test_openmp_2
	$(CC) $(CFLAGS) computepi.o time_test.c -DOPENMP_4 -o time_test_openmp_4
	$(CC) $(CFLAGS) computepi.o time_test.c -DAVX -o time_test_avx
	$(CC) $(CFLAGS) computepi.o time_test.c -DAVXUNROLL -o time_test_avxunroll
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ -o time_test_leibniz
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_OPENMP_2 -o time_test_leibniz_openmp_2
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_OPENMP_4 -o time_test_leibniz_openmp_4
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_AVX -o time_test_leibniz_avx
	$(CC) $(CFLAGS) computepi.o time_test.c -DLEIBNIZ_AVXUNROLL -o time_test_leibniz_avxunroll
	$(CC) $(CFLAGS) computepi.o benchmark_clock_gettime.c -D$(METHOD) -o benchmark_clock_gettime

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

gencsv: default
	for i in `seq 1000 5000 1000000`; do \
		printf "%d " $$i;\
		./benchmark_clock_gettime $$i; \
	done > result_clock_gettime.csv

plot: gencsv
	gnuplot scripts/runtime.gp

clean:
	rm -f $(EXECUTABLE) *.o *.s result_clock_gettime.csv runtime.png
