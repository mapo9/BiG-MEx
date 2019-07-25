#!/bin/bash -l

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf

###############################################################################
# 2. Set parameters
###############################################################################

while :; do
  case "${1}" in
#############
  --env)
  if [[ -n "${2}" ]]; then
    ENV="${2}"
    shift
  fi
  ;;
  --env=?*)
  ENV="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --env=) # Handle the empty case
  printf "ERROR: --env requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  --)              # End of all options.
  shift
  break
  ;;
  -?*)
  printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
  ;;
  *) # Default case: If no more options then break out of the loop.
  break
  esac
  shift
done

###############################################################################
# 3. Load env
###############################################################################

source "${ENV}"

###############################################################################
# 4. Collapse table
###############################################################################

awk 'BEGIN {OFS="\t"}; {

  cluster = $1;
  id = $2;
  array_cluster2abund[cluster] = array_cluster2abund[cluster] + $3;
  
  if ( array_cluster2id[cluster] == ""  ) {
    array_cluster2id[cluster] = id;
    sample_array[cluster] = $4
  }
  
} END {
  for (c in array_cluster2abund) {
    printf "%s\t%s\t%s\t%s\n",  \
    c,array_cluster2id[c],array_cluster2abund[c],sample_array[c]
  }
}' "${TMP_NAME}_concat_cluster2abund.tsv" > \
   "${TMP_NAME}_onlyrep_cluster2abund.tsv"

###############################################################################
# 5. Extract repseqs
###############################################################################

cut -f2 "${TMP_NAME}_onlyrep_cluster2abund.tsv" | \
sed "s/_repseq$//" > "${TMP_NAME}.onlyrep_headers"

"${filterbyname}" \
in="${TMP_NAME}_all.faa" \
out="${TMP_NAME}_onlyrep_subseqs.faa" \
names="${TMP_NAME}.onlyrep_headers" \
include=t \
overwrite=t
