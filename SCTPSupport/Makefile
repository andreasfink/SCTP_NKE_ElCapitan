#
# Makefile
#

SCTPSupport:	sctp_support_generator ../SCTPSupport_symbols.txt
	./sctp_support_generator SCTPSupport ../SCTPSupport_symbols.txt

sctp_support_generator:	sctp_support_generator.o
	clang sctp_support_generator.o -o sctp_support_generator

sctp_support_generator.o:	sctp_support_generator.c
	clang -c sctp_support_generator.c -o sctp_support_generator.o
