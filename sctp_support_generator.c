/*
** sctp_support_generator.c
** Author: Andreas Fink
** (c) 2020
**
** This code writes a binary Mach-O file which exports missing symbols.
**
*/
#include <stdio.h>
#include <mach/machine.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <string.h>

// see also http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/DevTools/14_MachO/MachO.htmld/index.html


#define MH_MAGIC    0xfeedface  /* the Mach magic number */
#define CPU_TYPE_X86		((cpu_type_t) 7)
#define CPU_TYPE_I386		CPU_TYPE_X86		/* compatibility */
#define	CPU_TYPE_X86_64		(CPU_TYPE_X86 | CPU_ARCH_ABI64)
#define CPU_TYPE_ARM64		(CPU_TYPE_ARM | CPU_ARCH_ABI64)


int main(const int argc, const char *argv[])
{
	struct mach_header_64 MachHeader;
	
	
	memset(&MachHeader,0x00,sizeof(MachHeader));
	
	MachHeader.magic = MH_MAGIC_64;
	MachHeader.cputype = 16777223;
	MachHeader.cpusubtype = 3;
	MachHeader.filetype = 11;
	MachHeader.ncmds = 4;
	MachHeader.sizeofcmds = 0;
	MachHeader.flags = 2;
	MachHeader.reserved = 0;
	
	FILE *f = fopen("out.bin","w+");
	
	fwrite(&MachHeader,sizeof(MachHeader),1,f);
	
	fclose(f);
}