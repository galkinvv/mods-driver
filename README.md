# NVIDIA MODS kernel driver

## Introduction

The NVIDIA MODS kernel driver is a simple kernel module which provides
access to devices on the PCI bus for user mode programs.  It is so named
because it was originally written to support the MOdular Diagnostic Suite
(MODS), which is our internal chip diagnostic toolkit.

The MODS driver was never intended for release to the public, and as such,
the code is in something of an unfinished form.  It is released in the hopes
that it will save work for people who might otherwise need to implement such
a thing.

This software is licensed under GNU GPL2 and not published as an official NVIDIA product.
NVIDIA will provide no support for this source release.

## Usage

### Install prerequisites
Use your distribution package meneger to install:

* Toolchain and make program required for building C kernel modules (for ubuntu it is `build-essential` package).
* Kernel headers of your kernel version (typically is is package named like `linux*headers*`).

### Userspace tool naming for this module
* Due to compatibility problems, mats binaries at least up to v400 must be named as `mats` or `mats400`. Other names are not accepted.
* Due to compatibility problems, newer mats binaries must be named like `mats499` (replace 499 with real version).

### Loading module alternatives

#### Alternative 1: universal - for any tools - manual loading
Run `./install_module.sh` without parameters.
On success it will build the module if it is not already build and load it into kernel.

Here is example of expected output with examples of a typical output for correct operation:
```
[root@pool mods-driver]# ./install_module.sh
make: Entering directory '/opt/mods-driver/build-4.19.47-1-lts'
make -C /lib/modules/4.19.47-1-lts/build M=/opt/mods-driver/build-4.19.47-1-lts clean
make[1]: Entering directory '/usr/lib/modules/4.19.47-1-lts/build'
make[1]: Leaving directory '/usr/lib/modules/4.19.47-1-lts/build'
make: Leaving directory '/opt/mods-driver/build-4.19.47-1-lts'
make: Entering directory '/opt/mods-driver/build-4.19.47-1-lts'
make -C /lib/modules/4.19.47-1-lts/build M=/opt/mods-driver/build-4.19.47-1-lts modules
make[1]: Entering directory '/usr/lib/modules/4.19.47-1-lts/build'
  CC [M]  /opt/mods-driver/build-4.19.47-1-lts/mods_krnl.o
  CC [M]  /opt/mods-driver/build-4.19.47-1-lts/mods_mem.o
  CC [M]  /opt/mods-driver/build-4.19.47-1-lts/mods_irq.o
  CC [M]  /opt/mods-driver/build-4.19.47-1-lts/mods_pci.o
  CC [M]  /opt/mods-driver/build-4.19.47-1-lts/mods_acpi.o
  CC [M]  /opt/mods-driver/build-4.19.47-1-lts/mods_debugfs.o
  LD [M]  /opt/mods-driver/build-4.19.47-1-lts/mods.o
  Building modules, stage 2.
  MODPOST 1 modules
  CC      /opt/mods-driver/build-4.19.47-1-lts/mods.mod.o
  LD [M]  /opt/mods-driver/build-4.19.47-1-lts/mods.ko
make[1]: Leaving directory '/usr/lib/modules/4.19.47-1-lts/build'
make: Leaving directory '/opt/mods-driver/build-4.19.47-1-lts'
Loaded module mods
[root@pool mods-driver]# ./install_module.sh
Already loaded module mods
[root@pool mods-driver]# rmmod mods
[root@pool mods-driver]# ./install_module.sh
Loaded already compiled module mods
[root@pool mods-driver]# ./install_module.sh
Already loaded module mods
[root@pool mods-driver]#

```

Now you can use the software that needs this kernel module - mods or mats - until reboot.

#### Alternative 2: mods-specific autoloading
mods utility (unlike mats!) can automatically run this script during startup if the module is not loaded in the kernal yet.
So just put `install_module.sh` and `_aa_driver_*-src` folder in the directory with mods binary
