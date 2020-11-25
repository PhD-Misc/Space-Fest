#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=14:30:00
#SBATCH --ntasks=28
#SBATCH --mem=124GB
#SBATCH -J calibrate
#SBATCH --mail-type FAIL,TIME_LIMIT,TIME_LIMIT_90
#SBATCH --mail-user sirmcmissile47@gmail.com

module load singularity
module load python/2.7.14
module swap python/2.7.14 python/3.6.3
module load numpy/1.19.0
module load MWA_Tools/mwa-sci_test
module use /group/mwa/software/modulefiles

set -x
{
### steps to calibrate ###
# 1) wget the obs if ms not present and unzip file
# 2) aoflagger the 3 bands
# 3) if model not provided, use infield calibration for all 3 bands
# 4) plot python aocal for the solutions
# 5) apply the solution on the measurement set
# 6) create a cleaned image
# 7) do self cal
# 8) interpolate solution for flagged frequencies
# 9) plot python aocal for the interpolated solution
##########################

obsnum=OBSNUM
base=BASE
model=MODEL
link=

while getopts 'l:' OPTION
do
    case "$OPTION" in
        l)
            link=${OPTARG}
            ;;
    esac
done

echo "The download link is ${link}"

datadir=${base}calibrations

cd ${datadir}

if [[ -e "${obsnum}" ]]
then
    echo "obs exists. not downloading"
    cd ${obsnum}
else
    echo "file does not exist"
    echo "re-downloading the obs..."
    mkdir ${obsnum}

    cd ${obsnum}
    wget -O ${obsnum}_ms.zip --no-check-certificate "${link}"
    unzip -n ${obsnum}_ms.zip
fi

## aoflagger the DATA column
singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_068-083.ms
singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_107-108.ms
singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_112-114.ms
singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_147-149.ms


## calibrate using model or self cal
metafits=${obsnum}.metafits
if [ "$model" = "infield" ];then
    echo "performing infield calibration"
    RA=$( pyhead.py -p RA $metafits | awk '{print $3}' )
    Dec=$( pyhead.py -p DEC $metafits | awk '{print $3}' )
    chan=$( pyhead.py -p CENTCHAN $metafits | awk '{print $3}' )
    

    radius="--radius=30"
    catfile="${base}models/skymodel_only_alpha.fits"

    crop_catalogue.py --ra=${RA} --dec=${Dec} ${radius} --minflux=1.0 --attenuate --metafits=${obsnum}.metafits --catalogue=${catfile} --fluxcol=S_200
    cp /home/sprabu/customPython/vo2model.py .
    ./vo2model.py --catalogue=cropped_catalogue.fits --point --output=local_gleam_model.txt --racol=RAJ2000 --decol=DEJ2000 --acol=a --bcol=b --pacol=pa --fluxcol=S_200 --alphacol=alpha

    singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 -m local_gleam_model.txt ${obsnum}_068-083.ms round1_068-083.bin
    singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 -m local_gleam_model.txt ${obsnum}_107-108.ms round1_107-108.bin
    singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 -m local_gleam_model.txt ${obsnum}_112-114.ms round1_112-114.bin
    singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 -m local_gleam_model.txt ${obsnum}_147-149.ms round1_147-149.bin

else
    echo "performing calibration usin source model"
    singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 -m ../../models/model-${model}-*withalpha.txt ${obsnum}_068-083.ms round1_068-083.bin

fi


## apply solution

singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif applysolutions ${obsnum}_068-083.ms round1_068-083.bin
singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif applysolutions ${obsnum}_107-108.ms round1_107-108.bin
singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif applysolutions ${obsnum}_112-114.ms round1_112-114.bin
singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif applysolutions ${obsnum}_147-149.ms round1_147-149.bin 

## aoflagger on CORRECTED_DATA column
singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_068-083.ms

singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_107-108.ms

singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_112-114.ms

singularity exec /pawsey/mwa/singularity/cotter/cotter_4.5.sif aoflagger ${obsnum}_147-149.ms




## image for self cal
singularity exec /pawsey/mwa/singularity/wsclean/wsclean_2.9.2.img wsclean -name selfcal_068-083 -size 2800 2800 -scale 0.5amin -niter 10000 -mgain 0.8 -auto-threshold 1.5 ${obsnum}_068-083.ms

singularity exec /pawsey/mwa/singularity/wsclean/wsclean_2.9.2.img wsclean -name selfcal_107-108 -size 2800 2800 -scale 0.5amin -niter 10000 -mgain 0.8 -auto-threshold 1.5 ${obsnum}_107-108.ms

singularity exec /pawsey/mwa/singularity/wsclean/wsclean_2.9.2.img wsclean -name selfcal_112-114 -size 2800 2800 -scale 0.5amin -niter 10000 -mgain 0.8 -auto-threshold 1.5 ${obsnum}_112-114.ms

singularity exec /pawsey/mwa/singularity/wsclean/wsclean_2.9.2.img wsclean -name selfcal_147-149 -size 2800 2800 -scale 0.5amin -niter 10000 -mgain 0.8 -auto-threshold 1.5 ${obsnum}_147-149.ms




## self cal
#singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 ${obsnum}.ms selfcal.bin
singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 ${obsnum}_068-083.ms round2_068-083.bin
singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 ${obsnum}_107-108.ms round2_107-108.bin
singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 ${obsnum}_112-114.ms round2_112-114.bin
singularity exec /pawsey/mwa/singularity/mwa-reduce/mwa-reduce_2020.09.15.sif calibrate -absmem 120 -minuv 150 -ch 4 ${obsnum}_147-149.ms round2_147-149.bin




}

