PREFIX = acre
BIN = @acre2
ZIP = acre2
FLAGS = -i include -w unquoted-string -w redefinition-wo-undef
VERSION_FILES = README.md docs/_data/sidebar.yml
COPY_FILES = *.dll acre_logo_medium_ca.paa LICENSE meta.cpp mod.cpp README.md extras/ plugin/

MAJOR = $(shell grep "^\#define[[:space:]]*MAJOR" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
MINOR = $(shell grep "^\#define[[:space:]]*MINOR" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
PATCH = $(shell grep "^\#define[[:space:]]*PATCHLVL" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
BUILD = $(shell grep "^\#define[[:space:]]*BUILD" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
VERSION = $(MAJOR).$(MINOR).$(PATCH)
VERSION_FULL = $(VERSION).$(BUILD)
GIT_HASH = $(shell git log -1 --pretty=format:"%H" | head -c 8)

ifeq ($(OS), Windows_NT)
	ARMAKE = ./tools/armake2.exe
else
	ARMAKE = armake2
endif

$(BIN)/addons/$(PREFIX)_%.pbo: addons/%
	@mkdir -p $(BIN)/addons
	@echo "  PBO  $@"
	@${ARMAKE} build ${FLAGS} -f -e "version=$(GIT_HASH)" $< $@

$(BIN)/optionals/$(PREFIX)_%.pbo: optionals/%
	@mkdir -p $(BIN)/optionals
	@echo "  PBO  $@"
	@${ARMAKE} build ${FLAGS} -f -e "version=$(GIT_HASH)" $< $@

# Shortcut for building single addons (eg. "make <component>.pbo")
%.pbo:
	"$(MAKE)" $(MAKEFLAGS) $(patsubst %, $(BIN)/addons/$(PREFIX)_%, $@)

all: $(patsubst addons/%, $(BIN)/addons/$(PREFIX)_%.pbo, $(wildcard addons/*)) \
		$(patsubst optionals/%, $(BIN)/optionals/$(PREFIX)_%.pbo, $(wildcard optionals/*))
	@cp -ru $(COPY_FILES) $(BIN)

filepatching:
	"$(MAKE)" $(MAKEFLAGS) FLAGS="-w unquoted-string -p"

$(BIN)/keys/%.biprivatekey:
	@mkdir -p $(BIN)/keys
	@echo "  KEY  $@"
	@${ARMAKE} keygen -f $(patsubst $(BIN)/keys/%.biprivatekey, $(BIN)/keys/%, $@)

$(BIN)/addons/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL)-$(GIT_HASH).bisign: $(BIN)/addons/$(PREFIX)_%.pbo $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey
	@echo "  SIG  $@"
	@${ARMAKE} sign -f -s $@ $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey $<

$(BIN)/optionals/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL)-$(GIT_HASH).bisign: $(BIN)/optionals/$(PREFIX)_%.pbo $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey
	@echo "  SIG  $@"
	@${ARMAKE} sign -f -s $@ $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey $<

signatures: $(patsubst addons/%, $(BIN)/addons/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL)-$(GIT_HASH).bisign, $(wildcard addons/*)) \
		$(patsubst optionals/%, $(BIN)/optionals/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL)-$(GIT_HASH).bisign, $(wildcard optionals/*))

extensions: $(wildcard extensions/*/*)
	cd extensions/vcproj && cmake .. && make

extensions-win64: $(wildcard extensions/*/*)
	cd extensions/vcproj64 && CXX=$(eval $(which g++-w64-mingw-i686)) cmake .. && make

version:
	@echo "  VER  $(VERSION_FULL)"
	$(shell sed -i -r -s 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/$(VERSION_FULL)/g' $(VERSION_FILES))
	$(shell sed -i -r -s 's/[0-9]+\.[0-9]+\.[0-9]+/$(VERSION)/g' $(VERSION_FILES))
	@echo -e "#define MAJOR $(MAJOR)\n#define MINOR $(MINOR)\n#define PATCHLVL $(PATCH)\n#define BUILD $(BUILD)" > "addons/main/script_version.hpp"
	$(shell sed -i -r -s 's/ACRE_VERSION_MAJOR [0-9]+/ACRE_VERSION_MAJOR $(MAJOR)/g' extensions/src/ACRE2Shared/version.h)
	$(shell sed -i -r -s 's/ACRE_VERSION_MINOR [0-9]+/ACRE_VERSION_MINOR $(MINOR)/g' extensions/src/ACRE2Shared/version.h)
	$(shell sed -i -r -s 's/ACRE_VERSION_SUBMINOR [0-9]+/ACRE_VERSION_SUBMINOR $(PATCH)/g' extensions/src/ACRE2Shared/version.h)
	$(shell sed -i -r -s 's/ACRE_VERSION_BUILD [0-9]+/ACRE_VERSION_BUILD $(BUILD)/g' extensions/src/ACRE2Shared/version.h)

release: clean
	@"$(MAKE)" $(MAKEFLAGS) signatures
	@echo "  ZIP  $(ZIP)_$(VERSION).zip"
	@cp -r $(COPY_FILES) $(BIN)
	@zip -qr $(ZIP)_$(VERSION).zip $(BIN)

clean:
	rm -rf $(BIN) $(ZIP)_*.zip

.PHONY: all filepatching signatures extensions extensions-win64 release clean
