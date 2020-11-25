#!/bin/bash
usage()
{
echo "applysolution.sh [-o obsnum] [-c calibration] [-d dep] [-a account] [-m machine]
	-o obsnum	: the observation id
	-c calibration	: the calibration solution
	-d dep		: dependant job
	-a account	: account.default=mwasci
	-m machine	: the machine to run.default=garrawarla" 1>&2;
exit 1;
}

obsnum=
calibration=
account="mwasci"
machine="garrawarla"
dep=

while getopts "o:c:d:a:m:" OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        c)
            calibration=${OPTARG}
            ;;
        d)
            dep=${OPTARG}		
            ;;
        a)
            account=${OPTARG}
            ;;
        m)
            machine=${OPTARG}
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

if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi


script="${base}queue/applysolution_${obsnum}.sh"
cat ${base}bin/applysolution.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/applysolution_${obsnum}.o%A"
error="${base}queue/logs/applysolution_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} -M ${machine} -A ${account} ${script} -a ${calibration}"
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted applysolution job as ${jobid}"





