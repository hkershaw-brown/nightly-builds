#!/bin/bash -l 

SCRIPT_DIR=$(pwd)
BUILD_DIR=/glade/scratch/hkershaw/nightly_builds
MODEL=lorenz_96
MAILTO="hkershaw+${MODEL}@ucar.edu"
cd $BUILD_DIR

checkout () {
i
git clone https://github.com/NCAR/DART.git $MODEL
}

compile () { 
cp ${SCRIPT_DIR}/mkmf.template $MODEL/build_templates && \
cd $MODEL/models/$MODEL/work && \
./quikbuild.csh
}

submit () {
cp "${SCRIPT_DIR}/batch_${MODEL}.sh" . && \
qsub batch_"$MODEL".sh
}

mail_fail() {

cat <<EOF> mail.txt

$MODEL test failed in $1
$(date)"

EOF

mail -s "${1} failed" $MAILTO  < mail.txt
}

checkout
[[ $? -ne 0 ]] ; mail_fail checkout

compile
[[ $? -ne 0 ]] ; mail_fail compile

submit $?
[[ $? -ne 0 ]] ; mail_fail submit


