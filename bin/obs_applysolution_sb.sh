#!/bin/bash
usage()
{
echo "applysolution_sb.sh [-o obsnum] [-c calibration 1] [-v calibration 2] [-k calibration 3] [-z calibration 4] [-d dep] [-a account] [-m machine]
	-o obsnum	: the observation id
	-c calibration	: the calibration solution path (band1)
	-v calibration 	: the calibration solution path (band2)
	-k calibration	: the calibration solution path (band3)
	-z calibration	: the calibration solution path (band4)
	-d dep		: dependant job
	-a account	: account.default=mwasci
	-m machine	: the machine to run.default=garrawarla" 1>&2;
exit 1;
}

obsnum=
calibration1=
calibration2=
calibration3=
calibration4=
account="mwasci"
machine="garrawarla"
dep=

while getopts "o:d:a:m:c:v:k:z:" OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        c)
            calibration1=${OPTARG}
            ;;
	v)
	    calibration2=${OPTARG}
	    ;;
	k)
	    calibration3=${OPTARG}
	    ;;
	z)
	    calibration4=${OPTARG}
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


script="${base}queue/applysolution_sb_${obsnum}.sh"
cat ${base}bin/applysolution_sb.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/applysolution_sb_${obsnum}.o%A"
error="${base}queue/logs/applysolution_sb_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} -M ${machine} -A ${account} ${script} -a ${calibration1} -b ${calibration2} -c ${calibration3} -d ${calibration4}"
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted applysolution job as ${jobid}"





