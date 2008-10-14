SOURCES  := $(wildcard *.st)
DEMOS    := $(SOURCES:%.st=%.elf)
BOOTLIBS := libobjects.a libossage.a libofw.a
BOOTFILES := ${BOOTLIBS:%=${IDST_DIR}/function/examples/xo/%}

all: check $(DEMOS)

%.elf: %.st
	${IDST_DIR}/function/examples/idc -XO -XS -o $@ $<  $(BOOTFILES) -lgcc
	strip $@

clean:
	-rm $(DEMOS)

check:
	[ -n "${IDST_DIR}" ] || echo "Please set the IDST_DIR environment variable."

