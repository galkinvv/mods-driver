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
MODULE_DIR="build-${KERN_VERSION}/"
INSMOD="/sbin/insmod"
RMMOD="/sbin/rmmod"
MODPROBE="/sbin/modprobe"
DEPMOD="/sbin/depmod"
UDEVBASEDIR="/etc/udev"
MODSRULESFILE="99-mods.rules"
MODSPERMFILE="99-mods.permissions"
MODSRULES="KERNEL==\"mods\", GROUP=\"video\""
MODSPERM="mods:root:video:0660"
MODULELIST="/proc/modules"
DRIVER="`dirname $0`/driver.tgz"

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

# Check arguments
OPTION=""
case "$1" in
-i|--install)
    OPTION="install" ;;
-u|--uninstall)
    OPTION="uninstall" ;;
-r|--reload)
    OPTION="reload" ;;
--insert)
    OPTION="insert" ;;
esac
if [ -z "$1" ]; then
    OPTION="insert"
fi
if [ $# -gt 1 ] || [ -z "$OPTION" ]; then
    echo "This is installation script for MODS kernel driver"
    echo
    echo "Usage: `basename $0` [OPTION]"
    echo
    echo "OPTION is one of:"
    echo "NO ARGS, --insert Compiles driver and loads it until reboot."
    echo "  -i, --install   Installs the driver in the system and loads it."
    echo "  -u, --uninstall Unloads the driver and removes it from the system."
    echo "  -r, --reload    Reloads installed driver."
    echo "  -h, --help      Displays this information."
    echo
    [ "$1" = "--help" ] || [ "$1" = "-h" ] || exit 1
    exit 0
fi

# Uninstall
if [ "$OPTION" = "uninstall" ]; then
    checkuser
    isloaded "$MODULE_NAME" && $RMMOD "$MODULE_NAME"
    RULESFILE=`find "$UDEVBASEDIR/" -name "$MODSRULESFILE" 2>/dev/null | head -n 1`
    [ -f "$RULESFILE" ] && [ "`cat "$RULESFILE"`" = "$MODSRULES" ] && rm "$RULESFILE"
    PERMFILE=`find "$UDEVBASEDIR/" -name "$MODSPERMFILE" 2>/dev/null | head -n 1`
    [ -f "$PERMFILE" ] && [ "`cat "$PERMFILE"`" = "$MODSPERM" ] && rm "$PERMFILE"
    [ -f "/etc/modules" ] && grep -q "$MODULE_NAME" "/etc/modules" && sed -i "/$MODULE_NAME/d" "/etc/modules"
    find "/lib/modules/`uname -r`"/ -name "$MODULE_NAME.ko" -exec rm '{}' \;
    $DEPMOD -aq
    [ -c "/dev/$MODULE_NAME" ] && rm "/dev/$MODULE_NAME"
    exit 0
fi

# Unload NVIDIA module
if isloaded nvidia; then
    checkuser
    $MODPROBE -r nvidia_uvm 2>/dev/null
    $MODPROBE -r nvidia_drm 2>/dev/null
    $MODPROBE -r nvidia_modeset 2>/dev/null
    $MODPROBE -r nvidia || die "Unable to unload nvidia module"
fi

# Unload MODS module if we are reinstalling or reloading it
if ( [ "$OPTION" = "install" ] || [ "$OPTION" = "reload" ] ) && isloaded "$MODULE_NAME"; then
    checkuser
    $RMMOD "$MODULE_NAME" || die "Unable to unload $MODULE_NAME module"
fi

# Check if module is loaded, if not, load it
if isloaded "$MODULE_NAME"; then
    echo "Already loaded module ${MODULE_NAME}"
    exit 0
fi

if [ "$OPTION" != "install" ]; then

    # Attempt to load the MODS driver
    [ `id -u` -eq 0 ] && $MODPROBE -q "$MODULE_NAME" && sleep 1 && echo "Loaded preinstalled module ${MODULE_NAME}" && exit

    # Check if there is a precompiled module and try to install it
    if [ "$OPTION" = "insert" -a -f "${MODULE_DIR}${MODULE_NAME}.ko" ]; then
        checkuser
        $INSMOD "${MODULE_DIR}${MODULE_NAME}.ko" && sleep 1 && echo "Loaded already compiled module ${MODULE_NAME}" && exit
    fi

    # Bail out on reload
    [ "$OPTION" = "reload" ] && die "Unable to reload $MODULE_NAME module, please install it"
fi

# Check if make is installed
command -v make >/dev/null || die "'make' program is not installed.\nPlease install Toolchain and make program required for building C kernel modules\n(for ubuntu it is 'build-essential' package)."

# Check if kernel sources are available
[ -d "/lib/modules/${KERN_VERSION}/build" ] || die "Kernel sources are not installed.\nPlease install kernel headers for version ${KERN_VERSION} using your distribution's package manager.\nTypically is is package named like 'linux*headers*'"

[ -w . ] || die "Current directory must be writable since in-tree build is used"

mkdir -p "${MODULE_DIR}"

(
    cd "${MODULE_DIR}"
    ln -fs ../Makefile ../*.c ../*.h ./
)

# Clean the precompiled module
make -C "$MODULE_DIR" clean || die "Cleanup failed"

# Compile the module
make -C "$MODULE_DIR" || die "Compilation failed"

# Install the module
checkuser
if [ "$OPTION" != "insert" ]; then
    make -C "$MODULE_DIR" install || die "Installation failed"
    $DEPMOD -ae

    # Update udev rules
    if ! grep -R -l -q "$MODULE_NAME" "$UDEVBASEDIR"/*; then
        RULESOK=0
        if grep -R -l -q nvidia "$UDEVBASEDIR"/*; then
            EXISTINGRULES=`grep -R -l nvidia "$UDEVBASEDIR"/* | grep ".rules$"`
            EXISTINGPERM=`grep -R -l nvidia "$UDEVBASEDIR"/* | grep ".permissions$"`
            if [ -f "$EXISTINGRULES" ]; then
                EXISTINGGROUP=`grep "nvidia" "$EXISTINGRULES" | sed "s/.*GROUP=\"// ; s/\".*//"`
                ( echo "$EXISTINGGROUP" | grep -q "=\|\"" ) || MODSRULES=`echo "$MODSRULES" | sed "s/video/$EXISTINGGROUP/"`
                RULESDIR=`dirname "$EXISTINGRULES"`
            fi
            if [ -f "$EXISTINGPERM" ]; then
                MODSPERM=`grep "nvidia" "$EXISTINGPERM" | sed "s/nvidia[^:]*:/mods:/"`
                PERMDIR=`dirname "$EXISTINGPERM"`
            fi
        fi
        if [ -z "$PERMDIR" -a -z "$RULESDIR" ]; then
            RULES=`find "$UDEVBASEDIR/" -name "*.rules" 2>/dev/null | head -n 1`
            if [ -f "$RULES" ]; then
                RULESDIR=`dirname "$RULES"`
            else
                RULESDIR="$UDEVBASEDIR/rules.d"
                [ -d "$RULESDIR" ] || mkdir "$RULESDIR"
            fi
        fi
        if [ -d "$RULESDIR" ]; then
            RULESFILE="$RULESDIR/$MODSRULESFILE"
            echo "Writing udev rules for the $MODULE_NAME kernel module info $RULESFILE"
            echo "$MODSRULES" > "$RULESFILE" || die "Unable to write $RULESFILE"
            RULESOK=1
        fi
        if [ -d "$PERMDIR" ]; then
            PERMFILE="$PERMDIR/$MODSPERMFILE"
            echo "Writing udev permissions for the $MODULE_NAME kernel module info $PERMFILE"
            echo "$MODSPERM" > "$PERMFILE" || die "Unable to write $PERMFILE"
            RULESOK=1
        fi
        if [ "$RULESOK" != "1" ]; then
            echo "Warning: Could not update udev rules!"
            echo "Please ensure that access permissions to /dev/mods are correct"
        fi
    fi

    # Print hint about loading the module on boot
    if [ -f "/etc/modules" ] && [ -f "/etc/debian_version" ]; then
        echo
        echo "To load the $MODULE_NAME module on boot, add it to /etc/modules"
    elif [ -f "/etc/rc.d/rc.local" ] && [ -f "/etc/redhat-release" ]; then
        echo
        echo "To load the $MODULE_NAME module on boot, add the following line in /etc/rc.d/rc.local:"
        echo "modprobe mods"
    elif [ -f "/etc/sysconfig/kernel" ] && [ -f "/etc/SuSE-release" ]; then
        echo
        echo "To load the $MODULE_NAME module on boot, add it to MODULES_LOADED_ON_BOOT"
        echo "in /etc/sysconfig/kernel"
    fi
fi

# Try to insert the compiled module
if [ "$OPTION" = "insert" ]; then
    $INSMOD "${MODULE_DIR}${MODULE_NAME}.ko" || die "Unable to install the module"
else
    $MODPROBE "${MODULE_NAME}" || die "Unable to install the module"
fi
echo "Loaded module ${MODULE_NAME}"

