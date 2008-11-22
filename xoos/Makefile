MAIN     := XOOS1.st
LIBS     := Extension Geode Keyboard Mouse OFW Wifi Test
LIB_OBJS := $(LIBS:%=%.o)
BOOTLIBS := libobjects.a libossage.a libofw.a
BOOTFILES := ${BOOTLIBS:%=${IDST_DIR}/function/examples/xo/%}

all: check xoos1

xoos1: XOOS1.st $(LIB_OBJS)
	${IDST_DIR}/function/examples/idc -XO -XS -o $@ XOOS1.st $(LIB_OBJS) $(SOURCES) $(BOOTFILES) -lgcc
	strip $@

%.o: %.st
	${IDST_DIR}/function/examples/idc -XO -o $@ -c $<

clean:
	-rm $(DEMOS)

check:
	[ -n "${IDST_DIR}" ] || echo "Please set the IDST_DIR environment variable."

