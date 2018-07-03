#!/bin/bash
# Patch the kernel for the Intel Realsense library librealsense on a Jetson TX Development Kit
# Copyright (c) 2016-18 Jetsonhacks
# MIT License

# Error out if something goes wrong
set -e

CLEANUP=false

function usage
{
    echo "usage: ./buildPatchedKernel.sh [[-c cleanup ] | [-h]]"
    echo "-c | --cleanup   Do not remove kernel and module sources after build"
    echo "-h | --help  This message"
}

# Iterate through command line inputs
while [ "$1" != "" ]; do
    case $1 in
        -c | --cleanup )        CLEANUP=true
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done



BUILD_LIBREALSENSE_DIR=$PWD
# Is this the correct kernel version?
source scripts/jetson_variables.sh
#Print Jetson version
echo "$JETSON_DESCRIPTION"
#Print Jetpack version
echo "Jetpack $JETSON_JETPACK [L4T $JETSON_L4T]"

# Check to make sure we're installing the correct kernel sources
L4TTarget="28.2"
if [ $JETSON_L4T != $L4TTarget ] ; then
   echo ""
   tput setaf 1
   echo "==== L4T Kernel Version Mismatch! ============="
   tput sgr0
   echo ""
   echo "This repository is for modifying the kernel for L4T "$L4TTarget "system."
   echo "You are attempting to modify a L4T "$JETSON_L4T "system."
   echo "The L4T releases must match!"
   echo ""
   echo "There may be versions in the tag/release sections that meet your needs"
   echo ""
   exit 1
fi

# Is librealsense on the device?
LIBREALSENSE_DIRECTORY=${HOME}/repositories/librealsense
LIBREALSENSE_VERSION=v2.13.0

if [ ! -d "$LIBREALSENSE_DIRECTORY" ] ; then
   echo "The librealsense repository directory is not available"
   read -p "Would you like to git clone librealsense? (y/n) " answer
   case ${answer:0:1} in
     y|Y )
         # install librealsense
         ./installLibrealsense.sh
         echo "${green}Cloning librealsense${reset}"
     ;;
     * )
         echo "Kernel patch and build not started"
         exit 1
     ;;
   esac
fi

# Is the version of librealsense current enough?
cd $LIBREALSENSE_DIRECTORY
VERSION_TAG=$(git tag -l $LIBREALSENSE_VERSION)
if [ ! $VERSION_TAG  ] ; then
   echo ""
  tput setaf 1
  echo "==== librealsense Version Mismatch! ============="
  tput sgr0
  echo ""
  echo "The installed version of librealsense is not current enough for these scripts."
  echo "This script needs librealsense tag version: "$LIBREALSENSE_VERSION "but it is not available."
  echo "This script uses patches from librealsense on the kernel source."
  echo "Please upgrade librealsense before attempting to patch and build the kernel again."
  echo ""
  exit 1
fi

KERNEL_BUILD_DIR=${HOME}/repositories/buildJetsonTX2Kernel
if [ ! -d "$KERNEL_BUILD_DIR" ] ; then
   echo "The jetsonhacks kernel build repository directory is not available in "$KERNEL_BUILD_DIR
   read -p "Would you like to git clone buildJetsonTX2Kernel? (y/n) " answer
   case ${answer:0:1} in
     y|Y )
         echo "${green}Cloning buildJetsonTX2Kernel${reset}"
         cd ${HOME}/repositories
         git clone https://github.com/rapyuta-robotics/buildJetsonTX2Kernel.git
     ;;
     * )
         echo "Kernel patch and build not started"
         exit 1
     ;;
   esac
fi

# Checkout the correct branch for kernel building
cd $KERNEL_BUILD_DIR
git checkout 28.2.1
echo "Ready to patch and build kernel "$JETSON_BOARD

# Get the kernel sources; does not open up editor on .config file
echo "${green}Getting Kernel sources${reset}"
cd $KERNEL_BUILD_DIR
./getKernelSourcesNoGUI.sh

echo "${green}Patching and configuring kernel${reset}"
cd $BUILD_LIBREALSENSE_DIR
sudo ./scripts/configureKernel.sh
sudo ./scripts/patchKernel.sh

cd $KERNEL_BUILD_DIR
# Apply custom kernel patches
echo "${green}Apply custom kernel patches${reset}"
sudo ./applyCustomKernelPatch.sh

# Make the new Image and build the modules
echo "${green}Building Kernel and Modules${reset}"
./makeKernel.sh

# Now copy over the built image
echo "Do you wish to copy the image to boot and overwrite the existing image? This action is not reversible."
select yn in "Y" "N"; do
    case $yn in
        y|Y )./copyImage.sh; break;;
        * ) break;;
    esac
done

# Remove buildJetson Kernel scripts
if [ $CLEANUP == true ]
then
  echo "Do you want to remove kernel build sources?"
  select yn in "Y" "N"; do
    case $yn in
        y|Y )./removeAllKernelSources.sh; break;;
        * ) break;;
    esac
  done
else
  echo "Kernel sources are in /usr/src"
fi

echo "Please reboot for changes to take effect"

