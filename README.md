NVIDIA MODS kernel driver
=========================

Introduction
------------

The NVIDIA MODS kernel driver is a simple kernel module which provides
access to devices on the PCI bus for user mode programs.  It is so named
because it was originally written to support the MOdular Diagnostic Suite
(MODS), which is our internal chip diagnostic toolkit.

The MODS driver was never intended for release to the public, and as such,
the code is in something of an unfinished form.  It is released in the hopes
that it will save work for people who might otherwise need to implement such
a thing.

This software is not published as an official NVIDIA product.  NVIDIA will
provide no support for this source release
