
#
#
#

MKDIRS=$(patsubst %/,%,$(dir $(wildcard */Makefile) $(wildcard examples/*/Makefile)))


#
#
#

.PHONY: default
default: all

#
#
#

.PHONY: all
all: $(MKDIRS)

.PHONY: install
install: $(MKDIRS)

.PHONY: clean
clean: $(MKDIRS)

.PHONY: $(MKDIRS)
$(MKDIRS):
	$(MAKE) -C $(@) -f Makefile $(MAKECMDGOALS)

#
# EOF
#

