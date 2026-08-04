#!/bin/bash

# fix dts
sed -i 's/subdir-y\s*:=\s*\$(dts-dirs)/subdir-y        += galaxytab\/gts9wifi/' kernel_platform/msm-kernel/arch/arm64/boot/dts/samsung/Makefile

# remove ro
find device/qcom/gki-kernel -type f ! -writable -exec chmod u+w {} +

# clean out previous
rm -rf out

# rebuild but pipe log to file
./build_kernel_GKI.sh 2>&1 | tee buildlog.log
