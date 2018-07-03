#!/bin/bash
# Install the Intel Realsense library kernel patches on a NVIDIA Jetson TX Development Kit
# Jetson TX1, Jetson TX2
# Copyright (c) 2016-18 Jetsonhacks
# MIT License

LIBREALSENSE_DIR=${HOME}/repositories/librealsense
kernel_branch="master"
echo "kernel branch" $kernel_branch

# For L4T 28.2 the kernel is 4.4.38 hence kernel-4.4
cd /usr/src/kernel/kernel-4.4


# Patching kernel for RealSense devices
echo -e "\e[32mApplying realsense-uvc patch\e[0m"
patch -p1 < ${LIBREALSENSE_DIR}/scripts/realsense-camera-formats_ubuntu-xenial-${kernel_branch}.patch
echo -e "\e[32mApplying realsense-metadata patch\e[0m"
patch -p1 < ${LIBREALSENSE_DIR}/scripts/realsense-metadata-ubuntu-xenial-${kernel_branch}.patch
echo -e "\e[32mApplying realsense-hid patch\e[0m"
patch -p1 < ${LIBREALSENSE_DIR}/scripts/realsense-hid-ubuntu-xenial-${kernel_branch}.patch
patch -p1 < ${LIBREALSENSE_DIR}/scripts/realsense-powerlinefrequency-control-fix.patch


