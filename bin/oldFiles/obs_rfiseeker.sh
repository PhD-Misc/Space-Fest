#!/bin/bash

usage()
{
echo "rfiseeker.sh [-o obsnum] [-m cluster] [-a account] [-d dependancy] [-t timeSteps]
        -m cluster              : the hpc cluster to process data in, default=zeus
        -a account              : the project id, default=mwasci
        -t timeSteps		: number of timesteps in ms. default=55
        -d dependancy		: dependant job id
        -o obsnum               : the obsid" 1>&2;
exit 1;
}

obsnum=
cluster="zeus"
project="mwasci"
dep=
timeSteps=55

while getopts 'o:m:a:d:t:' OPTION
do
    case "$OPTION" in
        d)
            dep=${OPTARG}
            ;;
        o)
            obsnum=${OPTARG}
            ;;
        m)
            cluster=${OPTARG}
            ;;
        a)
            project=${OPTARG}
            ;;
        t)
            timeSteps=${OPTARG}
            ;;
        ? | : | h)
            usage
            ;;
    esac
done


# set the obsid to be the first non option
shift  "$(($OPTIND -1))"


# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi

if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi

base=/astro/mwasci/sprabu/satellites/Space-Fest/

script="${base}queue/rfiseeker_${obsnum}.sh"
cat ${base}bin/rfiseeker.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/rfiseeker_${obsnum}.o%A"
error="${base}queue/logs/rfiseeker_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} -M ${cluster} -A ${project} ${script} -s ${timeSteps}"
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted rfiseeker job as ${jobid}"


