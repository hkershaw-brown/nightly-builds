#!/bin/bash -l 

SCRIPT_DIR=$(pwd)
BUILD_DIR=/glade/scratch/hkershaw/nightly_builds
MODEL=lorenz_96
MAILTO="hkershaw+${MODEL}@ucar.edu"

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

now=$(date +"%m_%d_%Y")
cp "${BUILD_DIR}/${MODEL}/models/${MODEL}/lorenz_96.log*" log.txt
cat <<EOF> mail.txt

$MODEL test failed in $1
$(date)"

EOF

mail -s "${1} failed" $MAILTO -A log.txt < mail.txt
}

checkout
[[ $? -ne 0 ]] && mail_fail checkout && exit 1

compile
[[ $? -ne 0 ]] && mail_fail compile && exit 2

submit $?
[[ $? -ne 0 ]] && mail_fail submit && exit 3


