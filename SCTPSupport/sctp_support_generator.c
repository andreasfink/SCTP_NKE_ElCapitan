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
#include <mach-o/stab.h>
#include <string.h>
#include <stdlib.h>

// see also http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/DevTools/14_MachO/MachO.htmld/index.html


int main(const int argc, const char *argv[])
{
	const char *output_filename;
	const char *symbol_filename;
	const char *tmp_filename1;
	const char *tmp_filename2;
	
	struct mach_header_64		machHeader;
	struct segment_command_64	segmentCommand;
	struct symtab_command 		symtabCommand;
	struct uuid_command 		uuidCommand;
	int		symbolCount = 0;
	int		symbolIndex = 0;
	int		symbolsOutputOffset;
	void *symbolsStrings;
	void *symbols;
	uint8_t	uuid[16] = {0x00,0x01,0x02,0x03,0x04,0x5,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f };

	if(argc <3)
	{
		fprintf(stderr,"Syntax: %s <outputfile> <symbolfile>",argv[0]);
		exit(-1);
	}
	output_filename = argv[1];
	symbol_filename = argv[2];
	tmp_filename1 = "symbols.tmp1"; /* the symbol strings separated by 0 */
	tmp_filename2 = "symbols.tmp2"; /* the nlist_64 entries */

	FILE *output_file = fopen(output_filename,"w+");
	if(output_file==NULL)
	{
		fprintf(stderr,"can not create output file %s",output_filename);
		exit(-1);
	}	
	FILE *symbols_file = fopen(symbol_filename,"r");
	if(symbols_file==NULL)
	{
		fprintf(stderr,"can not read input file %s",symbol_filename);
		exit(-1);
	}

	FILE *tmp_file1 = fopen(tmp_filename1,"w+");
	if(tmp_file1==NULL)
	{
		fprintf(stderr,"can not create temporary file %s",tmp_filename1);
		exit(-1);
	}
	
	FILE *tmp_file2 = fopen(tmp_filename2,"w+");
	if(tmp_file2==NULL)
	{
		fprintf(stderr,"can not create temporary file %s",tmp_filename2);
		exit(-1);
	}	

	symbolCount = 0;
	symbolIndex = 0;
	symbolsOutputOffset = 0;
	
	char buffer[256];
	memset(&buffer,0x00,sizeof(buffer));

	fwrite(buffer,4,1,tmp_file1);
	symbolsOutputOffset +=4;

	while(1)
	{
		struct nlist_64 nlist_entry;
		int i=0;
		size_t symbolNameLength = 0;
		int n=sizeof(buffer);
	
		memset(&buffer,0x00,sizeof(buffer));
		memset(&nlist_entry,0x00,sizeof(nlist_entry));
		
	    char *s = fgets(buffer, sizeof(buffer)-1,symbols_file);
		if(s == NULL)
		{
			break;
		}
		
		for(i=0;i<sizeof(buffer)-1;i++)
		{
			if((buffer[i] == '\0') || (buffer[i] == '\n') || (buffer[i] == '\r'))
			{
				buffer[i] = '\0';
				symbolNameLength = i;
				break;
			}
		}
		
		fwrite(buffer,symbolNameLength+1,1,tmp_file1);
		nlist_entry.n_un.n_strx = symbolsOutputOffset;
		nlist_entry.n_type = N_EXT | N_UNDF;
		nlist_entry.n_sect = NO_SECT;
		nlist_entry.n_desc = N_GSYM;
		nlist_entry.n_value = 0;

		fprintf(stdout,"Symbol %d: %s at offset %d\n",symbolCount,buffer,symbolsOutputOffset);
		symbolsOutputOffset += symbolNameLength+1;
		symbolCount++;
		fwrite(&nlist_entry,sizeof(nlist_entry),1,tmp_file2);
	}
	rewind(tmp_file1);
	rewind(tmp_file2);

	symbolsStrings = calloc(symbolsOutputOffset,1);
	symbols = calloc(sizeof(struct nlist_64),symbolCount);
	fread(symbolsStrings,symbolsOutputOffset,1,tmp_file1);
	fread(symbols,sizeof(struct nlist_64),symbolCount,tmp_file2),
	
	memset(&machHeader,0x00,sizeof(machHeader));
	machHeader.magic = MH_MAGIC_64;
	machHeader.cputype = CPU_TYPE_X86_64;
	machHeader.cpusubtype = 3;
	machHeader.filetype = 11;
	machHeader.ncmds = 3;
	machHeader.sizeofcmds = sizeof(machHeader)+sizeof(segmentCommand)+sizeof(symtabCommand)+sizeof(uuidCommand);
	machHeader.flags = MH_INCRLINK;
	machHeader.reserved = 0;
	
	memset(&segmentCommand,0x00,sizeof(segmentCommand));
	segmentCommand.cmd = LC_SEGMENT_64;
	segmentCommand.cmdsize = sizeof(segmentCommand);
	strncpy(segmentCommand.segname,"__LINKEDIT",sizeof(segmentCommand.segname));
	segmentCommand.vmaddr = 0x0000000000000000;
	segmentCommand.vmsize = 0x0000000000004000;
	segmentCommand.fileoff = 4096;
	segmentCommand.filesize = symbolCount *sizeof(struct nlist_64) + symbolsOutputOffset;
	segmentCommand.maxprot = 0x00000001;
	segmentCommand.initprot = 0x00000001;
	segmentCommand.nsects = 0;
	segmentCommand.flags = 0x04;

	memset(&symtabCommand,0x00,sizeof(symtabCommand));
	symtabCommand.cmd = LC_SYMTAB;
	symtabCommand.cmdsize = sizeof(symtabCommand);
	symtabCommand.symoff = 4096;
	symtabCommand.nsyms = symbolCount;
	symtabCommand.stroff = 4096 + sizeof(struct nlist_64) * symbolCount; /* position in the file where the strings start */
	symtabCommand.strsize = symbolsOutputOffset;

	memset(&uuidCommand,0x00,sizeof(uuidCommand));
	uuidCommand.cmd = LC_UUID;
	uuidCommand.cmdsize = sizeof(struct uuid_command);
	memcpy(uuidCommand.uuid,uuid,sizeof(uuidCommand.uuid));

	fprintf(stderr,"Writing machHeader %lu bytes\n",sizeof(machHeader));
	fwrite(&machHeader,sizeof(machHeader),1,output_file);
	fprintf(stderr,"Writing segmentCommand %lu bytes\n",sizeof(segmentCommand));
	fwrite(&segmentCommand,sizeof(segmentCommand),1,output_file);
	fprintf(stderr,"Writing symtabCommand %lu bytes\n",sizeof(symtabCommand));
	fwrite(&symtabCommand,sizeof(symtabCommand),1,output_file);
	fprintf(stderr,"Writing uuidCommand %lu bytes\n",sizeof(uuidCommand));
	fwrite(&uuidCommand,sizeof(uuidCommand),1,output_file);
	int zeros = 4096 - sizeof(machHeader) - sizeof(segmentCommand) - sizeof(symtabCommand) - sizeof(uuidCommand);

	int buf[4096];
	memset(buf,0x00,4096);
	
	fprintf(stderr,"Writing %d zeros\n",zeros);
	fwrite(&buf,zeros,1,output_file);
	fprintf(stderr,"Writing %d nlist objects of size %lu total %lu\n",symbolCount,sizeof(struct nlist_64),symbolCount *sizeof(struct nlist_64));
	fwrite(symbols,sizeof(struct nlist_64),symbolCount,output_file);

	fprintf(stderr,"Writing %d bytes of strings\n",symbolsOutputOffset);
	fwrite(symbolsStrings,symbolsOutputOffset,1,output_file);
	fclose(output_file);
}