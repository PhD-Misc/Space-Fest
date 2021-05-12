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
b2name="107-108"
b3name="112-114"
b4name="147-153"
img_size=200
img_scale="5amin"
set -x
{

obsnum=OBSNUM
base=BASE
norad=NORAD


datadir=${base}processing/${obsnum}
cd ${datadir}

#if [[ -d "${norad}" ]]
#then
#    rm -r ${norad}
#fi

#mkdir ${norad}


### fm band ###
cp -r ${obsnum}${b1name}.ms /nvmetmp
cp ${obsnum}.metafits /nvmetmp

cd /nvmetmp

### run track.py
cp /home/sprabu/customPython/track.py /nvmetmp
myPython ./track.py --obs ${obsnum} --metafits ${datadir}/${obsnum}.metafits --noradid ${norad} --user ${spaceTrackUser} --passwd ${spaceTrackPassword}

### make images along phase
tarray=
while IFS=, read -r col1 col2 col3 col4 col5
do
    ah=$((col1))
    bh=$((ah+1))
    bt=$((col1))
    at=$((bt-1))
    tarray=(${tarray[@]} ${col1})
    echo ${tarray}
    echo ${tarray[@]}
    chgcentre ${obsnum}${b1name}.ms ${col2} ${col3}

    mkdir Head
    wsclean -name ${obsnum}${b1name}-2m-${col1}h -size ${img_size} ${img_size} -scale ${img_scale} -interval ${ah} ${bh} -channels-out 384 -weight natural -abs-mem 40 -temp-dir Head -quiet -use-wgridder -maxuvw-m ${col4} ${obsnum}${b1name}.ms &

    PID1=$!

    mkdir Tail
    wsclean -name ${obsnum}${b1name}-2m-${col1}t -size ${img_size} ${img_size} -scale ${img_scale} -interval ${at} ${bt} -channels-out 384 -weight natural -abs-mem 40 -temp-dir Tail -quiet -use-wgridder -maxuvw-m ${col4} ${obsnum}${b1name}.ms & 

    PID2=$!



    wait ${PID1}    
    wait ${PID2}
    
    rm -r Head
    rm -r Tail
   
done < ${obsnum}-${norad}.csv

## run rfiseeker
#cp /home/sprabu/RFISeeker/RFISeekerSpaceFest /nvmetmp
#while IFS=, read -r col1 col2 col3 col4
#do
#    while [[ $(jobs | wc -l) -ge 28 ]]
#    do
#        wait -n $(jobs -p)
#    done
#for col1 in "${tarray[@]}"
#do
#    while [[ $(jobs | wc -l) -ge 28 ]]
#    do
#        wait -n $(jobs -p)
#    done
#
#    python_rfi ./RFISeekerSpaceFest --obs ${obsnum}${b1name} --freqChannels 384 --seedSigma 6 --floodfillSigma 1 --prefix 6Sigma1Floodfill --DSNRS=False --imgSize ${img_size} --timeStep ${col1} &
#
#done  
#done < ${obsnum}-${norad}.csv

#i=0
#for job in `jobs -p`
#do
#    pids[${i}]=${job}
#    i=$((i+1))
#done
#for pid in ${pids[*]}; do
#    wait ${pid}
#done

## run timeLapse.py
## get min max timestep values
#max=${tarray[0]}
#min=${tarray[0]}
#
#for i in "${tarray[@]}"; do
#  (( i > max )) && max=$i
#  (( i < min )) && min=$i
#done
#cp /home/sprabu/customPython/TrackTimeLapse.py /nvmetmp
#myPython ./TrackTimeLapse.py --obs ${obsnum} --noradid ${norad} --t1 ${min} --t2 ${max} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --prefix 6Sigma1Floodfill 

### make cube
cp /home/sprabu/customPython/makeCube_v2.py /nvmetmp 
myPython3 ./makeCube_v2.py --obs ${obsnum} --band ${b1name} --noradid ${norad} --channels 384 --user ${spaceTrackUser} --passwd ${spaceTrackPassword}

### copy data over back to /astro
mkdir ${datadir}/${norad}/stackRot
cp *.npy ${datadir}/${norad}/stackRot



end=`date +%s`
runtime=$((end-start))

echo "the job run time ${runtime}"

}
