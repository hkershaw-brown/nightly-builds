#!/bin/bash -l 


BUILD_DIR=/glade/scratch/hkershaw/nightly_builds
MODEL=lorenz_96
MAILTO="hkershaw+${MODEL}@ucar.edu"
cd $BUILD_DIR

checkout () {
git clone https://github.com/NCAR/DART.git $MODEL
}

compile () { 
cp mkmf.template DART/build_templates && \
cd $MODEL/models/$MODEL/work && \
./quikbuild.csh
}

submit () {
qsub batch.sh
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

# Submit batch job
#cd /glade/u/home/hkershaw/test_cron
#qsub batch.sh  

