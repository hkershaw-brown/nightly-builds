#!/bin/bash -l 

cd /glade/u/home/hkershaw/test_cron

SCRIPT_DIR=$(pwd)
BUILD_DIR=/glade/scratch/hkershaw/nightly_builds
MODEL=lorenz_96
MAILTO="hkershaw+${MODEL}@ucar.edu"
REFERENCE="/glade/work/hkershaw/DART_bitwise/DART_v10.7.3/models/lorenz_96/work"
TIMING_FILE=${SCRIPT_DIR}/"timing.csv"
LOG_FILE=""

cd $BUILD_DIR
[[ -d $MODEL ]] && rm -rf $MODEL

checkout () {
git clone https://github.com/NCAR/DART.git $MODEL
}

compile () { 
cp ${SCRIPT_DIR}/mkmf.template $MODEL/build_templates && \
cd $MODEL/models/$MODEL/work && \
./quickbuild.sh 
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

log_result() {

find  ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/ -name lorenz_96.log* -exec cp {} ${SCRIPT_DIR}/log.txt \;
cd ${SCRIPT_DIR}
head -n 1 log.txt | cut -d . -f 1 | tr -d '\n' >> $TIMING_FILE
tail log.txt | grep -A3 real | awk '{ printf " , %s ", $2 } END { print " " }' >> $TIMING_FILE
}

mail_fail_log() {

find  ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/ -name lorenz_96.log* -exec cp {} ${SCRIPT_DIR}/log.txt \;
cp ${BUILD_DIR}/${MODEL}/models/${MODEL}/work/${LOG_FILE} ${SCRIPT_DIR}/


cd ${SCRIPT_DIR}
cat <<EOF> mail.txt

$MODEL not bitwise
$(date)

EOF


head $LOG_FILE >> mail.txt

mail -s "${1} failed" -a log.txt $MAILTO < mail.txt

}

check_bitwise() {

now=$(date +"%m-%d-%YT%H:%M:%S")
LOG_FILE="bitwise_log_${now}.txt"
netcdf=("preassim.nc" "analysis.nc" "filter_output.nc")
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
if [[ $? -ne 0 ]]
then 
  mail_fail_log
else
# log the results
  log_result
fi


