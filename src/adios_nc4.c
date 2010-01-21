/* 
 * ADIOS is freely available under the terms of the BSD license described
 * in the COPYING file in the top level directory of this source distribution.
 *
 * Copyright (c) 2008 - 2009.  UT-BATTELLE, LLC. All rights reserved.
 */

#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <stdio.h>

#include "mpi.h"
#include "adios.h"
#include "adios_types.h"
#include "adios_bp_v1.h"
#include "adios_transport_hooks.h"
#include "adios_internals.h"
#ifdef NC4 
#include "netcdf.h"
#endif

#include "io_timer.h"

typedef char nc4_dimname_t[256];

#define NUM_GP 24
void adios_nc4_end_iteration (struct adios_method_struct * method)
{
}

void adios_nc4_start_calculation (struct adios_method_struct * method)
{
}

void adios_nc4_stop_calculation (struct adios_method_struct * method)
{
}
void adios_nc4_get_write_buffer (struct adios_file_struct * fd
		,struct adios_var_struct * v
		,uint64_t * size
		,void ** buffer
		,struct adios_method_struct * method
)
{
}


#ifndef NC4
void adios_nc4_init(const char *parameters
		,struct adios_method_struct * method
){}
void adios_nc4_finalize (int mype, struct adios_method_struct * method){}
enum ADIOS_FLAG adios_nc4_should_buffer (struct adios_file_struct * fd
		,struct adios_method_struct * method
){ return adios_flag_unknown; }
int adios_nc4_open(struct adios_file_struct *fd
		,struct adios_method_struct * method
		,void * comm
){ return -1; }
void adios_nc4_close (struct adios_file_struct * fd
		,struct adios_method_struct * method
){}
void adios_nc4_write (struct adios_file_struct * fd
		,struct adios_var_struct * v
		,void * data
		,struct adios_method_struct * method
){}
void adios_nc4_read (struct adios_file_struct * fd
		,struct adios_var_struct * v, void * buffer
		,uint64_t buffersize
		,struct adios_method_struct * method
){}
#else

///////////////////////////
// Function Declarations
///////////////////////////
int getTypeSize(enum ADIOS_DATATYPES type, void * val);

// adios_flag determine whether it is dataset or group

void open_groups(int root_group,
		char *path,
		int *grp_id,
		int *level,
		char **last,
		enum ADIOS_FLAG open_for_attr,
		enum ADIOS_FLAG flag);
void close_groups(int *grp_id,
		int level,
		enum ADIOS_FLAG flag);
int getNC4TypeId(enum ADIOS_DATATYPES type,
		int *nc4_type_id,
		enum ADIOS_FLAG fortran_flag);
void populate_dimension_size(struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_dimension_item_struct *dim,
		size_t dimsize);
void parse_dimension_size(struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_dimension_item_struct * dim,
		size_t *dimsize);
void parse_dimension_name(struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_dimension_item_struct * dim,
		nc4_dimname_t dimname);
int write_var(int ncid,
		int root_group,
		struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_var_struct *pvar,
		enum ADIOS_FLAG fortran_flag,
		int myrank,
		int nproc);
int read_var (int ncid,
		int root_group,
		struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_var_struct *pvar,
		enum ADIOS_FLAG fortran_flag,
		int myrank,
		int nproc);
int write_attribute(int ncid,
		int root_group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt,
		enum ADIOS_FLAG fortran_flag,
		int myrank,
		int nproc);

typedef struct {
	struct adios_dimension_struct *dims;

	nc4_dimname_t  gbdims_dim0_name;
	nc4_dimname_t  gbdims_dim1_name;
	nc4_dimname_t  gbdims_name;
	nc4_dimname_t *nc4_global_dimnames;
	nc4_dimname_t *nc4_local_dimnames;
	nc4_dimname_t *nc4_local_offset_names;

	size_t    *nc4_gbdims;
	size_t    *nc4_globaldims;
	size_t    *nc4_localdims;
	size_t    *nc4_offsets;
	ptrdiff_t *nc4_strides;
	int       *nc4_global_dimids;
	int       *nc4_local_dimids;
	int       *nc4_loffs_dimids;

	ptrdiff_t nc4_gbstrides[2];
	size_t    nc4_gbglobaldims[2];
	size_t    nc4_gblocaldims[2];
	size_t    nc4_gboffsets[2];
	int       nc4_gbglobaldims_dimids[2];
	int       nc4_gbglobaldims_varid;

	enum ADIOS_FLAG has_globaldims;
	enum ADIOS_FLAG has_localdims;
	enum ADIOS_FLAG has_localoffsets;

	enum ADIOS_FLAG has_timedim;
	int             timedim_index;

	int global_dim_count;
	int local_dim_count;
	int local_offset_count;
} deciphered_dims_t;
struct adios_nc4_data_struct
{
	int      ncid;
	int      root_ncid;
	MPI_Comm group_comm;
	int      rank;
	int      size;

	void * comm; // temporary until moved from should_buffer to open
};
static int adios_nc4_initialized = 0;
static void adios_var_to_comm_nc4 (enum ADIOS_FLAG host_language_fortran, void * data, MPI_Comm * comm)
{
	if (data) {
		int t = *(int *) data;
		if (host_language_fortran == adios_flag_yes) {
			*comm = MPI_Comm_f2c (t);
		} else {
			*comm = *(MPI_Comm *) data;
		}
	} else {
		fprintf (stderr, "coordination-communication not provided. "
				"Using MPI_COMM_WORLD instead\n");
		*comm = MPI_COMM_WORLD;
	}
}
void adios_nc4_init(const char *parameters, struct adios_method_struct * method)
{
	struct adios_nc4_data_struct *md = (struct adios_nc4_data_struct *)method->method_data;
	if (!adios_nc4_initialized) {
		adios_nc4_initialized = 1;
	}
	method->method_data = malloc(sizeof(struct adios_nc4_data_struct));
	md = (struct adios_nc4_data_struct *)method->method_data;
	md->ncid       = -1;
	md->root_ncid  = -1;
	md->rank       = -1;
	md->size       = 0;
	md->group_comm = MPI_COMM_NULL;
}
enum ADIOS_FLAG adios_nc4_should_buffer (struct adios_file_struct * fd, struct adios_method_struct * method)
{
	int rc=NC_NOERR;

	struct adios_nc4_data_struct *md = (struct adios_nc4_data_struct *)method->method_data;
	char *name;
	MPI_Info info = MPI_INFO_NULL;
	adios_var_to_comm_nc4(fd->group->adios_host_language_fortran, md->comm, &md->group_comm);
	// no shared buffer
	//fd->shared_buffer = adios_flag_no;
	if (md->group_comm != MPI_COMM_NULL) {
		MPI_Comm_rank(md->group_comm, &md->rank);
		MPI_Comm_size(md->group_comm, &md->size);
	} else {
		md->group_comm=MPI_COMM_SELF;
	}
	fd->group->process_id = md->rank;
	name = malloc(strlen(method->base_path) + strlen(fd->name) + 1);
	sprintf(name, "%s%s", method->base_path, fd->name);

	// create a new file. If file exists its contents will be overwritten. //

	MPI_Info_create(&info);
	MPI_Info_set(info,"cb_align","2");
	MPI_Info_set(info,"romio_ds_write","disable");

	switch (fd->mode) {
		case adios_mode_read:
		{
			rc = nc_open_par(name, NC_NOWRITE|NC_MPIIO, md->group_comm, info, &md->ncid);
			if (rc != NC_NOERR) {
				fprintf (stderr, "ADIOS NC4: could not open file(%s) for reading, rc=%d\n", name, rc);
				free (name);
				return adios_flag_no;
			}
			break;
		}
		case adios_mode_write:
		case adios_mode_append:
		{
			rc = nc_create_par(name, NC_NOCLOBBER|NC_MPIIO|NC_NETCDF4, md->group_comm, info, &md->ncid);
			if (rc == NC_EEXIST) {
				rc = nc_open_par(name, NC_WRITE|NC_MPIIO, md->group_comm, info, &md->ncid);
				if (rc != NC_NOERR) {
					fprintf (stderr, "ADIOS NC4: could not open file(%s) for writing, rc=%d\n", name, rc);
					free (name);
					return adios_flag_no;
				}
			} else if (rc != NC_NOERR) {
				fprintf (stderr, "ADIOS NC4: cannot create file(%s), rc=%d\n", name, rc);
				free (name);
				return adios_flag_no;
			}
			break;
		}
	}

	md->root_ncid = md->ncid;
//	rc = nc_inq_ncid(md->ncid, NULL, &md->root_ncid);
//	if (rc != NC_NOERR)
//	{
//		fprintf (stderr, "ADIOS NC4: root group not found (THIS SHOULD NEVER HAPPEN): %s\n", fd->name);
//		free (name);
//		return adios_flag_no;
//	}

	free(name);

	return adios_flag_no;
}

int adios_nc4_open(struct adios_file_struct *fd, struct adios_method_struct * method, void * comm)
{
	struct adios_nc4_data_struct * md = (struct adios_nc4_data_struct *)method->method_data;

	md->comm = comm;

	return 1;
}

void adios_nc4_write (struct adios_file_struct * fd, struct adios_var_struct * v, void * data, struct adios_method_struct * method)
{
	struct adios_nc4_data_struct * md = (struct adios_nc4_data_struct *)method->method_data;
	if (fd->mode == adios_mode_write || fd->mode == adios_mode_append) {
		if (md->rank==0) {
//			fprintf(stderr, "-------------------------\n");
//			fprintf(stderr, "write var: %s start!\n", v->name);
		}
		write_var(md->ncid,
				md->root_ncid,
				fd->group,
				fd->group->vars,
				fd->group->attributes,
				v,
				fd->group->adios_host_language_fortran,
				md->rank,md->size);
	} else {
		//fprintf(stderr, "entering unknown nc4 mode %d!\n", fd->mode);
	}
	if (md->rank==0) {
//		fprintf(stderr, "write var: %s end!\n", v->name);
		//fprintf(stderr, "-------------------------\n");
	}
}


void adios_nc4_read(struct adios_file_struct * fd, struct adios_var_struct * v, void * buffer, uint64_t buffersize, struct adios_method_struct * method)
{
	struct adios_nc4_data_struct * md = (struct adios_nc4_data_struct *)
                                                    						   method->method_data;
	if(fd->mode == adios_mode_read) {
		v->data = buffer;
		v->data_size = buffersize;

		if (md->rank==0) {
//			fprintf(stderr, "-------------------------\n");
//			fprintf(stderr, "read var: %s! start\n", v->name);
		}
		read_var(md->ncid,
				md->root_ncid,
				fd->group,
				fd->group->vars,
				fd->group->attributes,
				v,
				fd->group->adios_host_language_fortran,
				md->rank,
				md->size);
		v->data = 0;
		if (md->rank==0) {
//			fprintf(stderr, "read var: %s! end\n", v->name);
			//fprintf(stderr, "-------------------------\n");
		}

	}
}

static void adios_nc4_do_read (struct adios_file_struct * fd, struct adios_method_struct * method)
{
	// This function is not useful for nc4 since adios_read/write do real read/write
}

void adios_nc4_close (struct adios_file_struct * fd, struct adios_method_struct * method)
{
	struct adios_nc4_data_struct * md = (struct adios_nc4_data_struct*)method->method_data;

	struct adios_attribute_struct * a = fd->group->attributes;

	if (fd->mode == adios_mode_read) {
		if (md->rank==0) {
			fprintf(stderr, "-------------------------\n");
			fprintf(stderr, "reading done, nc4 file is closed;\n");
			fprintf(stderr, "-------------------------\n");
		}
	} else if (fd->mode == adios_mode_write || fd->mode == adios_mode_append) {
		//fprintf(stderr, "entering nc4 write attribute mode!\n");
		while(a) {
			write_attribute(md->ncid, md->root_ncid, fd->group->vars, a,
					fd->group->adios_host_language_fortran,
					md->rank,
					md->size);
			a = a->next;
		}
		if (md->rank==0) {
			fprintf(stderr, "-------------------------\n");
			fprintf(stderr, "writing done, nc4 file is closed;\n");
			fprintf(stderr, "-------------------------\n");
		}
	}

	if (md) {
		nc_close(md->ncid);
	}
	md->group_comm = MPI_COMM_NULL;
	md->ncid = -1;
	md->root_ncid = -1;
	md->rank = -1;
	md->size = 0;
}

void adios_nc4_finalize (int mype, struct adios_method_struct * method)
{
	// nothing to do here
	if (adios_nc4_initialized)
		adios_nc4_initialized = 0;
}

int write_attribute(int ncid,
		int root_group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt,
		enum ADIOS_FLAG fortran_flag,
		int myrank,
		int nproc)
{

	int i, rank = 0;
	char *name;
	char *last;
	int rc;

	int level;
	int grp_ids[NUM_GP];
	int nc4_type_id;
	int varid;

	struct adios_dimension_struct * dims;
	struct adios_var_struct * var_linked;

	open_groups(root_group, patt->path, grp_ids, &level, &last, adios_flag_yes, adios_flag_yes);

	int err_code = 0;

//	printf("looking for var(%s)\n", last);
	rc = nc_inq_varid(grp_ids[level], last, &varid);
	if (rc == NC_NOERR) {
	} else if (rc == NC_ENOTVAR) {
//		fprintf (stderr, "NC4 ERROR variable(%s) does not exist in write_attribute, rc=%d\n", last, rc);
		err_code = -2;
		goto escape;
	} else {
		fprintf (stderr, "NC4 ERROR inquiring about grp_id(%d) variable(%s) in write_attribute, rc=%d\n", grp_ids[level], last, rc);
		err_code = -2;
		goto escape;
	}
//	printf("got varid(%d) for grp_id(%d).variable(%s) in write_attribute\n", varid, grp_ids[level], last);

//	printf("patt->type=%d patt->name : %s\n", patt->type, patt->name);
	if (patt->type == -1) {
		var_linked = patt->var;
		if (!var_linked || (var_linked && !var_linked->data)) {
			fprintf (stderr, "NC4 ERROR: invalid data in var_linked(%s(%d)) (in attribute write), rc=%d\n"
					,var_linked->name, var_linked->id, rc);
			err_code = -2;
			goto escape;
		} else {
			dims = var_linked->dimensions;
		}
		getNC4TypeId(var_linked->type, &nc4_type_id, fortran_flag);
		// Scalar variable as attribute
		if (!dims) {
			rc = nc_put_att(grp_ids[level], varid, patt->name, nc4_type_id, 1, var_linked->data);
			if (rc != NC_NOERR) {
				fprintf (stderr, "NC4 ERROR unable to put attribute(%s) in write_attribute, rc=%d\n", patt->name, rc);
				err_code = -2;
				goto escape;
			}
		} else {
			fprintf (stderr, "NC4 ERROR multi-dimensional attribute(%s) unsupported for variable(%s) in write_attribute, rc=%d\n", patt->name, pvar_root->name, rc);
			err_code = -2;
			goto escape;
			//             while (dims) {
			//                ++rank;
			//                dims = dims->next;
			//             }
			//
			//             h5_localdims = (hsize_t *) malloc (rank * sizeof(hsize_t));
			//             dims = var_linked->dimensions;
			//             for ( i = 0; i < rank; i++) {
			//                 if ( dims->dimension.rank == 0 && dims->dimension.id) {
			//                     var_linked = adios_find_var_by_id (pvar_root , dims->dimension.id);
			//                     if ( var_linked) {
			//                         h5_localdims [i] = *(int *)var_linked->data;
			//                     }
			//                 } else {
			//                     h5_localdims [i] = dims->dimension.rank;
			//                 }
			//             }
			//             h5_dataspace_id = H5Screate_simple(rank,h5_localdims, NULL);
			//             h5_attribute_id = H5Aopen_name ( grp_ids[level], patt->name);
			//             if (h5_attribute_id < 0) {
			//                 h5_attribute_id = H5Acreate ( grp_ids[level], patt->name
			//                                          ,h5_type_id,h5_dataspace_id,0);
			//                 if (h5_attribute_id < 0) {
			//                     fprintf (stderr, "NC4 ERROR: getting negative attribute_id "
			//                                      "in write_attribute: %s\n", patt->name);
			//                     err_code = -2;
			//                  }
			//             }
			//             if (h5_attribute_id > 0) {
			//                 if (myrank == 0 && var_linked->data) {
			//                     H5Awrite ( h5_attribute_id, h5_type_id, var_linked->data);
			//                 }
			//                 H5Aclose ( h5_attribute_id);
			//             }
			//             H5Sclose ( h5_dataspace_id);
			//             free (h5_localdims);
		}
	}
	if (patt->type > 0) {
		getNC4TypeId(patt->type, &nc4_type_id, fortran_flag);
		if (nc4_type_id > 0) {
			if (patt->type == adios_string) {
				rc = nc_put_att_text(grp_ids[level], varid, patt->name, strlen((char *)patt->value), (const char *)patt->value);
				if (rc != NC_NOERR) {
					fprintf (stderr, "NC4 ERROR unable to put attribute(%s) in write_attribute, rc=%d\n", patt->name, rc);
					err_code = -2;
					goto escape;
				}
			} else {
				rc = nc_put_att(grp_ids[level], varid, patt->name, nc4_type_id, 1, patt->value);
				if (rc != NC_NOERR) {
					fprintf (stderr, "NC4 ERROR unable to put attribute(%s) in write_attribute, rc=%d\n", patt->name, rc);
					err_code = -2;
					goto escape;
				}
			}
		}
	}
escape:
	close_groups(grp_ids, level, adios_flag_yes);
	return err_code;
}

static int decipher_dims(int ncid,
		int root_group,
		struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_var_struct *pvar,
		int myrank,
		int nproc,
		deciphered_dims_t *deciphered_dims)
{
	int i=0;


	struct adios_dimension_struct *dims;
	nc4_dimname_t *nc4_global_dimnames=NULL;
	nc4_dimname_t *nc4_local_dimnames=NULL;
	nc4_dimname_t *nc4_local_offset_names=NULL;
	size_t    *nc4_gbdims;
	size_t    *nc4_globaldims;
	size_t    *nc4_localdims;
	size_t    *nc4_offsets;
	ptrdiff_t *nc4_strides;
	int       *nc4_global_dimids;
	int       *nc4_local_dimids;
	int       *nc4_loffs_dimids;

	int nc4_gbglobaldims_dimids[2];
	int nc4_gbglobaldims_varid;

	enum ADIOS_FLAG has_globaldims=adios_flag_no;
	enum ADIOS_FLAG has_localdims=adios_flag_no;
	enum ADIOS_FLAG has_localoffsets=adios_flag_no;

	enum ADIOS_FLAG has_timedim=adios_flag_no;
	int             timedim_index=-1;

	int global_dim_count=0;
	int local_dim_count=0;
	int local_offset_count=0;

	memset(deciphered_dims, 0, sizeof(deciphered_dims_t));

	dims=pvar->dimensions;
	while (dims) {
		if ((dims->dimension.time_index == adios_flag_yes) &&
			(dims->dimension.id == 0)) {
			has_timedim = adios_flag_yes;
			timedim_index = local_dim_count;
			local_dim_count++;
		} else if ((dims->dimension.rank != 0) ||
			(dims->dimension.rank == 0) && (dims->dimension.id != 0)) {
			has_localdims=adios_flag_yes;
			local_dim_count++;
		}
		if ((dims->global_dimension.rank != 0) ||
			(dims->global_dimension.rank == 0) && (dims->global_dimension.id != 0)) {
			has_globaldims=adios_flag_yes;
			global_dim_count++;
		}
		if ((dims->local_offset.rank != 0) ||
			(dims->local_offset.rank == 0) && (dims->local_offset.id != 0)) {
			has_localoffsets=adios_flag_yes;
			local_offset_count++;
		}
//		printf("gdims[%d].rank=%llu; id=%d, time_index=%d\n", i, dims->global_dimension.rank, dims->global_dimension.id, dims->global_dimension.time_index);
//		printf("ldims[%d].rank=%llu; id=%d, time_index=%d\n", i, dims->dimension.rank, dims->dimension.id, dims->dimension.time_index);
//		printf("loffs[%d].rank=%llu; id=%d, time_index=%d\n", i, dims->local_offset.rank, dims->local_offset.id, dims->local_offset.time_index);
		i++;
		dims = dims->next;
	}

//	printf("global_dim_count  ==%d\n", global_dim_count);
//	printf("local_dim_count   ==%d\n", local_dim_count);
//	printf("calculated local_offset_count==%d\n", local_offset_count);
	if ((has_localoffsets == adios_flag_yes) && (local_offset_count < global_dim_count)) {
		printf("assuming local_offset_count should equal global_dim_count.  FORCING EQUALITY\n");
		local_offset_count = global_dim_count;
	}

	nc4_gbdims     = (size_t *)calloc(local_dim_count * 3, sizeof(size_t));
	nc4_globaldims = nc4_gbdims;
	nc4_localdims  = nc4_gbdims + local_dim_count;
	nc4_offsets    = nc4_gbdims + (2*local_dim_count);
	nc4_strides    = (ptrdiff_t *)calloc(local_dim_count, sizeof(ptrdiff_t));
	nc4_global_dimnames      = (nc4_dimname_t *)calloc(local_dim_count, sizeof(nc4_dimname_t));
	nc4_local_dimnames       = (nc4_dimname_t *)calloc(local_dim_count, sizeof(nc4_dimname_t));
	nc4_local_offset_names   = (nc4_dimname_t *)calloc(local_dim_count, sizeof(nc4_dimname_t));
	nc4_global_dimids     = (int *)calloc(global_dim_count, sizeof(int));
	nc4_local_dimids      = (int *)calloc(local_dim_count, sizeof(int));
	nc4_loffs_dimids      = (int *)calloc(local_offset_count, sizeof(int));

	dims = pvar->dimensions;
	for (i=0;i<global_dim_count;i++) {
		parse_dimension_name(group, pvar_root, patt_root, &dims->global_dimension, nc4_global_dimnames[i]);
//		printf("global_dimension[%d]->name==%s, ->rank==%llu, ->id==%d, time_index==%d\n",
//				i, nc4_global_dimnames[i], dims->global_dimension.rank, dims->global_dimension.id, dims->global_dimension.time_index);
		if (dims) {
			dims = dims -> next;
		}
	}
	dims = pvar->dimensions;
	for (i=0;i<local_dim_count;i++) {
		parse_dimension_name(group, pvar_root, patt_root, &dims->dimension, nc4_local_dimnames[i]);
//		printf("local_dimension[%d]->name ==%s, ->rank==%llu, ->id==%d, time_index==%d\n",
//				i, nc4_local_dimnames[i], dims->dimension.rank, dims->dimension.id, dims->dimension.time_index);
		if (dims) {
			dims = dims -> next;
		}
	}
	dims = pvar->dimensions;
	for (i=0;i<local_offset_count;i++) {
		parse_dimension_name(group, pvar_root, patt_root, &dims->local_offset, nc4_local_offset_names[i]);
//		printf("local_offset[%d]->name    ==%s, ->rank==%llu, ->id==%d, time_index==%d\n",
//				i, nc4_local_offset_names[i], dims->local_offset.rank, dims->local_offset.id, dims->local_offset.time_index);
		if (dims) {
			dims = dims -> next;
		}
	}
	int global_idx=0;
	int local_idx =0;
	int loffs_idx =0;
	dims = pvar->dimensions;
//	printf("timedim_index=%d\n", timedim_index);
	while (dims) {
		/* get the global/local/offset arrays */
		nc4_strides[local_idx] = 1;
		if (timedim_index == local_idx) {
			nc4_globaldims[global_idx] = NC_UNLIMITED;
			nc4_localdims[local_idx] = 1;
			nc4_offsets[loffs_idx] = 0;
			parse_dimension_name(group, pvar_root, patt_root, &dims->dimension, nc4_global_dimnames[global_idx]);
			strcpy(nc4_local_dimnames[local_idx], nc4_global_dimnames[global_idx]);
			strcpy(nc4_local_offset_names[loffs_idx], nc4_global_dimnames[global_idx]);
			if ((global_dim_count < local_dim_count) && (local_idx < local_dim_count)) {
				global_idx++;
				loffs_idx++;
			}
		} else {
			parse_dimension_name(group, pvar_root, patt_root, &dims->dimension, nc4_local_dimnames[local_idx]);
			if (nc4_local_dimnames[local_idx][0] == '\0') {
				sprintf(nc4_local_dimnames[local_idx], "local_%d", local_idx);
			}
			parse_dimension_size(group, pvar_root, patt_root, &dims->dimension, &nc4_localdims[local_idx]);
		}
//		if (myrank==0) {
//			printf("\t%s[%d]: l(%d)", pvar->name, local_idx, nc4_localdims[local_idx]);
//		}
		local_idx++;
		if (global_idx < local_dim_count) {
			parse_dimension_name(group, pvar_root, patt_root, &dims->global_dimension, nc4_global_dimnames[global_idx]);
			if (nc4_global_dimnames[global_idx][0] == '\0') {
				sprintf(nc4_global_dimnames[global_idx], "global_%d", global_idx);
			}
			parse_dimension_size(group, pvar_root, patt_root, &dims->global_dimension, &nc4_globaldims[global_idx]);
//			if (myrank==0) {
//				printf(":g(%d)", nc4_globaldims[global_idx]);
//			}
			global_idx++;
		}
		if (loffs_idx < local_dim_count) {
			parse_dimension_name(group, pvar_root, patt_root, &dims->local_offset, nc4_local_offset_names[loffs_idx]);
			if (nc4_local_offset_names[loffs_idx][0] == '\0') {
				sprintf(nc4_local_offset_names[loffs_idx], "offset_%d", loffs_idx);
			}
			parse_dimension_size(group, pvar_root, patt_root, &dims->local_offset, &nc4_offsets[loffs_idx]);
//			if (myrank==0) {
//				printf(":o(%d)", nc4_offsets[loffs_idx]);
//			}
			loffs_idx++;
		}
//		if (myrank==0) {
//			printf("\n");
//		}

		if (dims) {
			dims = dims -> next;
		}
	}
//	for (i=0;i<local_dim_count;i++) {
//		printf("nc4_global_dimnames[%d]   ==%s\n", i, nc4_global_dimnames[i]);
//		printf("nc4_local_dimnames[%d]    ==%s\n", i, nc4_local_dimnames[i]);
//		printf("nc4_local_offset_names[%d]==%s\n", i, nc4_local_offset_names[i]);
//	}

	if ((has_timedim == adios_flag_yes) && (global_dim_count < local_dim_count)) {
		global_dim_count++;
		local_offset_count++;
	}

	deciphered_dims->nc4_gbstrides[0]    = 1;
	deciphered_dims->nc4_gbstrides[1]    = 1;
	deciphered_dims->nc4_gbglobaldims[0] = nproc;
	deciphered_dims->nc4_gbglobaldims[1] = local_dim_count * 3;
	deciphered_dims->nc4_gboffsets[0]    = myrank;
	deciphered_dims->nc4_gboffsets[1]    = 0;
	deciphered_dims->nc4_gblocaldims[0]  = 1;
	deciphered_dims->nc4_gblocaldims[1]  = local_dim_count * 3;

	sprintf(deciphered_dims->gbdims_name, "_%s_gbdims", pvar->name);
	sprintf(deciphered_dims->gbdims_dim0_name, "_%s_gbdims_dim0", pvar->name);
	sprintf(deciphered_dims->gbdims_dim1_name, "_%s_gbdims_dim1", pvar->name);


	/*
	 * Copy local scalers and pointers into deciphered_dims
	 */
	deciphered_dims->dims=pvar->dimensions;
	deciphered_dims->nc4_global_dimnames=nc4_global_dimnames;
	deciphered_dims->nc4_local_dimnames=nc4_local_dimnames;
	deciphered_dims->nc4_local_offset_names=nc4_local_offset_names;

	deciphered_dims->nc4_gbdims    =nc4_gbdims;
	deciphered_dims->nc4_globaldims=nc4_globaldims;
	deciphered_dims->nc4_localdims =nc4_localdims;
	deciphered_dims->nc4_offsets   =nc4_offsets;
	deciphered_dims->nc4_strides   =nc4_strides;
	deciphered_dims->nc4_global_dimids=nc4_global_dimids;
	deciphered_dims->nc4_local_dimids =nc4_local_dimids;
	deciphered_dims->nc4_loffs_dimids =nc4_loffs_dimids;

	memcpy(deciphered_dims->nc4_gbglobaldims_dimids, nc4_gbglobaldims_dimids, 2*sizeof(int));
	deciphered_dims->nc4_gbglobaldims_varid=nc4_gbglobaldims_varid;

	deciphered_dims->has_globaldims=has_globaldims;
	deciphered_dims->has_localdims=has_localdims;
	deciphered_dims->has_localoffsets=has_localoffsets;

	deciphered_dims->has_timedim   =has_timedim;
	deciphered_dims->timedim_index =timedim_index;

	deciphered_dims->global_dim_count=global_dim_count;
	deciphered_dims->local_dim_count=local_dim_count;
	deciphered_dims->local_offset_count=local_offset_count;
}
static int cleanup_deciphered_dims(deciphered_dims_t *deciphered_dims)
{
	if (deciphered_dims->nc4_gbdims             != NULL) free(deciphered_dims->nc4_gbdims);
	if (deciphered_dims->nc4_global_dimnames    != NULL) free(deciphered_dims->nc4_global_dimnames);
	if (deciphered_dims->nc4_local_dimnames     != NULL) free(deciphered_dims->nc4_local_dimnames);
	if (deciphered_dims->nc4_local_offset_names != NULL) free(deciphered_dims->nc4_local_offset_names);
	if (deciphered_dims->nc4_strides            != NULL) free(deciphered_dims->nc4_strides);
	if (deciphered_dims->nc4_global_dimids      != NULL) free(deciphered_dims->nc4_global_dimids);
	if (deciphered_dims->nc4_local_dimids       != NULL) free(deciphered_dims->nc4_local_dimids);
	if (deciphered_dims->nc4_loffs_dimids       != NULL) free(deciphered_dims->nc4_loffs_dimids);
}
int read_var (int ncid,
		int root_group,
		struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_var_struct *pvar,
		enum ADIOS_FLAG fortran_flag,
		int myrank,
		int nproc)
{
	int return_code=0;
	int i, rc;
	char *last;

	struct adios_dimension_struct * dims = pvar->dimensions;

	deciphered_dims_t deciphered_dims;

	int grp_ids[NUM_GP];
	int level;
	int nc4_type_id;
	int nc4_varid;

	getNC4TypeId (pvar->type, &nc4_type_id, fortran_flag);
	if (nc4_type_id <=0 )
	{
		fprintf (stderr, "ERROR in getNC4TypeId in read_var!\n");
		return_code=-2;
		goto escape;
	}

	if (pvar->path) {
		open_groups(ncid, pvar->path, grp_ids, &level, &last, adios_flag_no, adios_flag_yes);
	}
	//printf("root_id=%d, grd_ids[%d]=%d\n", root_id, level, grp_ids[level]);
	// variable is scalar only need to read by every processor

	rc = nc_inq_varid(grp_ids[level], pvar->name, &nc4_varid);
	if (rc == NC_ENOTVAR) {
		fprintf(stderr, "NC4 ERROR variable(%s) does not exist in read_var, rc=%d\n", pvar->name, rc);
		return_code=-2;
		goto escape;
	} else if (rc != NC_NOERR) {
		fprintf(stderr, "NC4 ERROR checking existence of variable(%s) in read_var, rc=%d\n", pvar->name, rc);
		return_code=-2;
		goto escape;
	}

//	if(myrank==0)printf("\tenter global reading!\n");

	if (!pvar->dimensions) { // begin scalar write
		rc = nc_inq_varid(grp_ids[level], pvar->name, &nc4_varid);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR reading scalar variable(%s) in read_var\n", pvar->name);
			return_code=-2;
			goto escape;
		}
		rc = nc_get_var(grp_ids[level], nc4_varid, pvar->data);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR getting scalar variable(%s) in read_var\n", pvar->name);
			return_code=-2;
			goto escape;
		}
		//printf("groupid=%d level=%d datasetid=%d\n",grp_ids[level],level,h5_dataset_id);
		//printf("write dataset: name=%s/%s status=%d myrank=%d\n"
		//         , pvar->path,pvar->name,status, myrank);

		close_groups(grp_ids,level, adios_flag_yes);
		return_code=0;
		goto escape;
	} // end scalar write

	decipher_dims(ncid,
			root_group,
			group,
			pvar_root,
			patt_root,
			pvar,
			myrank,
			nproc,
			&deciphered_dims);
	dims = pvar->dimensions;


	if (deciphered_dims.has_timedim == adios_flag_no) {

		/* begin reading array with fixed dimensions */

//		if (myrank==0) printf("\treading fixed dimension array var!\n");

		sprintf(deciphered_dims.gbdims_name, "_%s_gbdims", pvar->name);
		rc = nc_inq_varid(grp_ids[level], deciphered_dims.gbdims_name, &deciphered_dims.nc4_gbglobaldims_varid);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR looking up array variable(%s) in read_var\n", deciphered_dims.gbdims_name);
			return_code=-2;
			goto escape;
		}
		rc = nc_get_vars(grp_ids[level], deciphered_dims.nc4_gbglobaldims_varid, deciphered_dims.nc4_gboffsets, deciphered_dims.nc4_gblocaldims, deciphered_dims.nc4_gbstrides, deciphered_dims.nc4_gbdims);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR getting array variable(%s) in read_var\n", deciphered_dims.gbdims_name);
			return_code=-2;
			goto escape;
		}

		dims = pvar->dimensions;
		for (i=0;i<deciphered_dims.global_dim_count;i++) {
			populate_dimension_size(group, pvar_root, patt_root, &dims->global_dimension, deciphered_dims.nc4_globaldims[i]);
//			if (myrank==0) {
//				printf("\t%s[%d]: g(%d)", pvar->name, i, deciphered_dims.nc4_globaldims[i]);
//			}
			if (dims) {
				dims = dims -> next;
			}
		}
		dims = pvar->dimensions;
		for (i=0;i<deciphered_dims.local_dim_count;i++) {
			populate_dimension_size(group, pvar_root, patt_root, &dims->dimension, deciphered_dims.nc4_localdims[i]);
//			if (myrank==0) {
//				printf("\t%s[%d]: l(%d)", pvar->name, i, deciphered_dims.nc4_localdims[i]);
//			}
			if (dims) {
				dims = dims -> next;
			}
		}
		dims = pvar->dimensions;
		for (i=0;i<deciphered_dims.local_offset_count;i++) {
			populate_dimension_size(group, pvar_root, patt_root, &dims->local_offset, deciphered_dims.nc4_offsets[i]);
//			if (myrank==0) {
//				printf("\t%s[%d]: o(%d)", pvar->name, i, deciphered_dims.nc4_offsets[i]);
//			}
			if (dims) {
				dims = dims -> next;
			}
		}

//		for (i=0;i<deciphered_dims.local_dim_count;i++) {
//			if(myrank==0) {
//				printf("\tDIMS var:%s dim[%d]:  %d %d %d\n",pvar->name
//						,i, deciphered_dims.nc4_globaldims[i], deciphered_dims.nc4_localdims[i], deciphered_dims.nc4_offsets[i]);
//          }
//		}

		rc = nc_get_vars(grp_ids[level], nc4_varid, deciphered_dims.nc4_offsets, deciphered_dims.nc4_localdims, deciphered_dims.nc4_strides, pvar->data);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR getting array variable(%s) in read_var\n", pvar->name);
			return_code=-2;
			goto escape;
		}

		/* end reading array with fixed dimensions */

	}
	else {

		/* begin reading array with unlimited dimension */

		sprintf(deciphered_dims.gbdims_name, "_%s_gbdims", pvar->name);
		rc = nc_inq_varid(grp_ids[level], deciphered_dims.gbdims_name, &deciphered_dims.nc4_gbglobaldims_varid);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR looking up array variable(%s) in read_var\n", deciphered_dims.gbdims_name);
			return_code=-2;
			goto escape;
		}
		rc = nc_get_vars(grp_ids[level], deciphered_dims.nc4_gbglobaldims_varid, deciphered_dims.nc4_gboffsets, deciphered_dims.nc4_gblocaldims, deciphered_dims.nc4_gbstrides, deciphered_dims.nc4_gbdims);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR getting array variable(%s) in read_var\n", deciphered_dims.gbdims_name);
			return_code=-2;
			goto escape;
		}

		dims = pvar->dimensions;
		for (i=0;i<deciphered_dims.global_dim_count;i++) {
			populate_dimension_size(group, pvar_root, patt_root, &dims->global_dimension, deciphered_dims.nc4_globaldims[i]);
			if (dims) {
				dims = dims -> next;
			}
		}
		dims = pvar->dimensions;
		for (i=0;i<deciphered_dims.local_dim_count;i++) {
			populate_dimension_size(group, pvar_root, patt_root, &dims->dimension, deciphered_dims.nc4_localdims[i]);
			if (dims) {
				dims = dims -> next;
			}
		}
		dims = pvar->dimensions;
		for (i=0;i<deciphered_dims.local_offset_count;i++) {
			populate_dimension_size(group, pvar_root, patt_root, &dims->local_offset, deciphered_dims.nc4_offsets[i]);
			if (dims) {
				dims = dims -> next;
			}
		}

//		for (i=0;i<deciphered_dims.local_dim_count;i++) {
//			if(myrank==0) {
//				printf("\tDIMS var:%s dim[%d]:  %d %d %d\n",pvar->name
//						,i, deciphered_dims.nc4_globaldims[i], deciphered_dims.nc4_localdims[i], deciphered_dims.nc4_offsets[i]);
//          }
//		}

		rc = nc_inq_varid(grp_ids[level], pvar->name, &nc4_varid);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR looking up array variable(%s) in read_var\n", pvar->name);
			return_code=-2;
			goto escape;
		}
		rc = nc_get_vars(grp_ids[level], nc4_varid, deciphered_dims.nc4_offsets, deciphered_dims.nc4_localdims, deciphered_dims.nc4_strides, pvar->data);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR getting array variable(%s) in read_var\n", pvar->name);
			return_code=-2;
			goto escape;
		}

		/* end reading array with unlimited dimension */

	}

escape:
	close_groups(grp_ids, level, adios_flag_yes);

	cleanup_deciphered_dims(&deciphered_dims);

	return return_code;
}
int write_var(int ncid, int root_group, struct adios_group_struct *group, struct adios_var_struct *pvar_root, struct adios_attribute_struct *patt_root, struct adios_var_struct *pvar, enum ADIOS_FLAG fortran_flag, int myrank, int nproc)
{
	int i;
	int rc;
	int return_code=0;
	int grp_ids[NUM_GP];
	int level;
	char *last;
	int nc4_type_id;
	int nc4_varid;
	deciphered_dims_t deciphered_dims;

	memset(&deciphered_dims, 0, sizeof(deciphered_dims_t));

	getNC4TypeId(pvar->type, &nc4_type_id, fortran_flag);
	if(nc4_type_id <= 0) {
		fprintf(stderr, "NC4 ERROR in getH5TypeId in write_var\n");
		return_code=-2;
		goto escape;
	}

	if (pvar->path) {
		Func_Timer("open_groups", open_groups(ncid, pvar->path, grp_ids, &level, &last, adios_flag_no, adios_flag_yes););
	}

	// printf("root_id=%d, grp_id=%d\n", root_id, grp_ids[level]);

	if (!pvar->dimensions) { // begin scalar write
		Func_Timer("inqvar", rc = nc_inq_varid(grp_ids[level], pvar->name, &nc4_varid););
		if (rc == NC_ENOTVAR) {
			if (pvar->type == adios_string) {
				size_t str_var_dimid=0;
				char str_var_dimname[40];
				sprintf(str_var_dimname, "%s_dim", pvar->name);
				Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], str_var_dimname, strlen((char *)pvar->data)+1, &str_var_dimid););
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR defining string variable(%s) dim in write_var, rc=%d\n", pvar->name, rc);
					return_code=-2;
					goto escape;
				}
				Func_Timer("defvar", rc = nc_def_var(grp_ids[level], pvar->name, nc4_type_id, 1, &str_var_dimid, &nc4_varid););
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR defining string variable(%s) in write_var, rc=%d\n", pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			} else {
				Func_Timer("defvar", rc = nc_def_var(grp_ids[level], pvar->name, nc4_type_id, 0, NULL, &nc4_varid););
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR defining scalar variable(%s) in write_var, rc=%d\n", pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			}
		}
		rc = nc_var_par_access(grp_ids[level], nc4_varid, NC_COLLECTIVE);
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR setting parallel access for scalar variable(%s) in write_var, rc=%d\n", pvar->name, rc);
			return_code=-2;
			goto escape;
		}

//		Func_Timer("enddef", rc = nc_enddef(grp_ids[level]););
//		if (rc != NC_NOERR) {
//			fprintf(stderr, "NC4 ERROR ending define mode for scalar variable(%s) in write_var, rc=%d\n", pvar->name, rc);
//			return_code=-2;
//			goto escape;
//		}
		Func_Timer("putvar", rc = nc_put_var(grp_ids[level], nc4_varid, pvar->data););
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR putting scalar variable(%s) in write_var, rc=%d\n", pvar->name, rc);
			return_code=-2;
			goto escape;
		}
		//printf("groupid=%d level=%d datasetid=%d\n",grp_ids[level],level,h5_dataset_id);
		//printf("write dataset: name=%s/%s status=%d myrank=%d\n"
		//         , pvar->path,pvar->name,status, myrank);

		close_groups(grp_ids,level, adios_flag_yes);

		goto escape;
	} // end scalar write


	decipher_dims(ncid,
			root_group,
			group,
			pvar_root,
			patt_root,
			pvar,
			myrank,
			nproc,
			&deciphered_dims);

	enum ADIOS_FLAG var_exists = adios_flag_yes;
	Func_Timer("inqvar", rc = nc_inq_varid(grp_ids[level], pvar->name, &nc4_varid););
	if (rc == NC_ENOTVAR) {
		var_exists=adios_flag_no;
	} else if (rc != NC_NOERR) {
		fprintf(stderr, "NC4 ERROR checking existence of variable(%s) in write_var, rc=%d\n", pvar->name, rc);
		return_code=-2;
		goto escape;
	}

	if (deciphered_dims.has_timedim == adios_flag_no) {

		/* begin writing array with fixed dimensions */

//		if (myrank==0) printf("\twriting fixed dimension array var!\n");

		if (var_exists == adios_flag_no) {
			for (i=0;i<deciphered_dims.local_dim_count;i++) {
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.nc4_local_dimnames[i], &deciphered_dims.nc4_local_dimids[i]););
				if (rc == NC_EBADDIM) {
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.nc4_local_dimnames[i], deciphered_dims.nc4_localdims[i], &deciphered_dims.nc4_local_dimids[i]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.nc4_local_dimnames[i], rc);
						return_code=-2;
						goto escape;
					}
				} else if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR inquiring about dimension(%s) for array variable(%s) in write_var, rc=%d\n", deciphered_dims.nc4_local_dimnames[i], pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			}
			for (i=0;i<deciphered_dims.global_dim_count;i++) {
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.nc4_global_dimnames[i], &deciphered_dims.nc4_global_dimids[i]););
				if (rc == NC_EBADDIM) {
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.nc4_global_dimnames[i], deciphered_dims.nc4_globaldims[i], &deciphered_dims.nc4_global_dimids[i]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.nc4_global_dimnames[i], rc);
						return_code=-2;
						goto escape;
					}
				} else if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR inquiring about dimension(%s) for array variable(%s) in write_var, rc=%d\n", deciphered_dims.nc4_global_dimnames[i], pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			}
			if (deciphered_dims.has_globaldims == adios_flag_yes) {
				Func_Timer("defvar", rc = nc_def_var(grp_ids[level], pvar->name, nc4_type_id, deciphered_dims.global_dim_count, deciphered_dims.nc4_global_dimids, &nc4_varid););
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR defining array variable(%s) with global dims in write_var, rc=%d\n", pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			} else {
				Func_Timer("defvar", rc = nc_def_var(grp_ids[level], pvar->name, nc4_type_id, deciphered_dims.local_dim_count, deciphered_dims.nc4_local_dimids, &nc4_varid););
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR defining array variable(%s) with local dims in write_var, rc=%d\n", pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			}
			rc = nc_var_par_access(grp_ids[level], nc4_varid, NC_COLLECTIVE);
			if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR setting parallel access for scalar variable(%s) in write_var, rc=%d\n", pvar->name, rc);
				return_code=-2;
				goto escape;
			}


			Func_Timer("inqvar", rc = nc_inq_varid(grp_ids[level], deciphered_dims.gbdims_name, &deciphered_dims.nc4_gbglobaldims_varid););
			if (rc == NC_ENOTVAR) {
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.gbdims_dim0_name, &deciphered_dims.nc4_gbglobaldims_dimids[0]););
				if (rc == NC_EBADDIM) {
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.gbdims_dim0_name, deciphered_dims.nc4_gbglobaldims[0], &deciphered_dims.nc4_gbglobaldims_dimids[0]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_dim0_name, rc);
						return_code=-2;
						goto escape;
					}
				}
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.gbdims_dim1_name, &deciphered_dims.nc4_gbglobaldims_dimids[1]););
				if (rc == NC_EBADDIM) {
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.gbdims_dim1_name, deciphered_dims.nc4_gbglobaldims[1], &deciphered_dims.nc4_gbglobaldims_dimids[1]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_dim1_name, rc);
						return_code=-2;
						goto escape;
					}
				}
				Func_Timer("defvar", rc = nc_def_var(grp_ids[level], deciphered_dims.gbdims_name, NC_UINT64, 2, deciphered_dims.nc4_gbglobaldims_dimids, &deciphered_dims.nc4_gbglobaldims_varid););
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR defining array variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
					return_code=-2;
					goto escape;
				}
				rc = nc_var_par_access(grp_ids[level], deciphered_dims.nc4_gbglobaldims_varid, NC_COLLECTIVE);
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR setting parallel access for scalar variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
					return_code=-2;
					goto escape;
				}
			} else if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR checking existence of variable(%s) in write_var, rc=%d\n", pvar->name, rc);
				return_code=-2;
				goto escape;
			}
		}

//		printf("got varid(%d) for grp_id(%d).variable(%s) in write_attribute, rc=%d\n", nc4_varid, grp_ids[level], pvar->name, rc);
//		printf("sizeof(size_t)==%d\n", sizeof(size_t));

//		Func_Timer("enddef", rc = nc_enddef(grp_ids[level]););
//		if (rc != NC_NOERR) {
//			fprintf(stderr, "NC4 ERROR ending define mode for array variable(%s) in write_var, rc=%d\n", pvar->name, rc);
//			return_code=-2;
//			goto escape;
//		}

		Func_Timer("putvara", rc = nc_put_vara(grp_ids[level], deciphered_dims.nc4_gbglobaldims_varid, deciphered_dims.nc4_gboffsets, deciphered_dims.nc4_gblocaldims, deciphered_dims.nc4_gbdims););
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR putting to array variable(%s) in write_var, rc=%d\n", pvar->name, rc);
			return_code=-2;
			goto escape;
		}
//		Func_Timer("putvars", rc = nc_put_vars(grp_ids[level], nc4_varid, deciphered_dims.nc4_offsets, deciphered_dims.nc4_localdims, deciphered_dims.nc4_strides, pvar->data););
		Func_Timer("putvars", rc = nc_put_vara(grp_ids[level], nc4_varid, deciphered_dims.nc4_offsets, deciphered_dims.nc4_localdims, pvar->data););
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR putting to array variable(%s) in write_var, rc=%d\n", pvar->name, rc);
			return_code=-2;
			goto escape;
		}

		/* end writing array with fixed dimensions */

	} else {

		/* begin writing array with unlimited dimension */

		size_t current_timestep=0;

//		if (myrank==0) printf("\twriting timestep array var!\n");

		if (var_exists == adios_flag_no) {
			/* define the dims and var */
			for (i=0;i<deciphered_dims.global_dim_count;i++) {
//				printf("inq dim name=%s, size=%d\n", deciphered_dims.nc4_global_dimnames[i], deciphered_dims.nc4_globaldims[i]);
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.nc4_global_dimnames[i], &deciphered_dims.nc4_global_dimids[i]););
				if (rc == NC_EBADDIM) {
//					printf("def dim name=%s, size=%d\n", deciphered_dims.nc4_global_dimnames[i], deciphered_dims.nc4_globaldims[i]);
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.nc4_global_dimnames[i], deciphered_dims.nc4_globaldims[i], &deciphered_dims.nc4_global_dimids[i]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.nc4_global_dimnames[i], rc);
						return_code=-2;
						goto escape;
					}
				} else if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR inquiring about dimension(%s) for array variable(%s) in write_var, rc=%d\n", deciphered_dims.nc4_global_dimnames[i], pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			}
			for (i=0;i<deciphered_dims.local_dim_count;i++) {
//				printf("inq dim name=%s, size=%d\n", deciphered_dims.nc4_local_dimnames[i], deciphered_dims.nc4_localdims[i]);
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.nc4_local_dimnames[i], &deciphered_dims.nc4_local_dimids[i]););
				if (rc == NC_EBADDIM) {
//					printf("def dim name=%s, size=%d\n", deciphered_dims.nc4_local_dimnames[i], deciphered_dims.nc4_localdims[i]);
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.nc4_local_dimnames[i], deciphered_dims.nc4_localdims[i], &deciphered_dims.nc4_local_dimids[i]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.nc4_global_dimnames[i], rc);
						return_code=-2;
						goto escape;
					}
				} else if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR inquiring about dimension(%s) for array variable(%s) in write_var, rc=%d\n", deciphered_dims.nc4_global_dimnames[i], pvar->name, rc);
					return_code=-2;
					goto escape;
				}
			}

			Func_Timer("inqvar", rc = nc_inq_varid(grp_ids[level], deciphered_dims.gbdims_name, &deciphered_dims.nc4_gbglobaldims_varid););
			if (rc == NC_ENOTVAR) {
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.gbdims_dim0_name, &deciphered_dims.nc4_gbglobaldims_dimids[0]););
				if (rc == NC_EBADDIM) {
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.gbdims_dim0_name, deciphered_dims.nc4_gbglobaldims[0], &deciphered_dims.nc4_gbglobaldims_dimids[0]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_dim0_name, rc);
						return_code=-2;
						goto escape;
					}
				}
				Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.gbdims_dim1_name, &deciphered_dims.nc4_gbglobaldims_dimids[1]););
				if (rc == NC_EBADDIM) {
					Func_Timer("defdim", rc = nc_def_dim(grp_ids[level], deciphered_dims.gbdims_dim1_name, deciphered_dims.nc4_gbglobaldims[1], &deciphered_dims.nc4_gbglobaldims_dimids[1]););
					if (rc != NC_NOERR) {
						fprintf(stderr, "NC4 ERROR defining array dimension(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_dim1_name, rc);
						return_code=-2;
						goto escape;
					}
				}
				Func_Timer("defvar", rc = nc_def_var(grp_ids[level], deciphered_dims.gbdims_name, NC_UINT64, 2, deciphered_dims.nc4_gbglobaldims_dimids, &deciphered_dims.nc4_gbglobaldims_varid););
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR defining array variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
					return_code=-2;
					goto escape;
				}
				rc = nc_var_par_access(grp_ids[level], deciphered_dims.nc4_gbglobaldims_varid, NC_COLLECTIVE);
				if (rc != NC_NOERR) {
					fprintf(stderr, "NC4 ERROR setting parallel access for scalar variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
					return_code=-2;
					goto escape;
				}
			} else if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR checking existence of variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
				return_code=-2;
				goto escape;
			}

			Func_Timer("defvar", rc = nc_def_var(grp_ids[level], pvar->name, nc4_type_id, deciphered_dims.local_dim_count, deciphered_dims.nc4_global_dimids, &nc4_varid););
			if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR defining array variable(%s) in write_var, rc=%d\n", pvar->name, rc);
				return_code=-2;
				goto escape;
			}
			rc = nc_var_par_access(grp_ids[level], nc4_varid, NC_COLLECTIVE);
			if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR setting parallel access for scalar variable(%s) in write_var, rc=%d\n", pvar->name, rc);
				return_code=-2;
				goto escape;
			}

//			Func_Timer("enddef", rc = nc_enddef(grp_ids[level]););
//			if (rc != NC_NOERR) {
//				fprintf(stderr, "NC4 ERROR ending define mode for array variable(%s) in write_var, rc=%d\n", pvar->name, rc);
//				return_code=-2;
//				goto escape;
//			}
		} else {
			Func_Timer("inqvar", rc = nc_inq_varid(grp_ids[level], deciphered_dims.gbdims_name, &deciphered_dims.nc4_gbglobaldims_varid););
			if (rc == NC_ENOTVAR) {
				fprintf(stderr, "NC4 ERROR variable(%s) does not exist in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
				return_code=-2;
				goto escape;
			} else if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR checking existence of variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
				return_code=-2;
				goto escape;
			}
			rc = nc_var_par_access(grp_ids[level], deciphered_dims.nc4_gbglobaldims_varid, NC_COLLECTIVE);
			if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR setting parallel access for scalar variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
				return_code=-2;
				goto escape;
			}

			Func_Timer("inqdim", rc = nc_inq_dimid(grp_ids[level], deciphered_dims.nc4_local_dimnames[deciphered_dims.timedim_index], &deciphered_dims.nc4_global_dimids[deciphered_dims.timedim_index]););
			if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR inquiring about dimension(%s) for array variable(%s) in write_var, rc=%d\n", deciphered_dims.nc4_local_dimnames[i], pvar->name, rc);
				return_code=-2;
				goto escape;
			}
			/* get the current timestep */
			Func_Timer("inqdimlen", rc = nc_inq_dimlen(grp_ids[level], deciphered_dims.nc4_global_dimids[deciphered_dims.timedim_index], &current_timestep););
			if (rc != NC_NOERR) {
				fprintf(stderr, "NC4 ERROR error getting current timestep for array variable(%s) in write_var, rc=%d\n", pvar->name, rc);
				return_code=-2;
				goto escape;
			}
//			printf("current_timestep==%d\n", current_timestep);
			/* the next timestep goes after the current.  increment timestep. */
			/* THK: don't increment.  dims are 1-based, while offsets are 0-based. */
			// current_timestep++;
		}

		deciphered_dims.nc4_offsets[deciphered_dims.timedim_index]=current_timestep;
		//rc = nc_put_vars(grp_ids[level], nc4_varid, deciphered_dims.nc4_offsets, deciphered_dims.nc4_localdims, deciphered_dims.nc4_strides, pvar->data);
		Func_Timer("putvars", rc = nc_put_vara(grp_ids[level], nc4_varid, deciphered_dims.nc4_offsets, deciphered_dims.nc4_localdims, pvar->data););
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR putting to array variable(%s) in write_var, rc=%d\n", pvar->name, rc);
			return_code=-2;
			goto escape;
		}
		deciphered_dims.nc4_globaldims[deciphered_dims.timedim_index]=current_timestep+1;
		Func_Timer("putvara", rc = nc_put_vara(grp_ids[level], deciphered_dims.nc4_gbglobaldims_varid, deciphered_dims.nc4_gboffsets, deciphered_dims.nc4_gblocaldims, deciphered_dims.nc4_gbdims););
		if (rc != NC_NOERR) {
			fprintf(stderr, "NC4 ERROR putting to array variable(%s) in write_var, rc=%d\n", deciphered_dims.gbdims_name, rc);
			return_code=-2;
			goto escape;
		}

		/* end writing array with unlimited dimension */

	}

escape:
	Func_Timer("close_groups", close_groups(grp_ids, level, adios_flag_yes););

	cleanup_deciphered_dims(&deciphered_dims);

	return return_code;
}

/*
 * Maps bp datatypes to h5 datatypes 
 *
 * The Mapping is according to HDF5 Reference Manual
 * (http://hdf.ncsa.uiuc.edu/HDF5/doc1.6/Datatypes.html)
 */
int getNC4TypeId(enum ADIOS_DATATYPES type, int* nc4_type_id, enum ADIOS_FLAG fortran_flag)
{
	int size, status=0;
	switch (type)
	{
	case adios_byte:
		*nc4_type_id = NC_BYTE;
		break;
	case adios_short:
		*nc4_type_id = NC_SHORT;
		break;
	case adios_integer:
		*nc4_type_id = NC_INT;
		break;
	case adios_long:
		*nc4_type_id = NC_INT64;
		break;
	case adios_string:
		*nc4_type_id = NC_CHAR;
		break;
	case adios_real:
		*nc4_type_id = NC_FLOAT;
		break;
	case adios_double:
		*nc4_type_id = NC_DOUBLE;
		break;
	case adios_long_double:
		fprintf(stderr, "ERROR in mapping ADIOS Data Types to NC4: long double not supported yet.\n");
		status = -1;
		break;
	case adios_complex:
	case adios_double_complex:
		fprintf(stderr, "ERROR in mapping ADIOS Data Types to NC4: complex not supported yet.\n");
		status = -1;
		break;
	case adios_unsigned_byte:
		*nc4_type_id = NC_UBYTE;
		break;
	case adios_unsigned_short:
		*nc4_type_id = NC_USHORT;
		break;
	case adios_unsigned_integer:
		*nc4_type_id = NC_UINT;
		break;
	case adios_unsigned_long:
		*nc4_type_id = NC_UINT64;
		break;
	default:
		status = -1;
		break;
	}
	return status;
}

int getTypeSize(enum ADIOS_DATATYPES type, void *val)
{

	switch (type)
	{
	case adios_byte:
		return 1;

	case adios_string:
		return strlen ((char *) val);

	case adios_short:
	case adios_unsigned_short:
		return 2;

	case adios_integer:
	case adios_unsigned_integer:
	case adios_long:
	case adios_unsigned_long:
		return 4;

	case adios_real:
		return 4;

	case adios_double:
		return 8;

	case adios_long_double:
		return 16;

	case adios_complex:
		return 2 * 4;

	case adios_double_complex:
		return 2 * 8;

	default:
		return -1;
	}
}

// close group/dataset
// adios_flag_yes      group
// adios_flag_no       dataset

void close_groups(int *grp_id, int level, enum ADIOS_FLAG flag)
{
	//     int i;
	//     if (flag == adios_flag_unknown) {
	//         fprintf (stderr, "Unknown flag in hw_gclose!\n");
	//         return;
	//     }
	//     for ( i = 1; i <= level; i++) {
	//         if (i == level && flag == adios_flag_no)
	//             H5Dclose(grp_id[i]);
	//         else
	//             H5Gclose(grp_id[i]);
	//
	//     }
}

// open group/dataset
// adios_flag_yes      group
// adios_flag_no       dataset
// adios_flag_unknown 

void open_groups(int root_group,
		char *path,
		int *grp_id,
		int *level,
		char **last,
		enum ADIOS_FLAG open_for_attr,
		enum ADIOS_FLAG flag)
{
	if (flag == adios_flag_unknown) {
		fprintf (stderr, "Unknown flag in open_groups!\n");
		return;
	}
	int rc=0;
	int i, idx = 0, len = 0;
	char * pch, ** grp_name, * tmpstr;

//	printf("group_path==%s\n", path);

	len=strlen(path);
	if (path[len-1] == '/') {
		path[len-1]='\0';
	}
	tmpstr= (char *)malloc(strlen(path)+1);
	strcpy (tmpstr, path);
	pch = strtok(tmpstr,"/");
	grp_name = (char **) malloc(NUM_GP);
	while ( pch!=NULL && *pch!=' ') {
		len = strlen(pch);
		grp_name[idx]  = (char *)malloc(len+1);
		grp_name[idx][0]='\0';
		strcat(grp_name[idx],pch);
		*last = path+(pch-tmpstr);
		pch=strtok(NULL,"/");
		idx=idx+1;
	}
	*level = idx;
	if (open_for_attr == adios_flag_yes) {
		*level = idx-1;
	} else {
		*level = idx;
	}
	grp_id[0] = root_group;
	for ( i = 0; i < *level; i++) {
//		printf("idx==%d, level==%d\n", idx, *level);
		rc = nc_inq_ncid(grp_id[i], grp_name[i], &(grp_id[i+1]));
		if (rc == NC_ENOGRP) {
//			printf("defining grp_name[%d]==%s\n", i, grp_name[i]);
			rc = nc_def_grp(grp_id[i], grp_name[i], &(grp_id[i+1]));
//			printf("defined grp_name[%d]==%s with grp_id==%d\n", i, grp_name[i], grp_id[i+1]);
			if (rc != NC_NOERR) {
				if (rc == NC_ENAMEINUSE) {
					fprintf(stdout, "group exists.  how did this happen?  nc_inq_ncid failed. rc=%d\n", rc);
				} else {
					fprintf (stderr, "NC4 ERROR: create group %s failed! rc=%d\n", grp_name[i], rc);
					return;
				}
			}
		} else if (rc != NC_NOERR) {
			fprintf (stderr, "NC4 ERROR: group lookup(%s) failed! rc=%d\n", grp_name[i], rc);
		}
//		printf("found grp_name[%d]==%s with grp_id==%d\n", i, grp_name[i], grp_id[i+1]);
	}
	for ( i = 0; i < idx; i++)
		if ( grp_name[i])
			free (grp_name[i]);
	free (grp_name);
	free (tmpstr);
}
void populate_dimension_size(struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_dimension_item_struct *dim,
		size_t dimsize)
{
	struct adios_var_struct *var_linked = NULL;
	struct adios_attribute_struct *attr_linked;
	if (dim->id) {
		var_linked = adios_find_var_by_id (pvar_root , dim->id);
		if (!var_linked) {
			attr_linked = adios_find_attribute_by_id (patt_root, dim->id);
			if (!attr_linked->var) {
				switch (attr_linked->type) {
				case adios_unsigned_byte:
					*(uint8_t *)attr_linked->value = dimsize;
					break;
				case adios_byte:
					*(int8_t *)attr_linked->value = dimsize;
					break;
				case adios_unsigned_short:
					*(uint16_t *)attr_linked->value = dimsize;
					break;
				case adios_short:
					*(int16_t *)attr_linked->value = dimsize;
					break;
				case adios_unsigned_integer:
					*(uint32_t *)attr_linked->value = dimsize;
					break;
				case adios_integer:
					*(int32_t *)attr_linked->value = dimsize;
					break;
				case adios_unsigned_long:
					*(uint64_t *)attr_linked->value = dimsize;
					break;
				case adios_long:
					*(int64_t *)attr_linked->value = dimsize;
					break;
				default:
					fprintf (stderr, "Invalid datatype for array dimension on "
							"var %s: %s\n"
							,attr_linked->name
							,adios_type_to_string_int(var_linked->type)
					);
					break;
				}
			} else {
				var_linked = attr_linked->var;
			}
		}
		if (var_linked && var_linked->data) {
			*(int *)var_linked->data = dimsize;
		}
	} else {
		if (dim->time_index == adios_flag_yes) {
//			dimsize = NC_UNLIMITED;
//			dimsize = 1;
		} else {
			dim->rank = dimsize;
		}
	}

	return;
}
void parse_dimension_size(struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_dimension_item_struct *dim,
		size_t *dimsize)
{
	struct adios_var_struct *var_linked = NULL;
	struct adios_attribute_struct *attr_linked;
	if (dim->id) {
		var_linked = adios_find_var_by_id (pvar_root , dim->id);
		if (!var_linked) {
			attr_linked = adios_find_attribute_by_id (patt_root, dim->id);
			if (!attr_linked->var) {
				switch (attr_linked->type) {
				case adios_unsigned_byte:
					*dimsize = *(uint8_t *)attr_linked->value;
					break;
				case adios_byte:
					*dimsize = *(int8_t *)attr_linked->value;
					break;
				case adios_unsigned_short:
					*dimsize = *(uint16_t *)attr_linked->value;
					break;
				case adios_short:
					*dimsize = *(int16_t *)attr_linked->value;
					break;
				case adios_unsigned_integer:
					*dimsize = *(uint32_t *)attr_linked->value;
					break;
				case adios_integer:
					*dimsize = *(int32_t *)attr_linked->value;
					break;
				case adios_unsigned_long:
					*dimsize = *(uint64_t *)attr_linked->value;
					break;
				case adios_long:
					*dimsize = *(int64_t *)attr_linked->value;
					break;
				default:
					fprintf (stderr, "Invalid datatype for array dimension on "
							"var %s: %s\n"
							,attr_linked->name
							,adios_type_to_string_int (var_linked->type)
					);
					break;
				}
			} else {
				var_linked = attr_linked->var;
			}
		}
		if (var_linked && var_linked->data) {
			*dimsize = *(int *)var_linked->data;
		}
	} else {
		if (dim->time_index == adios_flag_yes) {
			*dimsize = NC_UNLIMITED;
			*dimsize = 1;
		} else {
			*dimsize = dim->rank;
		}
	}

	return;
}
void parse_dimension_name(struct adios_group_struct *group,
		struct adios_var_struct *pvar_root,
		struct adios_attribute_struct *patt_root,
		struct adios_dimension_item_struct *dim,
		nc4_dimname_t dimname)
{
	struct adios_var_struct *var_linked = NULL;
	struct adios_attribute_struct *attr_linked;
	if (dim->id) {
		var_linked = adios_find_var_by_id (pvar_root , dim->id);
		if (!var_linked) {
			attr_linked = adios_find_attribute_by_id (patt_root, dim->id);
			if (!attr_linked->var) {
//				strcpy(dimname, attr_linked->name);
				sprintf(dimname, "%s_dim", attr_linked->name);
			} else {
				var_linked = attr_linked->var;
			}
		}
		if (var_linked && var_linked->name) {
//			strcpy(dimname, var_linked->name);
			sprintf(dimname, "%s_dim", var_linked->name);
		}
	} else {
		if (dim->time_index == adios_flag_yes) {
//			strcpy(dimname, group->time_index_name);
			sprintf(dimname, "%s_dim", group->time_index_name);
		} else {
			dimname[0] = '\0';
		}
	}

	return;
}
#endif
