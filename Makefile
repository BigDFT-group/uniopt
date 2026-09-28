PREFIX ?= /usr/local
DESTDIR ?=
BINDIR = $(DESTDIR)$(PREFIX)/bin
DATADIR = $(DESTDIR)$(PREFIX)/share/uniopt

.PHONY: all test docs check-docs install uninstall

all: test

test:
	bash tests/all.sh

docs:
	bash scripts/generate-docs
	./scripts/generate-llms

check-docs:
	bash scripts/check-docs

install:
	PREFIX="$(PREFIX)" DESTDIR="$(DESTDIR)" bash scripts/install-uniopt

uninstall:
	rm -f "$(BINDIR)/uniopt" "$(DATADIR)/lib/uniopt.sh"
	rm -rf "$(DATADIR)/docs" "$(DATADIR)/tools" "$(DATADIR)/schema"
	rmdir "$(DATADIR)/lib" "$(DATADIR)" 2>/dev/null || true
