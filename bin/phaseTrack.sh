#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=6:00:00
#SBATCH --ntasks=20
#SBATCH --mem=124GB
#SBATCH --tmp=450GB
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
norad=NORAD


datadir=${base}processing/${obsnum}
cd ${datadir}

if [[ -d "${norad}" ]]
then
    rm -r ${norad}
fi

mkdir ${norad}
cp -r ${obsnum}.ms /nvmetmp
cp ${obsnum}.metafits /nvmetmp

cd /nvmetmp

### run track.py
cp /astro/mwasci/sprabu/path/PawseyPathFiles/track.py /nvmetmp
cp /astro/mwasci/sprabu/satellites/Space-Fest/tle/${norad}${obsnum}.txt /nvmetmp
myPython ./track.py --obs ${obsnum} --metafits ${datadir}/${obsnum}.metafits --noradid ${norad} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --debug True

### make images along phase
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
    chgcentre ${obsnum}.ms ${col2} ${col3}

    mkdir Head
    wsclean -name ${obsnum}-2m-${col1}h -size 200 200 -scale 5amin -interval ${ah} ${bh} -channels-out 768 -weight natural -abs-mem 40 -temp-dir Head -quiet -maxuvw-m ${col4} -use-wgridder ${obsnum}.ms &

    PID1=$!

    mkdir Tail
    wsclean -name ${obsnum}-2m-${col1}t -size 200 200 -scale 5amin -interval ${at} ${bt} -channels-out 768 -weight natural -abs-mem 40 -temp-dir Tail -quiet -maxuvw-m ${col4} -use-wgridder ${obsnum}.ms & 

    PID2=$!



    wait ${PID1}    
    wait ${PID2}
    
    rm -r Head
    rm -r Tail
   
done < ${obsnum}-${norad}.csv

## run rfiseeker
cp /home/sprabu/RFISeeker/RFISeekerSpaceFest /nvmetmp

for col1 in "${tarray[@]}"
do
    while [[ $(jobs | wc -l) -ge 28 ]]
    do
        wait -n $(jobs -p)
    done
    python_rfi ./RFISeekerSpaceFest --obs ${obsnum} --freqChannels 768 --seedSigma 6 --floodfillSigma 1 --prefix 6Sigma1Floodfill --DSNRS=False --imgSize 200 --timeStep ${col1} &

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

#while IFS=, read -r col1 col2 col3 col4
#do
#    while [[ $(jobs | wc -l) -ge 28 ]]
#    do
#        wait -n $(jobs -p)
#    done
#
#    python_rfi ./RFISeekerSpaceFest --obs ${obsnum} --freqChannels 768 --seedSigma 6 --floodfillSigma 1 --prefix 6Sigma1Floodfill --DSNRS=False --imgSize 100 --timeStep ${col1} &
#   
#done < ${obsnum}-${norad}.csv
#
#i=0
#for job in `jobs -p`
#do
#    pids[${i}]=${job}
#    i=$((i+1))
#done
#for pid in {pids[*]}; do
#    wait ${pid}
#done

## run timeLapse.py
## get min max timestep values
max=${tarray[0]}
min=${tarray[0]}

for i in "${tarray[@]}"; do
  (( i > max )) && max=$i
  (( i < min )) && min=$i
done
cp /astro/mwasci/sprabu/path/PawseyPathFiles/TrackTimeLapse.py /nvmetmp
myPython ./TrackTimeLapse.py --obs ${obsnum} --noradid ${norad} --t1 ${min} --t2 ${max} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --prefix 6Sigma1Floodfill

### make cube
#cp /astro/mwasci/sprabu/path/PawseyPathFiles/makeCube_v2.py /nvmetmp 
#myPython3 ./makeCube_v2.py --obs ${obsnum} --noradid ${norad} --channels 768 --user ${spaceTrackUser} --passwd ${spaceTrackPassword}
 
cp /astro/mwasci/sprabu/path/PawseyPathFiles/makeCube_v3.py /nvmetmp
myPython3 ./makeCube_v3.py --obs ${obsnum} --noradid ${norad} --channels 768 --user ${spaceTrackUser} --passwd ${spaceTrackPassword}


### copy data over back to /astro
cp *.npy ${datadir}/${norad}
cp 6S*.fits ${datadir}/${norad}
cp *.csv ${datadir}/${norad}
cp *.png ${datadir}/${norad}
cp *.txt ${datadir}/${norad}
#cp *dirty.fits ${datadir}/${norad}


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"

}
