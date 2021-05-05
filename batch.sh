#!/bin/bash
#PBS -A P86850054
#PBS -N cron-test
#PBS -j oe
#PBS -k eod
#PBS -m abe
#PBS -M hkershaw+cron@ucar.edu
#PBS -q regular
#PBS -l walltime=00:10:00
### Request 10 CPUS for 10 threads
#PBS -l select=1:ncpus=1:ompthreads=1

export TMPDIR=/glade/scratch/$USER/temp
mkdir -p $TMPDIR

echo "Hello world"  "$(date)"
