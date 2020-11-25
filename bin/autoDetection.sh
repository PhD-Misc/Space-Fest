#!/bin/bash

usage()
{
echo "autoDetection.sh [-o obsnum] [-d download link] [-c calibration] [-a account] [-m machine] [-n norad] [-b blind detection?] [-t timeSteps] [-p skip phasetrack]
	-o obsnum	: the observation id
	-d download link: the wget link
	-c calibration	: the calibration solution path 
	-a account	: the pawsey account to use.default=mwasci
	-m machine	: the cluster to run in. default=garrawarla
	-b blindDetection: run blind detection?Default=false
	-t timeSteps	: the number of timeSteps. default=56
	-p skip phasetrack: skip phase track?? default=False
	-n norad	: the norad id" 1>&2;
exit 1; 
}

obsnum=
link=
calibration=
account="mwasci"
cluster="garrawarla"
norad=
blindDetection=
timeSteps=56
skipPhaseTrack=

while getopts 'o:d:c:a:m:n:b:t:p:' OPTION
do
	case "$OPTION" in
	    o)
		obsnum=${OPTARG}
                ;;
	    d)
		link=${OPTARG}
		;;
	    c)
		calibration=${OPTARG}
		;;
	    a)
		account=${OPTARG}
		;;
	    m)
		cluster=${OPTARG}
		;;
	    n)
		norad=${OPTARG}
		;;
	    b)
		blindDetection=1
		;;
	    t)
		timeSteps=${OPTARG}
		;;
	    p)
		skipPhaseTrack=1
		;;
	    ? | : | h)
		usage
		;;
	esac
done

## echo outputs
echo "obsnum ${obsnum}"
echo "download link ${link}"
echo "calibration solution ${calibration}"
echo "norad ${norad}"



# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi

base=/astro/mwasci/sprabu/satellites/Space-Fest/


### submit the download job
script="${base}queue/asvo_${obsnum}.sh"
cat ${base}bin/asvo.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/asvo_${obsnum}.o%A"
error="${base}queue/logs/asvo_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} -M ${cluster} ${script} -l ${link} "
jobid0=($(${sub}))
jobid0=${jobid0[3]}
# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid0}/"`
output=`echo ${output} | sed "s/%A/${jobid0}/"`

echo "Submitted asvo job as ${jobid0}"


### submit the cotter job
script="${base}queue/cotter_${obsnum}.sh"
cat ${base}/bin/cotter.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/cotter_${obsnum}.o%A"
error="${base}queue/logs/cotter_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} --dependency=afterok:${jobid0} -A ${account} -M ${cluster} ${script}"
jobid1=($(${sub}))
jobid1=${jobid1[3]}
# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid1}/"`
output=`echo ${output} | sed "s/%A/${jobid1}/"`

echo "Submitted cotter job as ${jobid1}"



## applysolutions
script="${base}queue/applysolution_${obsnum}.sh"
cat ${base}/bin/applysolution.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/applysolution_${obsnum}.o%A"
error="${base}queue/logs/applysolution_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} --dependency=afterok:${jobid1} -A ${account} -M ${cluster} ${script} -a ${calibration}"
jobid2=($(${sub}))
jobid2=${jobid2[3]}
# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid2}/"`
output=`echo ${output} | sed "s/%A/${jobid2}/"`

echo "Submitted applysolution job as ${jobid2}"

if [[ -z ${skipPhaseTrack} ]]
then
    ## phasetrack
    script="${base}queue/phaseTrack_${obsnum}.sh"
    cat ${base}/bin/phaseTrack.sh | sed -e "s:OBSNUM:${obsnum}:g" \
				-e "s:NORAD:${norad}:g" \
                                 -e "s:BASE:${base}:g" > ${script}
    output="${base}queue/logs/phaseTrack_${obsnum}.o%A"
    error="${base}queue/logs/phaseTrack_${obsnum}.e%A"
    sub="sbatch --begin=now+15 --output=${output} --error=${error} --dependency=afterok:${jobid2} -M ${cluster} -A ${account} ${script}"
    jobid3=($(${sub}))
    jobid3=${jobid3[3]}

    # rename the err/output files as we now know the jobid
    error=`echo ${error} | sed "s/%A/${jobid3}/"`
    output=`echo ${output} | sed "s/%A/${jobid3}/"`

    echo "Submitted phaseTrack job as ${jobid3}"
fi



## run blind detection and rfiseeker
if [[ ! -z ${blindDetection} ]]
then
    script="${base}queue/lrimage_${obsnum}.sh"
    cat ${base}/bin/lrimage.sh | sed -e "s:OBSNUM:${obsnum}:g" \
    				-e "s:BASE:${base}:g" > ${script}
    output="${base}queue/logs/lrimage_${obsnum}.o%A"
    error="${base}queue/logs/lrimage_${obsnum}.e%A"
    sub="sbatch --begin=now+15 --output=${output} --error=${error} --dependency=afterok:${jobid2} -M ${cluster} -A ${account} ${script} -t ${timeSteps}"
    jobid4=($(${sub}))
    jobid4=${jobid4[3]}
    # rename the err/output files as we now know the jobid
    error=`echo ${error} | sed "s/%A/${jobid4}/"`
    output=`echo ${output} | sed "s/%A/${jobid4}/"`

    echo "Submitted lrimage job as ${jobid4}"
 
    ### run rfiseeker as a dependant job
    script="${base}queue/rfiseeker_${obsnum}.sh" 
    cat ${base}/bin/rfiseeker.sh | sed -e "s:OBSNUM:${obsnum}:g" \
				-e "s:BASE:${base}:g" > ${script}
    output="${base}queue/logs/rfiseeker_${obsnum}.o%A"
    error="${base}queue/logs/rfiseeker_${obsnum}.e%A"
    sub="sbatch --begin=now+15 --output=${output} --error=${error} --dependency=afterok:${jobid4} -M ${cluster} -A ${account} ${script} -s ${timeSteps}"
    jobid5=($(${sub}))
    jobid5=${jobid4[3]}
    # rename the err/output files as we now know the jobid
    error=`echo ${error} | sed "s/%A/${jobid5}/"`
    output=`echo ${output} | sed "s/%A/${jobid5}/"`

    echo "Submitted rfiseeker job as ${jobid5}"

fi







