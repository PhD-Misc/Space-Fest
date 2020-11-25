#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=2:00:00
#SBATCH --ntasks=12
#SBATCH --mem=20GB
#SBATCH -J applySol
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
band1Path=

while getopts 'a:' OPTION
do
    case "$OPTION" in
        a)
            band1Path=${OPTARG}
            ;;
    esac
done


datadir=${base}processing/${obsnum}


cd ${datadir}

applysolutions ${obsnum}.ms ${band1Path}

end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}

