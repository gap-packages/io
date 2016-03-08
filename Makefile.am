ACLOCAL_AMFLAGS = -I m4

BINARCHDIR = bin/$(GAPARCH)
GAPINSTALLLIB = $(BINARCHDIR)/io.so

lib_LTLIBRARIES = io.la

io_la_SOURCES = src/io.c
io_la_CPPFLAGS = $(GAP_CPPFLAGS) -DCONFIG_H
# Note that the latter is only for GAP 4.4.12
io_la_LDFLAGS = -module -avoid-version
if SYS_IS_CYGWIN
io_la_LDFLAGS += -no-undefined -version-info 0:0:0 -Wl,$(GAPROOT)/bin/$(GAPARCH)/gap.dll
endif

all-local: $(GAPINSTALLLIB)

$(GAPINSTALLLIB): io.la
	$(mkdir_p) $(top_srcdir)/$(BINARCHDIR)
if SYS_IS_CYGWIN
	cp .libs/io.dll $(GAPINSTALLLIB)
else
	cp .libs/io.so $(GAPINSTALLLIB)
endif

clean-local:
	rm -f $(GAPINSTALLLIB)

distclean-local:
	rm -rf bin/*
	(cd doc ; ./clean)

doc:
	(echo 'Read("makedoc.g");' | $(GAPROOT)/bin/gap.sh -A -q)

.PHONY: doc
