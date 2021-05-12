#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=12:00:00
#SBATCH --ntasks=6
#SBATCH --mem=8GB
#SBATCH -J mantra
#SBATCH --mail-type FAIL,TIME_LIMIT,TIME_LIMIT_90
#SBATCH --mail-user sirmcmissile47@gmail.com

module load singularity
shopt -s expand_aliases
source /astro/mwasci/sprabu/aliases


set -x

{

obsnum=OBSNUM
base=BASE


datadir=${base}processing


cd ${datadir}
rm -r ${obsnum}
mkdir -p ${obsnum}
cd  ${obsnum}

csvfile="${obsnum}_dl.csv"
echo "obs_id=${obsnum}, job_type=c, timeres=2, freqres=40, edgewidth=80, conversion=ms, allowmissing=true, flagdcchannels=true, norfi=true" > ${csvfile}
outfile="${obsnum}_ms.zip"
mwa_client --csv=${csvfile} --dir=${base}processing/${obsnum}

unzip -n ${outfile}
rm ${outfile}

## rename the measurement sets
#mv ${obsnum}_068-079.ms ${obsnum}068-079.ms
#mv ${obsnum}_112-114.ms ${obsnum}112-114.ms
#mv ${obsnum}_107-108.ms ${obsnum}107-108.ms
#mv ${obsnum}_147-153.ms ${obsnum}147-153.ms


}
