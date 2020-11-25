#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=24:00:00
#SBATCH --ntasks=28
#SBATCH --mem=124GB
#SBATCH -J lrimage
#SBATCH --mail-type FAIL,TIME_LIMIT,TIME_LIMIT_90
#SBATCH --mail-user sirmcmissile47@gmail.com


start=`date +%s`

module load singularity
shopt -s expand_aliases
source /astro/mwasci/sprabu/aliases

set -x
{

obsnum=OBSNUM
base=BASE
timeSteps=
channels=768

while getopts 't:' OPTION
do
    case "$OPTION" in
	t)
	    timeSteps=${OPTARG}
	    ;;
    esac
done

datadir=${base}processing/${obsnum}
cd ${datadir}

for g in `seq 0 ${timeSteps}`;
do
	i=$((g*1))
	j=$((i+1))
	for f in `seq 0 ${channels}`;
	do
		f1=$((f*1))
		f2=$((f1+1))

		while [[ $(jobs | wc -l) -ge 20 ]]
		do
		    wait -n $(jobs -p)
		done
		
		mkdir temp_${g}_${f1}
		name=`printf %04d $f`
		wsclean -quiet -name ${obsnum}-2m-${i}-${name} -size 1400 1400 -temp-dir temp_${g}_${f} \
		-abs-mem 5 -interval ${i} ${j} -channel-range ${f1} ${f2} -weight natural -scale 2.5amin\
		-maxuvw-m 1212 -use-wgridder ${obsnum}.ms &


	done
done

i=0
for job in `jobs -p`
do
        pids[${i}]=${job}
        i=$((i+1))
done
for pid in ${pids[*]}; do
        wait ${pid}
done

for ((k=0 ; k<10; k++))
do
        rm *${k}-image.fits
done

rm -r temp*
rm *.zip


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"

}






