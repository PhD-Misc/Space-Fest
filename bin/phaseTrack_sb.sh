#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=12:00:00
#SBATCH --ntasks=28
#SBATCH --mem=124GB
#SBATCH --tmp=890GB
#SBATCH -J phaseTrack
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


### fm band ###
cp -r ${obsnum}068-083.ms /nvmetmp
cp ${obsnum}.metafits /nvmetmp

cd /nvmetmp

### run track.py
cp /home/sprabu/customPython/track.py /nvmetmp
myPython ./track.py --obs ${obsnum} --metafits ${datadir}/${obsnum}.metafits --noradid ${norad} --user ${spaceTrackUser} --passwd ${spaceTrackPassword}

### make images along phase
tarray=
while IFS=, read -r col1 col2 col3 col4
do
    ah=$((col1))
    bh=$((ah+1))
    bt=$((col1))
    at=$((bt-1))
    tarray=(${tarray[@]} ${col1})
    echo ${tarray}
    echo ${tarray[@]}
    chgcentre ${obsnum}068-083.ms ${col2} ${col3}

    mkdir Head
    wsclean -name ${obsnum}068-083-2m-${col1}h -size 100 100 -scale 5amin -interval ${ah} ${bh} -channels-out 512 -weight natural -abs-mem 40 -temp-dir Head -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}068-083.ms &

    PID1=$!

    mkdir Tail
    wsclean -name ${obsnum}068-083-2m-${col1}t -size 100 100 -scale 5amin -interval ${at} ${bt} -channels-out 512 -weight natural -abs-mem 40 -temp-dir Tail -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}068-083.ms & 

    PID2=$!



    wait ${PID1}    
    wait ${PID2}
    
    rm -r Head
    rm -r Tail
   
done < ${obsnum}-${norad}.csv

## run rfiseeker
cp /home/sprabu/RFISeeker/RFISeekerSpaceFest /nvmetmp
#while IFS=, read -r col1 col2 col3 col4
#do
#    while [[ $(jobs | wc -l) -ge 28 ]]
#    do
#        wait -n $(jobs -p)
#    done
for col1 in "${tarray[@]}"
do
    while [[ $(jobs | wc -l) -ge 28 ]]
    do
        wait -n $(jobs -p)
    done

    python_rfi ./RFISeekerSpaceFest --obs ${obsnum}068-083 --freqChannels 512 --seedSigma 6 --floodfillSigma 1 --prefix 6Sigma1Floodfill --DSNRS=False --imgSize 100 --timeStep ${col1} &

done  
#done < ${obsnum}-${norad}.csv

i=0
for job in `jobs -p`
do
    pids[${i}]=${job}
    i=$((i+1))
done
for pid in ${pids[*]}; do
    wait ${pid}
done

## run timeLapse.py
## get min max timestep values
max=${tarray[0]}
min=${tarray[0]}

for i in "${tarray[@]}"; do
  (( i > max )) && max=$i
  (( i < min )) && min=$i
done
cp /home/sprabu/customPython/TrackTimeLapse.py /nvmetmp
myPython ./TrackTimeLapse.py --obs ${obsnum} --noradid ${norad} --t1 ${min} --t2 ${max} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --prefix 6Sigma1Floodfill 

### make cube
cp /home/sprabu/customPython/makeCube.py /nvmetmp 
myPython ./makeCube.py --obs ${obsnum}068-083 --noradid ${norad} -channels 512

### copy data over back to /astro
mkdir ${datadir}/${norad}/fm
cp *.npy ${datadir}/${norad}/fm
cp 6S*.fits ${datadir}/${norad}/fm
cp *.csv ${datadir}/${norad}/fm
cp *.png ${datadir}/${norad}/fm
rm -r *

#### end of fm band run

### run data in orbcomm band
cp -r ${obsnum}107-108.ms /nvmetmp
cp ${obsnum}.metafits /nvmetmp
cd /nvmetmp

### run track.py
cp /home/sprabu/customPython/track.py /nvmetmp
myPython ./track.py --obs ${obsnum} --metafits ${datadir}/${obsnum}.metafits --noradid ${norad} --user ${spaceTrackUser} --passwd ${spaceTrackPassword}

### make images along phase
tarray=
while IFS=, read -r col1 col2 col3 col4
do
    ah=$((col1))
    bh=$((ah+1))
    bt=$((col1))
    at=$((bt-1))
    tarray=(${tarray[@]} ${col1})
    echo ${tarray}
    echo ${tarray[@]}
    chgcentre ${obsnum}107-108.ms ${col2} ${col3}

    mkdir Head
    wsclean -name ${obsnum}107-108-2m-${col1}h -size 100 100 -scale 5amin -interval ${ah} ${bh} -channels-out 64 -weight natural -abs-mem 40 -temp-dir Head -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}107-108.ms &

    PID1=$!

    mkdir Tail
    wsclean -name ${obsnum}107-108-2m-${col1}t -size 100 100 -scale 5amin -interval ${at} ${bt} -channels-out 64 -weight natural -abs-mem 40 -temp-dir Tail -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}107-108.ms & 

    PID2=$!



    wait ${PID1}    
    wait ${PID2}
    
    rm -r Head
    rm -r Tail
   
done < ${obsnum}-${norad}.csv

## run rfiseeker
cp /home/sprabu/RFISeeker/RFISeekerSpaceFest /nvmetmp
#while IFS=, read -r col1 col2 col3 col4
#do
#    while [[ $(jobs | wc -l) -ge 28 ]]
#    do
#        wait -n $(jobs -p)
#    done

for col1 in "${tarray[@]}"
do
    while [[ $(jobs | wc -l) -ge 28 ]]
    do
        wait -n $(jobs -p)
    done
    python_rfi ./RFISeekerSpaceFest --obs ${obsnum}107-108 --freqChannels 64 --seedSigma 6 --floodfillSigma 1 --prefix 6Sigma1Floodfill --DSNRS=False --imgSize 100 --timeStep ${col1} &
   
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

## run timeLapse.py
## get min max timestep values
max=${tarray[0]}
min=${tarray[0]}

for i in "${tarray[@]}"; do
  (( i > max )) && max=$i
  (( i < min )) && min=$i
done
cp /home/sprabu/customPython/TrackTimeLapse.py /nvmetmp
myPython ./TrackTimeLapse.py --obs ${obsnum} --noradid ${norad} --t1 ${min} --t2 ${max} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --prefix 6Sigma1Floodfill 

### make cube
cp /home/sprabu/customPython/makeCube.py /nvmetmp 
myPython ./makeCube.py --obs ${obsnum}107-108 --noradid ${norad} -channels 64

### copy data over back to /astro
mkdir ${datadir}/${norad}/orb
cp *.npy ${datadir}/${norad}/orb
cp 6S*.fits ${datadir}/${norad}/orb
cp *.csv ${datadir}/${norad}/orb
cp *.png ${datadir}/${norad}/orb
rm -r *
### end of orbcomm band


### start of dl band
cp -r ${obsnum}112-114.ms /nvmetmp
cp ${obsnum}.metafits /nvmetmp
cd /nvmetmp

### run track.py
cp /home/sprabu/customPython/track.py /nvmetmp
myPython ./track.py --obs ${obsnum} --metafits ${datadir}/${obsnum}.metafits --noradid ${norad} --user ${spaceTrackUser} --passwd ${spaceTrackPassword}

### make images along phase
tarray=
while IFS=, read -r col1 col2 col3 col4
do
    ah=$((col1))
    bh=$((ah+1))
    bt=$((col1))
    at=$((bt-1))
    tarray=(${tarray[@]} ${col1})
    echo ${tarray}
    echo ${tarray[@]}
    chgcentre ${obsnum}112-114.ms ${col2} ${col3}

    mkdir Head
    wsclean -name ${obsnum}112-114-2m-${col1}h -size 100 100 -scale 5amin -interval ${ah} ${bh} -channels-out 96 -weight natural -abs-mem 40 -temp-dir Head -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}112-114.ms &

    PID1=$!

    mkdir Tail
    wsclean -name ${obsnum}112-114-2m-${col1}t -size 100 100 -scale 5amin -interval ${at} ${bt} -channels-out 96 -weight natural -abs-mem 40 -temp-dir Tail -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}112-114.ms & 

    PID2=$!



    wait ${PID1}    
    wait ${PID2}
    
    rm -r Head
    rm -r Tail
   
done < ${obsnum}-${norad}.csv

## run rfiseeker
cp /home/sprabu/RFISeeker/RFISeekerSpaceFest /nvmetmp
#while IFS=, read -r col1 col2 col3 col4
#do
#    while [[ $(jobs | wc -l) -ge 28 ]]
#    do
#        wait -n $(jobs -p)
#    done
for col1 in "${tarray[@]}"
do
    while [[ $(jobs | wc -l) -ge 28 ]]
    do
        wait -n $(jobs -p)
    done

    python_rfi ./RFISeekerSpaceFest --obs ${obsnum}112-114 --freqChannels 96 --seedSigma 6 --floodfillSigma 1 --prefix 6Sigma1Floodfill --DSNRS=False --imgSize 100 --timeStep ${col1} &
   
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

## run timeLapse.py
## get min max timestep values
max=${tarray[0]}
min=${tarray[0]}

for i in "${tarray[@]}"; do
  (( i > max )) && max=$i
  (( i < min )) && min=$i
done
cp /home/sprabu/customPython/TrackTimeLapse.py /nvmetmp
myPython ./TrackTimeLapse.py --obs ${obsnum} --noradid ${norad} --t1 ${min} --t2 ${max} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --prefix 6Sigma1Floodfill 

### make cube
cp /home/sprabu/customPython/makeCube.py /nvmetmp 
myPython ./makeCube.py --obs ${obsnum}112-114 --noradid ${norad} -channels 96

### copy data over back to /astro
mkdir ${datadir}/${norad}/dl
cp *.npy ${datadir}/${norad}/dl
cp 6S*.fits ${datadir}/${norad}/dl
cp *.csv ${datadir}/${norad}/dl
cp *.png ${datadir}/${norad}/dl
rm -r *
### end of dl band


### start of dtv band
cp -r ${obsnum}147-149.ms /nvmetmp
cp ${obsnum}.metafits /nvmetmp
cd /nvmetmp

### run track.py
cp /home/sprabu/customPython/track.py /nvmetmp
myPython ./track.py --obs ${obsnum} --metafits ${datadir}/${obsnum}.metafits --noradid ${norad} --user ${spaceTrackUser} --passwd ${spaceTrackPassword}

### make images along phase
tarray=
while IFS=, read -r col1 col2 col3 col4
do
    ah=$((col1))
    bh=$((ah+1))
    bt=$((col1))
    at=$((bt-1))
    tarray=(${tarray[@]} ${col1})
    echo ${tarray}
    echo ${tarray[@]}
    chgcentre ${obsnum}147-149.ms ${col2} ${col3}

    mkdir Head
    wsclean -name ${obsnum}147-149-2m-${col1}h -size 100 100 -scale 5amin -interval ${ah} ${bh} -channels-out 1 -weight natural -abs-mem 40 -temp-dir Head -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}147-149.ms &

    PID1=$!

    mkdir Tail
    wsclean -name ${obsnum}147-149-2m-${col1}t -size 100 100 -scale 5amin -interval ${at} ${bt} -channels-out 1 -weight natural -abs-mem 40 -temp-dir Tail -quiet -maxuvw-m 1212 -use-wgridder ${obsnum}147-149.ms & 

    PID2=$!



    wait ${PID1}    
    wait ${PID2}
    
    rm -r Head
    rm -r Tail
   
done < ${obsnum}-${norad}.csv

## run rfiseeker
cp /home/sprabu/RFISeeker/RFISeekerSpaceFest /nvmetmp
#while IFS=, read -r col1 col2 col3 col4
#do
#    while [[ $(jobs | wc -l) -ge 28 ]]
#    do
#        wait -n $(jobs -p)
#    done
for col1 in "${tarray[@]}"
do
    while [[ $(jobs | wc -l) -ge 28 ]]
    do
        wait -n $(jobs -p)
    done

    python_rfi ./RFISeekerSpaceFest --obs ${obsnum}147-149 --freqChannels 1 --seedSigma 6 --floodfillSigma 1 --prefix 6Sigma1Floodfill --DSNRS=False --imgSize 100 --timeStep ${col1} &
   
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

## run timeLapse.py
## get min max timestep values
max=${tarray[0]}
min=${tarray[0]}

for i in "${tarray[@]}"; do
  (( i > max )) && max=$i
  (( i < min )) && min=$i
done
cp /home/sprabu/customPython/TrackTimeLapse.py /nvmetmp
myPython ./TrackTimeLapse.py --obs ${obsnum} --noradid ${norad} --t1 ${min} --t2 ${max} --user ${spaceTrackUser} --passwd ${spaceTrackPassword} --prefix 6Sigma1Floodfill 

### make cube
cp /home/sprabu/customPython/makeCube.py /nvmetmp 
myPython ./makeCube.py --obs ${obsnum}147-149 --noradid ${norad} -channels 96

### copy data over back to /astro
mkdir ${datadir}/${norad}/dtv
cp *.npy ${datadir}/${norad}/dtv
cp 6S*.fits ${datadir}/${norad}/dtv
cp *.csv ${datadir}/${norad}/dtv
cp *.png ${datadir}/${norad}/dtv

### end of dtv band





end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"

}
