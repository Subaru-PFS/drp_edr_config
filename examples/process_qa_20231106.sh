#!/usr/bin/env bash

DATE_PROCESS=20231106
PIPE2D_VERSION="edr2-20231106"

CALIB="CALIB"
RERUN="pfs/internal/${PIPE2D_VERSION}-qa"

## EDR2 science data ##
#./scripts/reduction_edr_yaml.sh -M -F -A -c 16 -C $CALIB -y process_all.yaml $PIPE2D_VERSION $DATE_PROCESS $RERUN test
./scripts/reduction_edr_yaml.sh -M -F -A -c 32 -C $CALIB -y process_all.yaml $PIPE2D_VERSION $DATE_PROCESS $RERUN run12,run11,run08
./scripts/reduction_edr_yaml.sh -M -F -A -c 32 -C $CALIB -y process_all.yaml $PIPE2D_VERSION $DATE_PROCESS $RERUN run12_nofcal,run11_nofcal,run08_nofcal

## modify pfsConfig for all-sky designs and reprocess ##
setup -v pfs_pipe2d $PIPE2D_VERSION
./scripts/modify_pfsConfig_allsky_run12.py --release "${PIPE2D_VERSION}-qa" --calib $CALIB
./scripts/modify_pfsConfig_allsky_run11.py --release "${PIPE2D_VERSION}-qa" --calib $CALIB
./scripts/modify_pfsConfig_allsky_run08.py --release "${PIPE2D_VERSION}-qa" --calib $CALIB
./scripts/reduction_edr_yaml.sh -a -M -F -A -c 32 -y process_all.yaml $PIPE2D_VERSION $DATE_PROCESS $RERUN sky_run12,sky_run11,sky_run08

## change name of logfile ##
mv "logs/reduction_edr_yaml.${PIPE2D_VERSION}.${DATE_PROCESS}.log" "logs/reduction_edr_yaml.edr2-qa-${PIPE2D_VERSION}-${CALIB}-$DATE_PROCESS.log"

## EDR2 calibration data ##
#./scripts/reduction_edr_yaml.sh -M -F -A -D -c 16 -C $CALIB -y process_all.yaml $PIPE2D_VERSION $DATE_PROCESS $RERUN test
./scripts/reduction_edr_yaml.sh -M -F -A -c 32 -C $CALIB -y process_all.yaml $PIPE2D_VERSION $DATE_PROCESS $RERUN arcs_run12,traces_run12,twilight_run12

## change name of logfile ##
mv "logs/reduction_edr_yaml.${PIPE2D_VERSION}.${DATE_PROCESS}.log" "logs/reduction_edr_yaml.edr2-qa-calibs-${PIPE2D_VERSION}-${CALIB}-$DATE_PROCESS.log"

