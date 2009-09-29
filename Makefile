# SilverFW makefile
#
# This makefile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This makefile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this makefile.  If not, see <http://www.gnu.org/licenses/>.

VERSION=0.1

# If prefix is not set then set it
ifndef prefix
prefix=/usr/local
# If prefix IS set then assume a distro install (skips some steps)
else
distrib=true
endif

bindir ?= $(prefix)/sbin
datadir ?= $(prefix)/share
mandir ?= $(prefix)/share/man
sysconfdir ?= /etc
SFW_datadir = $(datadir)/silverfw
INITDIR ?= $(sysconfdir)/init.d/

# --- Set up some conditional settings ---
POD2MAN = $(shell [ ! -e "./silverfw.8" ] && echo man)
ifndef distrib
DEPS_CHECK=deps_check
# If we should start the FW or not
STARTFW=$(shell [ "$$(perl -e 'print $$<')" -eq "0" ] && echo startit)
# Which init mode to use
CHKCONFIG = $(shell which chkconfig 2> /dev/null && echo true)
UPDATERCD = $(shell which update-rc.d 2> /dev/null && echo true)

RC_INSTALL = manualrc
RC_REMOVE = manualrc_rm
ifneq "$(CHKCONFIG)" ''
RC_INSTALL = chkconfig
RC_REMOVE = chkconfig_rm
else
ifneq "$(UPDATERCD)" ""
RC_INSTALL = updatercd
RC_REMOVE = updatercd_rm
endif	# ifdef UPDATERCD
endif	# ifdef CHKCONFIG
else
STARTFW=""
RC_INSTALL=""
DEPS_CHECK=""
endif	# ifndef distrib

# Which init file to use
MDVINIT = $(shell [ -e "$(sysconfdir)/rc5.d/S10network" ] && echo true)
ifneq "$(MDVINIT)" ''
INITFILE = S10o-SilverFW
else
INITFILE = S55-SilverFW
endif

# --- Make targets ---

# Install silverfw
install: $(DEPS_CHECK) $(POD2MAN) maininstall $(RC_INSTALL) $(STARTFW)

maininstall:
	mkdir -p "$(bindir)"
	mkdir -p "$(SFW_datadir)"
	mkdir -p "$(mandir)/man8/"
	cp silverfw "$(SFW_datadir)"
	ln -sf "$(SFW_datadir)/silverfw" "$(bindir)"
	cp silverfw_easyallow.list "$(SFW_datadir)/"
	[ ! -e $(sysconfdir)/silverfw.conf ] && cp silverfw.conf $(sysconfdir)/silverfw.conf || true
	chmod 600 $(sysconfdir)/silverfw.conf
	cp silverfw.init $(INITDIR)/silverfw
	chmod 700 "$(INITDIR)/silverfw" "$(bindir)/silverfw"
	cp silverfw.8 "$(mandir)/man8/"

chkconfig:
	chkconfig --add silverfw

updatercd:
	update-rc.d silverfw defaults

manualrc:
	-ln -sf $(INITDIR)/silverfw $(sysconfdir)/rc5.d/$(INITFILE)
	-ln -sf $(INITDIR)/silverfw $(sysconfdir)/rc4.d/$(INITFILE)
	-ln -sf $(INITDIR)/silverfw $(sysconfdir)/rc3.d/$(INITFILE)
	-ln -sf $(INITDIR)/silverfw $(sysconfdir)/rc2.d/$(INITFILE)

startit:
	@echo
	@echo -n 'Run '
	@(if [ "`which service 2>/dev/null`" != "" ]; then echo -n "service silverfw start";else  echo -n '"$(INITDIR)silverfw" start';fi)
	@echo " to start it"

deps_check:
	which iptables > /dev/null
	which perl > /dev/null
	which modprobe > /dev/null

# Uninstall an installed silverfw
uninstall: $(RC_REMOVE)
	which service &>/dev/null && service silverfw stop || "$(bindir)/silverfw" stop
	rm -rf "$(SFW_datadir)"
	rm -f "$(bindir)/silverfw"
	rm -f $(INITDIR)/silverfw
	rm -f "$(mandir)/man8/silverfw.8"
	@echo Configuration file not removed. If you wish to remove it then delete $(sysconfdir)/silverfw.conf manually.

chkconfig_rm:
	chkconfig --del silverfw

updatercd_rm:
	update-rc.d -f silverfw remove

manualrc_rm:
	-rm -f $(sysconfdir)/rc5.d/$(INITFILE)
	-rm -f $(sysconfdir)/rc4.d/$(INITFILE)
	-rm -f $(sysconfdir)/rc3.d/$(INITFILE)
	-rm -f $(sysconfdir)/rc2.d/$(INITFILE)

# Clean up the tree
clean:
	rm -f `find|egrep '~$$'`
	rm -f silverfw-$(VERSION).tar.bz2
	rm -rf silverfw-$(VERSION)
	rm -f silverfw.8
# Verify syntax
test:
	@perl -c silverfw
# Create a manpage from the POD
man:
	pod2man --section 8 --name "silverfw" --center "" --release "SilverFW $(VERSION)" ./silverfw ./silverfw.8
# Create the tarball
distrib: clean test man
	mkdir -p silverfw-$(VERSION)
	cp -r ./`ls|grep -v silverfw-$(VERSION)` ./silverfw-$(VERSION)
	rm -rf `find silverfw-$(VERSION) -name \\.svn`
	tar -jcvf silverfw-$(VERSION).tar.bz2 ./silverfw-$(VERSION)
	rm -rf silverfw-$(VERSION)
