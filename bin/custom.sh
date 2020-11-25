#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=8:00:00
#SBATCH --ntasks=2
#SBATCH --mem=10GB
#SBATCH -J timeLapse
#SBATCH --mail-type FAIL,TIME_LIMIT,TIME_LIMIT_90
#SBATCH --mail-user sirmcmissile47@gmail.com

start=`date +%s`
#source /group/mwa/software/module-reset.sh
module load singularity
module load python/3.6.3

set -x

{

obsnum=OBSNUM
base=BASE
timeSteps=151

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


timeLapse.py --obs ${obsnum} --t1 1 --t2 151 --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --prefix fm4Sigma1Floodfill --debug True


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}

