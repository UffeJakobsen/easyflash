#
# Makefile
#


$(info Makefile target: $(MAKECMDGOALS))


#
#
#

MKDIRS := $(patsubst %/,%,$(dir $(wildcard */Makefile)))

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
