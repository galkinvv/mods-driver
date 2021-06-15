#!/bin/sh
# * install_module.sh - This file is part of NVIDIA MODS kernel driver.
# *
# * Copyright 2008-2016 NVIDIA Corporation.
# *
# * NVIDIA MODS kernel driver is free software: you can redistribute it and/or
# * modify
# * it under the terms of the GNU General Public License,
# * version 2, as published by the Free Software Foundation.
# *
# * NVIDIA MODS kernel driver is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# * GNU General Public License for more details.
# *
# * You should have received a copy of the GNU General Public License
# * along with NVIDIA MODS kernel driver.  If not, see
# * <http://www.gnu.org/licenses/>.

SELF=`dirname "$0"`
SELF_DIR=`readlink -f "$SELF"`
cd "$SELF_DIR"

MODULE_NAME="mods"
KERN_VERSION=`uname -r`
MODULE_DIR="../_ab_driver-local_builds/${KERN_VERSION}/"
INSMOD="/sbin/insmod"
RMMOD="/sbin/rmmod"
MODPROBE="/sbin/modprobe"
MODULELIST="/proc/modules"

die() {
    echo -e "$@"
    exit 1
}

checkuser() {
    # Check if we are running with root privileges
    [ `id -u` -eq 0 ] || die "The `basename $0` script must be run with root privileges" 
}

isloaded() {
    # Ensure that we only return is loaded for an exact match (via end of word indicator)
    # Otherwise "isloaded x" will return true if module "x_y" is loaded
    ( test -f "$MODULELIST" && grep -q "^$1\>" "$MODULELIST" ) || lsmod | grep -q "^$1\>"
}

# Unload NVIDIA module
if isloaded nvidia; then
    checkuser
    $MODPROBE -r nvidia_uvm 2>/dev/null
    $MODPROBE -r nvidia_drm 2>/dev/null
    $MODPROBE -r nvidia_modeset 2>/dev/null
    $MODPROBE -r nvidia || die "Unable to unload nvidia module"
    $MODPROBE -r i2c_nvidia_gpu 2>/dev/null
fi

# Check if module is loaded, if not, load it
if isloaded "$MODULE_NAME"; then
    echo "Already loaded module ${MODULE_NAME}"
    exit 0
fi

checkuser

# Check if there is a precompiled module and try to install it
if [ -f "${MODULE_DIR}${MODULE_NAME}.ko" ]; then
    $INSMOD "${MODULE_DIR}${MODULE_NAME}.ko" && sleep 1 && echo "Loaded already compiled module ${MODULE_NAME}" && exit 0
fi

# Check if make is installed
command -v make >/dev/null || die "'make' program is not installed.\nPlease install Toolchain and make program required for building C kernel modules\n(for ubuntu it is 'build-essential' package)."

# Check if kernel sources are available
[ -d "/lib/modules/${KERN_VERSION}/build" ] || die "Kernel sources are not installed.\nPlease install kernel headers for version ${KERN_VERSION} using your distribution's package manager.\nTypically is is package named like 'linux*headers*'"

[ -w . ] || die "Current directory must be writable since in-tree build is used"

mkdir -p "${MODULE_DIR}"

ln -fs "$SELF_DIR/Makefile" "$SELF_DIR"/*.c "$SELF_DIR"/*.h "${MODULE_DIR}"

# Clean the precompiled module
make -C "$MODULE_DIR" clean || die "Cleanup failed"

# Compile the module with disabled gcc plugins and disabled BTF to allow some compiler version mismatch
make -C "$MODULE_DIR" GCC_PLUGINS_CFLAGS= CONFIG_DEBUG_INFO_BTF_MODULES= || die "Compilation failed"

# Try to insert the compiled module
$INSMOD "${MODULE_DIR}${MODULE_NAME}.ko" || die "Unable to load the module"
echo "Loaded module ${MODULE_NAME}"

