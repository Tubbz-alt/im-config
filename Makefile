PROGRAM	=	im-config
ifeq ($(wildcard debian/changelog),)
VERSION = VCS-$(shell date -u  +%Y%m%d%H%M)
else
VERSION = $(shell dpkg-parsechangelog --format dpkg|\
		sed -ne '/^Version/s/Version: *//p')
endif

FILES = \
	70-im-config \
	70im-config_launch \
	im-config \
	im-launch \
	share/im-config.common \
	share/xinputrc.common.in \
	$(wildcard data/*.rc) \
	$(wildcard data/*.conf)

PRETESTS = $(addsuffix .pretest, $(FILES))

TESTS = $(addsuffix .test, $(FILES))

# escape  with \#
LANGS = $(shell grep -v '^\#' po/LINGUAS)
POTFILESIN = $(shell grep -v '^\#' po/POTFILES.in)

all: share/xinputrc.common mo

share/xinputrc.common: share/xinputrc.common.in
	sed -e "s/@@VERSION@@/$(VERSION)/" <$< >$@

pot: po/$(PROGRAM).pot

po/$(PROGRAM).pot: FORCE
	xgettext -o $@ --language=Shell $(PROGRAM) $(POTFILESIN)

po/%.po: po/$(PROGRAM).pot
	msgmerge -U $@ $<

po/locale/%/LC_MESSAGES/$(PROGRAM).mo: po/%.po
	mkdir -p po/locale/$*/LC_MESSAGES
	msgfmt -o $@ $<

# run test on all script first
%.pretest: %
	@/bin/sh -n $< ; echo $$? > $@

# stop if error was found
%.test: %.pretest
	@[ `cat $<` = "0" ]

test: $(PRETESTS)
	# check if any syntax check resulted in error
	@$(MAKE) $(TESTS)

mo:	$(addsuffix /LC_MESSAGES/$(PROGRAM).mo, $(addprefix po/locale/, $(LANGS)))

po:	$(addsuffix .po, $(addprefix po/, $(LANGS)))

foo:
	echo "$(addsuffix /LC_MESSAGES/$(PROGRAM).mo, $(addprefix po/locale/, $(LANGS)))"
	echo "-----"
	echo "$(addsuffix .po, $(addprefix po/, $(LANGS)))"

clean:
	-rm -f share/xinputrc.common
	rm -rf po/locale
	rm -f  po/*.po~ po/*.mo
	-rm -f $(PRETESTS)
	-rm -f $(TESTS)

distclean: clean

# Use this target on devel branch source
package:
	debmake -t -y -zx -b':sh' -i pdebuild

update:
	touch -t 200001010000 po/*.po
	$(MAKE) po
	$(MAKE) clean

.PHONY: all pot distclean clean mo update po test FORCE
