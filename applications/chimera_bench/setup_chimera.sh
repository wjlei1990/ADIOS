#!/bin/sh

# set working directory
if [ "X$1" = "X" ]
then
    export WORKING_DIR=/tmp/work/$LOGNAME/chimera_bench
else
    export WORKING_DIR=$1
fi

if [ "X$2" = "X" ]
then
    export LOW_BOUND_PROC=512
else 
    export LOW_BOUND_PROC=$2
fi

if [ "X$3" = "X" ]
then
    export UP_BOUND_PROC=16384
else 
    export UP_BOUND_PROC=$3
fi

if [ "X$4" = "X" ]
then
    export NUMBER_TEST=5
else 
    export NUMBER_TEST=$4
fi

echo "Chimera Benchmark is set to " $WORKING_DIR
echo "Number of processes from " $LOW_BOUND_PROC " to " $UP_BOUND_PROC
echo "For each (number of processes, ADIOS Method), run " $NUMBER_TEST " job(s)"
echo
sleep 2
echo 
echo "Decompress..."
echo 
sleep 1

mkdir -p $WORKING_DIR
cp ~zf2/chimera_bench.tar.gz $WORKING_DIR
cd $WORKING_DIR
tar zxvf chimera_bench.tar.gz

echo 
echo "Build executables in " $WORKING_DIR"/RadHyd3D_adios/Execute/build ..." 
echo 
sleep 1

# build executables
module load hdf5/1.6.7_par
cd RadHyd3D_adios/Execute/build
make

echo
echo "Correct path in scripts ..."
echo
sleep 1

# correct paths in scripts and input files to refer to WORKING_DIR
cd $WORKING_DIR/chimera_setting

WD_STRING=`echo $WORKING_DIR|sed -e "s:\/:\\\\/:g"`
for i in gen_script.sh chimera.pbs post_script.sh
do
    sed -i.bak -e "s:wwww:$WD_STRING:g" ./$i
    rm $i.bak
done

i=$LOW_BOUND_PROC
while [ $i -le $UP_BOUND_PROC ]
do
    sed -i.bak -e "s:wwww:$WD_STRING:g" $i/Initial_Data/array_dimensions.d
    rm $i/Initial_Data/array_dimensions.d.bak
    let i=i*2
done

echo
echo "Create sub-directories in $WORKING_DIR/chimera_run for job execution ..."
echo
sleep 1

# setup chimera_run
sh ./create_working_dir.sh

echo 
echo "Benchmark environment is setup in " $WORKING_DIR
echo 
