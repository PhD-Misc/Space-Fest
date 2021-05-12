#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=24:00:00
#SBATCH --ntasks=148
#SBATCH --mem=360GB
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

while getopts 's:' OPTION
do
    case "$OPTION" in
        s)
            timeSteps=${OPTARG}
            ;;
    esac
done

datadir=${base}processing/${obsnum}
cd ${datadir}

## step1) make fine channel images for FM band ###


for g in `seq 0 ${timeSteps}`;
do
    i=$((g*1))
    j=$((i+1))
    for f in `seq 0 511`;
    do
        f1=$((f*1))
        f2=$((f+1))
        while [[ $(jobs | wc -l) -ge 28 ]]
        do
            wait -n $(jobs -p)
        done
        mkdir temp_${g}_${f1}
        name=`printf %04d $f`
        wsclean -quiet \
                    -name ${obsnum}-fm-${i}-${name} -size 1400 1400 -temp-dir temp_${g}_${f1} \
                    -abs-mem 5 -interval ${i} ${j} -channel-range ${f1} ${f2}\
                    -weight natural -scale 2.5amin -maxuvw-m 800 -use-wgridder ${obsnum}068-083.ms &
        
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

## step2) make fine channel images in orbcom band

for g in `seq 0 ${timeSteps}`;
do
    i=$((g*1))
    j=$((i+1))
    for f in `seq 0 63`;
    do
        f1=$((f*1))
        f2=$((f+1))
        while [[ $(jobs | wc -l) -ge 28 ]]
        do
            wait -n $(jobs -p)
        done
        mkdir temp_${g}_${f1}
        name=`printf %04d $f`
        singularity exec  /pawsey/mwa/singularity/wsclean/wsclean_2.9.2.img wsclean -quiet \
                    -name ${obsnum}-orb-${i}-${name} -size 1400 1400 -temp-dir temp_${g}_${f1} \
                    -abs-mem 5 -interval ${i} ${j} -channel-range ${f1} ${f2}\
                    -weight natural -scale 2.5amin -maxuvw-m 800 -use-wgridder ${obsnum}107-108.ms &
        
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

## step3) make fine channel images in 2m band (dl-donwn link)

for g in `seq 0 ${timeSteps}`;
do
    i=$((g*1))
    j=$((i+1))
    for f in `seq 0 95`;
    do
        f1=$((f*1))
        f2=$((f+1))
        while [[ $(jobs | wc -l) -ge 28 ]]
        do
            wait -n $(jobs -p)
        done
        mkdir temp_${g}_${f1}
        name=`printf %04d $f`
        singularity exec  /pawsey/mwa/singularity/wsclean/wsclean_2.9.2.img wsclean -quiet \
                    -name ${obsnum}-dl-${i}-${name} -size 1400 1400 -temp-dir temp_${g}_${f1} \
                    -abs-mem 5 -interval ${i} ${j} -channel-range ${f1} ${f2}\
                    -weight natural -scale 2.5amin -maxuvw-m 800 -use-wgridder ${obsnum}112-114.ms &

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


### step4) make images for the dtv band

for g in `seq 0 ${timeSteps}`;
do
    i=$((g*1))
    j=$((i+1))

    singularity exec  /pawsey/mwa/singularity/wsclean/wsclean_2.9.2.img wsclean -quiet \
              -name ${obsnum}-dtv-${i} -size 1400 1400 \
               -interval ${i} ${j} -channels-out 3 -weight natural -maxuvw-m 800 -scale 2.5amin -use-wgridder ${obsnum}147-149.ms
done

end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}
