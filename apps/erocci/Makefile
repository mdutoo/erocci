PROJECT = erocci
VERSION = 0.5

dep_pocci = git https://github.com/CESNET/pOCCI.git master

top_srcdir = $(CURDIR)/../..
VSN = $(shell $(top_srcdir)/version.sh $(VERSION))

subst = sed -e 's|@VSN[@]|$(VSN)|g'

include $(top_srcdir)/erlang.mk

ERLC_OPTS += -I$(top_srcdir)/deps

POCCI_DATA = test/pocci_SUITE_data/pocci.conf

my_dep_verbose_0 = @echo " DEP    pocci";
my_dep_verbose = $(my_dep_verbose_$(V))

$(PROJECT).d:: src/$(PROJECT).app.src

src/$(PROJECT).app.src: src/$(PROJECT).app.src.in
	$(gen_verbose) $(subst) $< > $@

test-build:: pocci

pocci:
	$(my_dep_verbose) $(call dep_fetch_$(strip $(call dep_fetch,pocci)),pocci)

ct: $(POCCI_DATA)

$(POCCI_DATA):
	@echo "{'POCCI', \"$(DEPS_DIR)/pocci/pOCCI/pOCCI.py\"}." > $@

.PHONY: pocci
