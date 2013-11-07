# The MIT License (MIT)
#
# Copyright (c) 2013 KokaKiwi <kokakiwi@kokakiwi.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

## VARS
RUSTC							=	rustc
RUSTDOC							=	rustdoc

RUST_BUILDDIR					=	.rust_build
RUST_LIBDIR						=	lib

RUSTCFLAGS						+=	-L $(RUST_LIBDIR)
RUSTDOCFLAGS					+=

## UTILS
# Recursive wildcard function
# http://blog.jgc.org/2011/07/gnu-make-recursive-wildcard-function.html
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) \
  $(filter $(subst *,%,$2),$d))

# Not used, but keep it here, in case of...
# map = $(foreach a,$(2),$(call $(1),$(a)))

## MODULE RULES
define MODULE_RULES

$(1)_PATH						:=	src/$(1)
$(1)_SOURCES					:=	$$(call rwildcard,$$($(1)_PATH),*.rs)
$(1)_DEPS_NAMES					:=	$$(foreach dep,$$($(1)_DEPS),$(RUST_BUILDDIR)/.build_$$(dep))

ifneq ($$(wildcard $$($(1)_PATH)/main.rs),)
$(1)_TYPE						:=	bin
$(1)_MAIN_SOURCE				:=	$$($(1)_PATH)/main.rs
else ifneq ($$(wildcard $$($(1)_PATH)/lib.rs),)
$(1)_TYPE						:=	lib
$(1)_MAIN_SOURCE				:=	$$($(1)_PATH)/lib.rs
$(1)_LIB						:=	$$(wildcard $(RUST_LIBDIR)/lib$(1)-*.so)
else
$$(error Unkown module type: $(1))
endif

ifneq ($$(wildcard $$($(1)_PATH)/test.rs),)
$(1)_TESTNAME					:=	$(RUST_BUILDDIR)/test_$(1)
else
$(1)_TESTNAME					:=
endif

$(1):							$(RUST_BUILDDIR)/.build_$(1)
.PHONY:							$(1)

$(RUST_BUILDDIR)/.build_$(1):	$$($(1)_DEPS_NAMES) $$($(1)_SOURCES)
ifeq ($$($(1)_TYPE),bin)
	$$(RUSTC) $$(RUSTCFLAGS) -o $(1) $$($(1)_MAIN_SOURCE)
else ifeq ($$($(1)_TYPE),lib)
	@mkdir -p $(RUST_LIBDIR)
	$$(RUSTC) $$(RUSTCFLAGS) --lib --out-dir $(RUST_LIBDIR) $$($(1)_MAIN_SOURCE)
endif
	@touch $(RUST_BUILDDIR)/.build_$(1)

clean_$(1):
ifeq ($$($(1)_TYPE),bin)
	@rm -f $(1)
else ifeq ($$($(1)_TYPE),lib)
	@rm -f $$($(1)_LIB)
endif
	@rm -f $(RUST_BUILDDIR)/.build_$(1)
.PHONY:							clean_$(1)

test_$(1):						$$($(1)_TESTNAME)
ifneq ($$(wildcard $$($(1)_PATH)/test.rs),)
	@$$($(1)_TESTNAME)
endif

bench_$(1):						$$($(1)_TESTNAME)
ifneq ($$(wildcard $$($(1)_PATH)/test.rs),)
	@$$($(1)_TESTNAME) --bench
endif

ifneq ($$(wildcard $$($(1)_PATH)/test.rs),)
$$($(1)_TESTNAME):				$$($(1)_SOURCES)
	$$(RUSTC) $$(RUSTCFLAGS) --test -o $$($(1)_TESTNAME) $$($(1)_PATH)/test.rs
endif

endef

## RULES
all:							$(RUST_BUILDDIR) $(RUST_MODULES)

clean:							$(addprefix clean_,$(RUST_MODULES))
	@rm -rf $(RUST_BUILDDIR) $(RUST_LIBDIR)

test:							$(addprefix test_,$(RUST_MODULES))

bench:							$(addprefix bench_,$(RUST_MODULES))

$(foreach mod,$(RUST_MODULES),$(eval $(call MODULE_RULES,$(mod))))

$(RUST_BUILDDIR):
	@mkdir -p $(RUST_BUILDDIR)

.PHONY:							all clean test bench