#!/bin/bash
#PBS -A P86850054
#PBS -N lorenz_96.log
#PBS -j oe
#PBS -k eod
#PBS -q regular
#PBS -l walltime=00:10:00
### Request 10 CPUS for 10 threads
#PBS -l select=1:ncpus=1:ompthreads=1

export TMPDIR=/glade/scratch/$USER/temp
mkdir -p $TMPDIR

echo $PBS_JOBID
time mpiexec_mpt ./filter

touch done


