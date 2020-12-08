#!/bin/bash

usage()
{
echo "mantra.sh [-o obsnum] [-a account] [-c cluster]
	-o obsnum	: the observation id
	-a account	: account.defaut=mwasci
	-c cluster	: the cluster to run in.default=garrawarla" 1>&2;
exit 1;
}

obsnum=
account="mwasci"
cluster="garrawarla"

while getopts "o:a:c:" OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        a)
            account=${OPTARG}
            ;;
        c)
            cluster=${OPTARG}
            ;;
        ? | : | h)
            usage
            ;;
    esac
done


base=/astro/mwasci/sprabu/satellites/Space-Fest/

# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi


### submit the download job
script="${base}queue/mantra_${obsnum}.sh"
cat ${base}bin/mantra.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/mantra_${obsnum}.o%A"
error="${base}queue/logs/mantra_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} -M ${cluster} ${script} "
jobid0=($(${sub}))
jobid0=${jobid0[3]}
# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid0}/"`
output=`echo ${output} | sed "s/%A/${jobid0}/"`

echo "Submitted mantra job as ${jobid0}"



