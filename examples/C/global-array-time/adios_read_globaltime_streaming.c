/* 
 * ADIOS is freely available under the terms of the BSD license described
 * in the COPYING file in the top level directory of this source distribution.
 *
 * Copyright (c) 2008 - 2009.  UT-BATTELLE, LLC. All rights reserved.
 */

/* ADIOS C Example: read global arrays from a BP file
 *
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mpi.h"
#include "adios_read.h"

int main (int argc, char ** argv) 
{
// Bounding box selection or points selection
#define BB 1
// number of points to read if points selection
#define NP 10
    char        filename [256];
    int         rank, size, i, j, NX = 16;
    MPI_Comm    comm = MPI_COMM_WORLD;
    ADIOS_FILE * fp;
    ADIOS_VARINFO * vi;
    ADIOS_SELECTION sel;

    void * data = NULL, * data1 = NULL, * data2 = NULL;
    uint64_t start[2], count[2], bytes_read = 0;
    struct timeval t0, t1;

    MPI_Init (&argc, &argv);

    MPI_Comm_rank (comm, &rank);
    MPI_Comm_size (comm, &size);

    adios_read_init_method (ADIOS_READ_METHOD_BP, comm, "verbose=4");

    fp = adios_read_open_file ("adios_globaltime.bp", ADIOS_READ_METHOD_BP, comm);
    vi = adios_inq_var (fp, "temperature");
    adios_inq_var_blockinfo (fp, vi);
printf ("ndim = %d\n",  vi->ndim);
printf ("nsteps = %d\n",  vi->nsteps);
printf ("dims[%lu][%lu]\n",  vi->dims[0], vi->dims[1]);
    uint64_t slice_size = vi->dims[1]/size;
    start[0] = 0;

    if (rank == size-1)
        slice_size = slice_size + vi->dims[1]%size;

    count[0] = vi->dims[0];

    start[1] = rank * slice_size;
    count[1] = slice_size;

#if BB
    data = malloc (slice_size * vi->dims[0] * 8);
    if (rank == 0)
    {
        for (i = 0; i < vi->dims[0]; i++)
        {
            for (j = 0; j < slice_size; j++)
                * ((double *)data + i * slice_size  + j) = 0;
        }
    }
#else
    data = malloc (NP * 8);
#endif

#if BB
    sel.type = ADIOS_SELECTION_BOUNDINGBOX;
    sel.u.bb.ndim = vi->ndim;
    sel.u.bb.start = start;
    sel.u.bb.count = count;
#else
    sel.type = ADIOS_SELECTION_POINTS;
    sel.u.points.ndim = vi->ndim;
    sel.u.points.npoints = NP;
    sel.u.points.points = malloc (sel.u.points.npoints * vi->ndim * 8);
    for (i = 0; i < sel.u.points.npoints; i++)
    {
        sel.u.points.points[i * vi->ndim] = 0;
        sel.u.points.points[i * vi->ndim + 1] = i;
    }
#endif
/*
    sel.u.bb.ndim = 0;
    adios_schedule_read (fp, &sel, "NX", 1, 1, data);
*/
    sel.u.bb.ndim = vi->ndim;
    adios_schedule_read (fp, &sel, "temperature", 0, 1, data);

    adios_perform_reads (fp, 1);

#if BB
    if (rank == 0)
    {
        for (i = 0; i < vi->dims[0]; i++)
        {
            for (j = 0; j < slice_size; j++)
                printf (" %7.5g", * ((double *)data + i * slice_size  + j));
            printf ("\n");
        }
    }
#else
    if (rank == 0)
    {
        for (i = 0; i < sel.u.points.npoints; i++)
        {
            printf (" %7.5g", * ((double *)data + i));
        }
        printf ("\n");
    }

#endif

    adios_read_close (fp);

    adios_read_finalize_method (ADIOS_READ_METHOD_BP);

    free (data);
    MPI_Finalize ();

    return 0;
}

