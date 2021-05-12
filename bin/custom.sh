#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=12:00:00
#SBATCH --ntasks=28
#SBATCH --mem=124GB
#SBATCH --tmp=890GB
#SBATCH --mail-type FAIL,TIME_LIMIT,TIME_LIMIT_90
#SBATCH --mail-user sirmcmissile47@gmail.com

start=`date +%s`
module load singularity
shopt -s expand_aliases
source /astro/mwasci/sprabu/aliases

b1name="068-079"
img_size=200
img_scale="5amin"

set -x
{
obsnum=OBSNUM
base=BASE
norad=NORAD


datadir=${base}processing/${obsnum}
cd ${datadir}

if [[ -d "${norad}" ]]
then
    rm -r ${norad}
fi

mkdir ${norad}

cp -r ${obsnum}${b1name}.ms /nvmetmp
cp ${obsnum}.metafits /nvmetmp

cd /nvmetmp

## make an orgininal copy of the measurement set
cp -r ${obsnum}${b1name}.ms original.ms


## run track.py
cp /home/sprabu/customPython/track.py /nvmetmp
myPython ./track.py --obs ${obsnum} --metafits ${obsnum}.metafits --noradid ${norad} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --searchRadius 18


## make images along the phase centre
tarray=
while IFS=, read -r col1 col2 col3 col4 col5 col6
do
    ah=$((col1))
    bh=$((ah+1))
    bt=$((col1))
    at=$((bt-1))
    tarray=(${tarray[@]} ${col1})
    echo ${tarray}
    echo ${tarray[@]}
    chgcentre ${obsnum}${b1name}.ms ${col2} ${col3}

    # make near-field correction
    cp /astro/mwasci/sprabu/satellites/git/LEOVision/LEOVision /nvmetmp
    PyLEO ./LEOVision --ms ${obsnum}${b1name}.ms --tle ${norad}.txt --headTime ${col5} --debug True --t ${col1}

    mkdir Head
    wsclean -name ${obsnum}${b1name}-2m-${col1}h -size ${img_size} ${img_size} -scale ${img_scale} -interval ${ah} ${bh} -channels-out 384 -weight natural -abs-mem 40 -temp-dir Head -quiet -use-wgridder ${obsnum}${b1name}.ms &

    PID1=$!

    mkdir Tail
    wsclean -name ${obsnum}${b1name}-2m-${col1}t -size ${img_size} ${img_size} -scale ${img_scale} -interval ${at} ${bt} -channels-out 384 -weight natural -abs-mem 40 -temp-dir Tail -quiet -use-wgridder ${obsnum}${b1name}.ms &

    PID2=$!



    wait ${PID1}
    wait ${PID2}

    rm -r Head
    rm -r Tail

    ## delete the ms and replace with original
    rm -r ${obsnum}${b1name}.ms
    cp -r original.ms ${obsnum}${b1name}.ms

done < ${obsnum}-${norad}.csv


## make cube
cp /home/sprabu/customPython/makeCube_v2.py /nvmetmp
myPython3 ./makeCube_v2.py --obs ${obsnum} --band ${b1name} --noradid ${norad} --channels 384 --user ${spaceTrackUser} --passwd ${spaceTrackPassword}


##  
mkdir ${datadir}/${norad}/fm
cp *.npy ${datadir}/${norad}/fm
cp *.csv ${datadir}/${norad}/fm
cp *.txt ${datadir}/${norad}/fm
cp *.png ${datadir}/${norad}/fm


}
