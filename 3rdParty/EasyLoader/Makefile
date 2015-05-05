
# KickAss must be version 2.25 !!

# definitions in your file, read tools/example.EasyLoader.rc
# or use "make VARIABLE=VALUE"

DEPDIR = .deps
df = $(DEPDIR)/$(*F)
RCFILES =

ifneq ($(strip $(wildcard ~/.EasyLoader.rc)),)
include ~/.EasyLoader.rc
RCFILES += ~/.EasyLoader.rc
else
ifeq ($(PACKAGE),)
PACKAGE = tools/example.Package.rc
endif
endif

PHP5 ?= php
JAVA ?= java
KICKASS ?= KickAss.jar
VICE ?= x64
LOGUSER ?= $(USER)

RCFILES += $(PACKAGE)

SRCS = easyloader_nrm.asm easyloader_ocm.asm

N = "\\033[0m"
B = "\\033[1m"

.PHONY: all
all: build

.PHONY: build
build:
	$(MAKE) build/screen.asm
	$(MAKE) n

.PHONY: clean
clean:
	rm -f build/* .deps/*

.PHONY: svn
svn:
	svn ci
	svn up


define php_script =
		error_reporting(0); \
		$$f = `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 hg log .`; \
		if(preg_match("/changeset:([ 0-9]+):/s", $$f, $$r)){$$v = (int) $$r[1];}else{$$v = "unk";} \
		if(preg_match("/date:(.*? [+-][0-9]{4})/s", $$f, $$r)){$$t = time() - strtotime($$r[1]);}else{$$t = 0;} \
		if(`hg status -q .` == ""){ \
			$$s = "-".$$v; \
			echo str_pad(substr(strtoupper("$(LOGUSER)"), 0, 13-strlen($$s)).$$s, 13, chr(0x82), STR_PAD_LEFT); \
		}else{ \
			$$s = str_pad(strtoupper(substr("$(LOGUSER)", 0, 4)), 4, chr(0x82), STR_PAD_LEFT)."-"; \
			$$s .= $$v."."; \
			if($$t >= 356*86400){ \
				$$t = number_format($$t / (356*96400), 4, "Y", ""); \
			}else{ \
				$$t = sprintf("%06d", pow(log($$t/600+1, 1.654286), 3) * 100); \
			} \
			echo $$s.substr($$t, 0, 13-strlen($$s)); \
		}
endef

build/%.prg: %.asm
	@echo -e "$(B)Assembling $<$(N)"
	$(PHP5) tools/mkdep.php $< > $(df).P build/ts.txt
	$(PHP5) -r '$(php_script)' > build/ts.txt
	$(JAVA) -jar $(KICKASS) -showmem -vicesymbols -symbolfiledir build -symbolfile -asminfo "errors|files" -asminfofile $(@).asminfo -o $@ $<
	#$(JAVA) -jar $(KICKASS) -showmem -vicesymbols -asminfo "files|errors" -asminfofile $(@).asminfo -o $@ $<
	#@mv $(<:.asm=.vs) $(@:.prg=.vs)

%.crt: %.prg tools/mk_easyflash_module.php $(RCFILES)
	@echo -e "$(B)Packing a module $<$(N)"
	$(PHP5) tools/mk_easyflash_module.php > $@ < $< $< $(PACKAGE)

# prereq

#build/main.prg: graphics/petscii_lower_minimal.png build/screen.bin
build/main.prg: build/screen.bin

build/screen.asm: build/screen.bin

build/screen.bin: screen/screen.php graphics/sprites.png
	@echo -e "$(B)Generating $<$(N)"
	$(PHP5) screen/screen.php > $@


# debug version!

.PHONY: n
n: build/easyloader_nrm.crt
	@echo -e "$(B)Launching vice$(N)"
	echo 'load_labels "build/easyloader_nrm.vs"' > build/easyloader_nrm.mc
	$(VICE) -cartcrt build/easyloader_nrm.crt -moncommands build/easyloader_nrm.mc

.PHONY: o
o: build/easyloader_ocm.crt
	@echo -e "$(B)Launching vice$(N)"
	echo 'load_labels "build/easyloader_ocm.vs"' > build/easyloader_ocm.mc
	$(VICE) -cartcrt build/easyloader_ocm.crt -moncommands build/easyloader_ocm.mc

# autodep

-include $(SRCS:%.asm=$(DEPDIR)/%.P)
