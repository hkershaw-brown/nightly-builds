#!/bin/bash
#PBS -A P86850054
#PBS -N lorenz_96.log
#PBS -j oe
#PBS -k eod
#PBS -q regular
#PBS -l walltime=00:10:00
#PBS -l select=2:ncpus=4:mpiprocs=4

export TMPDIR=/glade/scratch/$USER/temp
mkdir -p $TMPDIR

echo $PBS_JOBID
module list
time mpiexec_mpt ./filter

touch done


