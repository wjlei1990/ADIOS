#!/bin/bash
#
# Test if staged read method functions correctly
#
# Environment variables set by caller:
# MPIRUN        Run command
# NP_MPIRUN     Run commands option to set number of processes
# MAXPROCS      Max number of processes allowed
# HAVE_FORTRAN  yes or no
# SRCDIR        Test source dir (.. of this script)
# TRUNKDIR      ADIOS trunk dir

PROCS=32
READPROCS=4

if [ $MAXPROCS -lt $PROCS ]; then
    echo "WARNING: Needs $PROCS processes at least"
    exit 77  # not failure, just skip
fi

# copy codes and inputs to .
cp $SRCDIR/programs/adios_amr_write .
cp $SRCDIR/programs/adios_amr_write.xml .

echo "Run C adios_amr_write"
ls -l ./adios_amr_write
echo $MPIRUN $NP_MPIRUN $PROCS ./adios_amr_write
$MPIRUN $NP_MPIRUN $PROCS ./adios_amr_write
EX=$?
ls -l ./adios_amr_write.bp
if [ ! -f adios_amr_write.bp ]; then
    echo "ERROR: C version of adios_amr_write failed. No BP file is created. Exit code=$EX"
    exit 1
fi

# copy codes and inputs to .
cp $SRCDIR/programs/adios_staged_read .

echo "Run C adios_staged_read"
ls -l ./adios_staged_read
echo $MPIRUN $NP_MPIRUN $READPROCS ./adios_staged_read
export num_aggregators=2
export chunk_size=64
$MPIRUN $NP_MPIRUN $READPROCS ./adios_staged_read | grep -v aggregator | grep [0-9] > 08_amr_write_read.txt
EX=$?
if [ ! -f adios_amr_write.bp ]; then
    echo "ERROR: C version of adios_amr_write failed. No BP file is created. Exit code=$EX"
    exit 1
fi

echo "Check output with reference"
diff -q 08_amr_write_read.txt $SRCDIR/reference/amr_write_read.txt
if [ $? != 0 ]; then
    echo "ERROR: C version of adios_global_no_xml produced a file different from the reference."
    echo "Compare \"bpls -lav $PWD/adios_global_no_xml.bp -d -n 10 | grep -v endianness\" to reference $SRCDIR/reference/global_array_no_xml_bpls.txt"
    exit 1
fi