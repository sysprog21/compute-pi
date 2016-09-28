reset

set logscale x 2
set xlabel 'N'
set ylabel 'Time (sec)'
set style fill solid
set key left top
set title 'Wall-clock time - using clock\_gettime()'
set term png enhanced font 'Verdana,10'
set output 'runtime.png'

plot 'result_clock_gettime.csv' using 1:2 smooth csplines lw 2 title 'Baseline', \
'' using 1:3 smooth csplines lw 2 title 'OpenMP (2 threads)', \
'' using 1:4 smooth csplines lw 2 title 'OpenMP (4 threads)', \
'' using 1:5 smooth csplines lw 2 title 'AVX', \
'' using 1:6 smooth csplines lw 2 title 'AVX + unroll looping'
