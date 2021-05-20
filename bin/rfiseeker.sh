#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=24:00:00
#SBATCH --ntasks=28
#SBATCH --mem=124GB
#SBATCH -J rfiseeker
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
timeSteps=55

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


### image in FM band ###
cp /home/sprabu/RFISeeker/RFISeeker .
for q in $(seq ${timeSteps})
do
  while [[ $(jobs | wc -l) -ge 28 ]]
  do
    wait -n $(jobs -p)
  done
  python_rfi ./RFISeeker --obs ${obsnum} --freqChannels 768 --seedSigma 6 --floodfillSigma 3 --timeStep ${q} --prefix 6Sigma3Floodfill --DSNRS=False --imgSize 1400 &

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



end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}

