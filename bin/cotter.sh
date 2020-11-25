#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=5:00:00
#SBATCH --ntasks=28
#SBATCH --mem=124GB
#SBATCH -J cotter
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

datadir=${base}processing/${obsnum}


cd ${datadir}


cotter -norfi -initflag 2 -timeres 2 -freqres 40 *gpubox* -allowmissing -flagdcchannels \
             -absmem 120 -edgewidth 80 -m ${obsnum}.metafits -o ${obsnum}.ms

end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}

