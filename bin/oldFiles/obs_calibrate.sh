#!/bin/bash

usage()
{
echo "obs_calibrate.sh [-o obsnum] [-a account] [-c calibrator] [-m machine] [-u wget link]
        -a account              : pawsey Account to use,default=mwasci
        -c calibrator           : the calibrator source
        -m machine              : the cluster to process data in, default=zeus
        -u ugetlink		: the wget link for obs
        -o obsnum               : the obsid" 1>&2;
exit 1;
}

account="mwasci"
model=
cluster="zeus"
obsnum=
link=

while getopts 'o:a:c:m:u:' OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        a)
            account=${OPTARG}
            ;;
        c)
            model=${OPTARG}
            ;;
        m)
            cluster=${OPTARG}
            ;;
        u)
            link=${OPTARG}
            ;;
        ? | : | h)
            usage
            ;;
    esac
done

# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi

base=/astro/mwasci/sprabu/satellites/Space-Fest/

script="${base}queue/calibrate_${obsnum}.sh"
cat ${base}/bin/calibrate.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:MODEL:${model}:g" \
                                 -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/calibrate_${obsnum}.o%A"
error="${base}queue/logs/calibrate_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} -M ${cluster} -A ${account} ${script} -l ${link} "
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted calibrate job as ${jobid}"









