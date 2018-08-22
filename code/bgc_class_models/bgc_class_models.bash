#!/bin/bash -l

#set -x
set -o pipefail

#############################################################################
# 1. Load general configuration
#############################################################################

source /bioinfo/software/conf

#############################################################################
# 2. set parameters
#############################################################################

show_usage(){
  cat <<EOF
  Usage: run_bgc_class_models.bash <input file> <input models> <output directory> <options>
  
  [-h|--help] [-nc|--no-convert t|f] [-v|--verbose t|f] [-w|--overwrite t|f] 
 
-h, --help	print this help
-c,--convert2relative	t or f, convert prfile to relative counts (default f)
-v,--verbose	t or f, run verbosely (default f)
-w, --overwrite	t or f, overwrite current directory (default f)
EOF
}

##############################################################################
## 3. parse parameters #######################################################
##############################################################################

while :; do
  case "${1}" in

    -h|-\?|--help) # Call a "show_help" function to display a synopsis, then
                   # exit.
    show_usage
    exit 1;
    ;;
#############
  -b|--bgc_models)
  if [[ -n "${2}" ]]; then
   BGC_MODELS="${2}"
   shift
  fi
  ;;
  --bgc_models=?*)
  BGC_MODELS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --bgc_models=) # Handle the empty case
  printf "ERROR: --bgc_models requires a non-empty option argument.\n"  >&2
  exit 1
  ;;

#############
 -c| --convert2relative)
   if [[ -n "${2}" ]]; then
     CONVERT2RELATIVE="${2}"
     shift
   fi
  ;;
  --convert2relative=?*)
  CONVERT2RELATIVE="${1#*=}" # Delete everything up to "=" and assign the
# remainder.
  ;;
  --convert2relative=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  -i|--input)
  if [[ -n "${2}" ]]; then
   INPUT_FILE="${2}"
   shift
  fi
  ;;
  --input=?*)
  INTPUT_FILE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input=) # Handle the empty case
  printf "ERROR: --input requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -o|--outdir)
   if [[ -n "${2}" ]]; then
     OUTDIR_EXPORT="${2}"
     shift
   fi
  ;;
  --outdir=?*)
  OUTDIR_EXPORT="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --outdir=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
-v|--verbose)
   if [[ -n "${2}" ]]; then
     VERBOSE="${2}"
     shift
   fi
  ;;
  --verbose=?*)
  VERBOSE="${1#*=}" # Delete everything up to "=" and assign the
# remainder.
  ;;
  --verbose=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############  
  -w|--overwrite)
   if [[ -n "${2}" ]]; then
     OVERWRITE="${2}"
     shift
   fi
  ;;
  --overwrite=?*)
  OVERWRITE="${1#*=}" # Delete everything up to "=" and assign the
# remainder.
  ;;
  --overwrite=) # Handle the empty case
  printf 'Using default environment.\n' >&2
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

#############################################################################
# 4. Define variables
#############################################################################

if [[ "${VERBOSE}" == "t" ]]; then
  function handleoutput {
    cat /dev/stdin | \
    while read STDIN; do 
      echo "${STDIN}"
    done  
  }
else
  function handleoutput {
  cat /dev/stdin >/dev/null
}
fi

#############################################################################
# 5. Check output directories
#############################################################################

if [[ -d "${OUTDIR_LOCAL}/${OUTDIR_EXPORT}" ]]; then
  if [[ "${OVERWRITE}" != "t" ]]; then
    echo "${OUTDIR_EXPORT} already exist. Use \"--overwrite t\" to overwrite."
    exit
  fi
fi  

#############################################################################
# 6. Create output directories
#############################################################################

THIS_JOB_TMP_DIR="${SCRATCH}/${OUTDIR_EXPORT}"

if [[ ! -d "${THIS_JOB_TMP_DIR}" ]]; then
  mkdir -p "${THIS_JOB_TMP_DIR}"
fi

THIS_OUTPUT_TMP_FILE="${THIS_JOB_TMP_DIR}/bgc_class_pred.tsv"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/bgc_class_pred.pdf"

#############################################################################
# 7. Predict BGC class abundance
#############################################################################
(
"${r_interpreter}" --vanilla --slave <<RSCRIPT
 
  options(warn=-1)
  library(bgcpred, quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
  options(warn=0)
  
  COUNTS <- read.table(file="${INPUT_FILE}", sep = "\t", header = F)
  colnames(COUNTS) <- c("sample","domain","abund")
  
  COUNTS_wide <- COUNTS %>% 
                 select( sample, domain, abund) %>% 
		 spread(data = ., key = domain, value = abund, fill= 0)

  COUNTS_wide <- COUNTS_wide %>% 
                 droplevels %>% 
		 arrange(sample) %>%
		 as.data.frame	%>%
		 remove_rownames() %>%
		 column_to_rownames(., var = "sample")
 
  if ( "${BGC_MODELS}" != "" ) {
    bgc_models_current <- get(load("${BGC_MODELS}"))
    PRED <- wrap_up_predict(x = COUNTS_wide, m = bgc_models_current)
  } else {
    PRED <- wrap_up_predict(x = COUNTS_wide)
  }

  if ( "${CONVERT2RELATIVE}" == "t" ) {
    PRED <- PRED/rowSums(PRED)
  }

  
  write.table(file = "${THIS_OUTPUT_TMP_FILE}", PRED, 
              sep = "\t", quote = F, col.names = NA)
  
  PRED_long <- PRED %>% gather(key = "bgc_class","value")
  pdf(file = "${THIS_OUTPUT_TMP_IMAGE}", width=8, height=4 )
  p <- ggplot(PRED_long, aes(x = bgc_class, y = value, fill = bgc_class)) +
              geom_bar(stat="identity") +
              xlab("BGC class") +
              ylab("Model prediction") +
              theme_light() +
              scale_fill_hue(c=70, l=40,h.start = 200,direction = -1) +
              theme(axis.text.y = element_text(size = 10, color = "black"), 
                    axis.text.x =  element_text(size = 10, color = "black", angle = 45, 
	            hjust = 1 ),
               axis.title.x = element_text(size = 12, color = "black", margin = 
	                                   unit(c(5, 0, 0, 0),"mm") ),
               axis.title.y = element_text(size = 12, color = "black", margin = 
                                          unit(c(0, 5, 0, 0),"mm") ) ) +
               scale_x_discrete(position = "bottom") +
               guides(fill=FALSE)
    
    if ( "${CONVERT2RELATIVE}" == "t" ) {
       
      p <- p + scale_y_continuous(labels = scales::percent)
       
    }
    
    p
    
   dev.off()

RSCRIPT

) 2>&1 | handleoutput

EXIT_CODE="$?"

if [[ "${EXIT_CODE}" != 0 ]]; then
  echo "prediction failed"
  exit 1
fi

#############################################################################
# 8. Move output for export
#############################################################################

rsync -a --delete "${THIS_JOB_TMP_DIR}" "${OUTDIR_LOCAL}"
