/*
 * mods_config.h - This file is part of NVIDIA MODS kernel driver.
 *
 * Copyright (c) 2008-2014, NVIDIA CORPORATION.  All rights reserved.
 *
 * NVIDIA MODS kernel driver is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * NVIDIA MODS kernel driver is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with NVIDIA MODS kernel driver.
 * If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _MODS_CONFIG_H_
#define _MODS_CONFIG_H_

#define MODS_KERNEL_VERSION LINUX_VERSION_CODE

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 19)
#	define MODS_IRQ_HANDLE_NO_REGS 1
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 25)
#	define MODS_HAS_SET_MEMORY 1
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 27)
#	define MODS_HAS_DEBUGFS 1
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 28)
#	define MODS_ACPI_DEVID_64 1
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 29)
#	define MODS_HAS_WC 1
#	define MODS_HAS_DEV_TO_NUMA_NODE 1
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 31)
#	define MODS_HAS_IORESOURCE_MEM_64 1
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 33)
#	define MODS_HAS_NEW_ACPI_WALK 1
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 13, 0)
#	define MODS_HAS_NEW_ACPI_HANDLE 1
#endif

#undef MODS_HAS_KFUSE

#if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 10, 0) && defined(CONFIG_ARCH_TEGRA) && defined(CONFIG_DMA_SHARED_BUFFER)
#	define MODS_HAS_DMABUF 1
#endif

#define MODS_MULTI_INSTANCE_DEFAULT_VALUE 0

#endif /* _MODS_CONFIG_H_  */
