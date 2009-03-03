# Makefile for configure and ioconfig.hin:

all:	configure ioconfig.hin

configure:	configure.ac
	autoconf configure.ac >configure
	chmod 755 configure

ioconfig.hin:	configure.ac
	autoheader configure.ac
	rm -rf ioconfig.hin~
