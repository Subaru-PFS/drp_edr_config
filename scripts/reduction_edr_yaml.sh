#!/usr/bin/env bash

usage() {
    echo "Process the EDR data with yaml file" 1>&2
    echo "" 1>&2
    echo "Usage: $0 [-c CORES] [-R] [-M] [-F] [-A] [-D] PIPE2D_VERSION  RERUN  BLOCKS" 1>&2
    echo "" 1>&2
    echo "    -c <CORES> : number of cores to use (default: ${CORES})" 1>&2
    echo "    -d : dry run (just make a script)" 1>&2
    echo "    -R : skip reduceExposure process" 1>&2
    echo "    -M : skip mergeArms process" 1>&2
    echo "    -F : skip fluxCalibration process" 1>&2
    echo "    -A : skip coaddSpectra process" 1>&2
    echo "    -D : developer mode (--clobber-config --no-versions)" 1>&2
    echo "    -y : YAML file for configuration" 1>&2
    echo "    PIPE2D_VERSION : version of PIPE2D (e.g., w.2023.25)" 1>&2
    echo "    DATE_PROCESS : date of the processing (e.g., 20230601)" 1>&2
    echo "    RERUN : rerun mame (e.g., edr2-20230601)" 1>&2
    echo "    BLOCKS : block name(s) in yaml file to process (e.g., ge_run11 or ge_run11,ge_run08,co_run11 etc.)" 1>&2

    echo "" 1>&2
    exit 1
}


REPO=/work/drp
CALIB=$REPO/CALIB
YAML=process_all.yaml
WORKDIR=/work/pfs/reduction/process/run12
OUTDIR=$WORKDIR/scripts
LOGDIR=$WORKDIR/logs
mkdir -p $OUTDIR
mkdir -p $LOGDIR

CORES=24
SKIP_REDUCE=false
SKIP_MERGE=false
SKIP_FLUXCAL=false
SKIP_COADD=false
DEVELOPER=false
DRY_RUN=false
while getopts "c:dRMFADy:" opt; do
    case "${opt}" in
        c)
            CORES=${OPTARG}
            ;;
        d)
            DRY_RUN=true
            ;;
	R)
	    SKIP_REDUCE=true
	    ;;
	M)
            SKIP_MERGE=true
            ;;
        F)
	    SKIP_FLUXCAL=true
            ;;
	A)
            SKIP_COADD=true
            ;;
        D)
            DEVELOPER=true
            ;;
        y)
            YAML=${OPTARG}
            ;;
        h | *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


if [ $# != 4 ];then
    echo "too many arguments"
    exit 1
fi

PIPE2D_VERSION=$1
DATE_PROCESS=$2
RERUN=$3
BLOCKS=$4

setup -v pfs_pipe2d $PIPE2D_VERSION
setup -jr /work/pfs/reduction/fluxCal/fluxmodeldata-ambre-20230608-small

export OMP_NUM_THREADS=1

OUTFILE="reduction_edr_yaml.${PIPE2D_VERSION}.${DATE_PROCESS}.sh"
LOGFILE="reduction_edr_yaml.${PIPE2D_VERSION}.${DATE_PROCESS}.log"

develFlag=""
if [ "$DEVELOPER" = true ]; then
    develFlag="--devel"
fi

scienceSteps=""
if [ "$SKIP_REDUCE" = false ]; then
    scienceSteps+="reduceExposure"
fi
if [ "$SKIP_MERGE" = false ]; then
    scienceSteps+=" mergeArms"
fi
if [ "$SKIP_FLUXCAL" = false ]; then
    scienceSteps+=" calculateReferenceFlux fluxCalibrate"
fi
if [ "$SKIP_COADD" = false ]; then
    scienceSteps+=" coaddSpectra"
fi

BLOCK=`echo ${BLOCKS//,/\ }`

## generate commands ##
generateCommands.py $REPO \
    configs/$YAML \
    $OUTDIR/$OUTFILE \
    --rerun=$RERUN \
    --blocks $BLOCK \
    --scienceSteps $scienceSteps \
    -j $CORES $develFlag \
    2>&1 | tee $LOGDIR/$LOGFILE

## tempral workaround for the flux calibration commands etc. ##
sed -i -e "s/calculateReferenceFlux/fitPfsFluxReference/g" $OUTDIR/$OUTFILE
sed -i -e "s/fluxCalibrate/fitFluxCal/g" $OUTDIR/$OUTFILE
sed -i -e "s/\/pipeline//g" $OUTDIR/$OUTFILE
sed -i -e "s/--doraise/--doraise --longlog 1/g" $OUTDIR/$OUTFILE

## run the script ##
if [ "$DRY_RUN" != true ]; then
    sh $OUTDIR/$OUTFILE 2>&1 | tee $LOGDIR/$LOGFILE
else
    echo "DRY RUN"
fi

