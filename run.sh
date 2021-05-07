#!/bin/bash -l 

SCRIPT_DIR=$(pwd)
BUILD_DIR=/glade/scratch/hkershaw/nightly_builds
MODEL=lorenz_96
MAILTO="hkershaw+${MODEL}@ucar.edu"
REFERENCE="/glade/work/hkershaw/DART_bitwise/DART_v9.10.3/models/lorenz_96/work"

cd $BUILD_DIR
[[ -d $MODEL ]] && rm -rf $MODEL

checkout () {
git clone https://github.com/NCAR/DART.git $MODEL
}

compile () { 
cp ${SCRIPT_DIR}/mkmf.template $MODEL/build_templates && \
cd $MODEL/models/$MODEL/work && \
./quickbuild.csh -mpi
}

submit () {
cp "${SCRIPT_DIR}/batch_${MODEL}.sh" . && \
qsub batch_"$MODEL".sh
}

mail_fail() {

cat <<EOF> mail.txt

$MODEL test failed in $1
$(date)

EOF

mail -s "${1} failed" $MAILTO < mail.txt
}

mail_fail_log() {

find  ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/ -name lorenz_96.log* -exec cp {} ${SCRIPT_DIR}/log.txt \;
cp ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/${LOG_FILE} ${SCRIPT_DIR}/
cat <<EOF> mail.txt

$MODEL not bitwise $1
$(date)

EOF 

mail -s "${1} failed" -a $LOG_FILE -a log.txt $MAILTO < mail.txt
}

log_result() {
echo "Hello doing nothing at the mo"
}

check_bitwise() {

now=$(date +"%m-%d-%YT%H:%M:%S")
LOG_FILE="bitwise_log_${now}.txt"
netcdf=("forecast.nc" "preassim.nc" "postassim.nc" "analysis.nc" "filter_output.nc")
status=0

echo "bitwise netcdf" > $LOG_FILE

for file in ${netcdf[@]}; do
  echo -n "$file  ::  " >> $LOG_FILE
  nccmp -d ${REFERENCE}/$file ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/$file 2>> $LOG_FILE
  [[ $? -ne 0 ]] && status=1 
done

echo "bitwise obs_seq.final" >> $LOG_FILE
diff ${REFERENCE}/obs_seq.final ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/obs_seq.final >> $LOG_FILE
[[ $? -ne 0 ]] && status=1 
 
return $status 
}

#---------------------------------------------

checkout
[[ $? -ne 0 ]] && mail_fail checkout && exit 1

compile
[[ $? -ne 0 ]] && mail_fail compile && exit 2

submit
[[ $? -ne 0 ]] && mail_fail submit && exit 3

# wait until job has created a log file
until [ -f ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/done ]
do 
 sleep 2m
done

# bitwise check
check_bitwise
[[ $? -ne 0 ]] && mail_fail_log bitwise

# log the results
log_result
