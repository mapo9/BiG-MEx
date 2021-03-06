#!/bin/bash

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf
# source /home/memo/workspace/BiG-MEx/bgc_dom_merge_div/resources/conf_local

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
  --input)
  if [[ -n "${2}" ]]; then
    INPUT="${2}"
    shift
  fi
  ;;
  --input=?*)
  INPUT="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input=) # Handle the empty case
  printf "ERROR: --input requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
############
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
# 4. Define input and output variables
###############################################################################

REF_ALIGN="${REF_PKG_DIR}/${DOMAIN}.refpkg/${DOMAIN}_core.align"
REF_PKG="${REF_PKG_DIR}/${DOMAIN}.refpkg"
OUT_DIR="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data"

mkdir "${OUT_DIR}"

###############################################################################
# 5. Clean fasta file
###############################################################################

tr "[ -%,;\(\):=\.\\\*[]\"\']" "_" < "${INPUT}" > "${OUT_DIR}/query_clean.fasta"

###############################################################################
# 6. Add sequences to profile
###############################################################################

unset MAFFT_BINARIES

"${mafft}" \
--add "${OUT_DIR}/query_clean.fasta" \
--reorder \
"${REF_ALIGN}" > "${OUT_DIR}/ref_added_query.align.fasta"

# "${famsa}" \
# -t "${NSLOTS}" \
# "${REF_ALIGN}" "${OUT_DIR}/ref_added_query.align.fasta"

###############################################################################
# 7. Place sequences onto tree
###############################################################################

"${pplacer}" \
-o "${OUT_DIR}/${DOMAIN}_query.jplace" \
-p \
--keep-at-most 10 \
--discard-nonoverlapped \
-c "${REF_PKG}" \
"${OUT_DIR}/ref_added_query.align.fasta"

###############################################################################
# 8. Visualize tree
###############################################################################

"${guppy}" fat \
--node-numbers \
--point-mass \
--pp \
-o "${OUT_DIR}/${DOMAIN}_query.phyloxml" \
   "${OUT_DIR}/${DOMAIN}_query.jplace"

"${guppy}" tog \
--node-numbers \
--pp \
--out-dir "${OUT_DIR}" \
-o "${DOMAIN}_query.newick" \
"${OUT_DIR}/${DOMAIN}_query.jplace"

###############################################################################
# 9. Compute stats
###############################################################################  

"${guppy}" to_csv \
--point-mass \
--pp \
-o "${OUT_DIR}/${DOMAIN}_query_info.csv" \
"${OUT_DIR}/${DOMAIN}_query.jplace"

###############################################################################
# 10. Compute edpl
###############################################################################
  
"${guppy}" edpl \
--csv \
--pp \
-o "${OUT_DIR}/${DOMAIN}_query_edpl.csv" \
"${OUT_DIR}/${DOMAIN}_query.jplace"

###############################################################################
# 11. Left join tables: info and edpl
###############################################################################

awk 'BEGIN {FS=","; OFS="," } { 
  if (NR==FNR) {

    array_edpl[$1]=$2;
    next;
  }

  if ( FNR == 1) {
  
    print $0,"edpl"
  
  } else {
  
    if (array_edpl[$2] != "" ) {
    
      print $0,array_edpl[$2];
      
    }
  }
}' "${OUT_DIR}/${DOMAIN}_query_edpl.csv" "${OUT_DIR}/${DOMAIN}_query_info.csv" \
> "${OUT_DIR}/${DOMAIN}_tmp.csv"

###############################################################################
# 12. Clean
###############################################################################

mv "${OUT_DIR}/${DOMAIN}_tmp.csv" "${OUT_DIR}/${DOMAIN}_query_info.csv"
rm "${OUT_DIR}/${DOMAIN}_query_edpl.csv"


