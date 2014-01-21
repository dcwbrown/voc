#SHELL := /bin/bash
BUILDID=$(shell date +%Y/%m/%d)
TOS = linux
TARCH = x86_64
#TARCH = x86 x86_64 armv6j armv6j_hardfp armv7a_hardfp powerpc
CCOMP = gnuc
RELEASE = 1.0


INCLUDEPATH = -Isrc/lib/system/$(CCOMP)/$(TARCH)

SETPATH = CFLAGS=$(INCLUDEPATH)  PATH=.:/bin:/usr/bin MODULES=.:src/lib:src/lib/v4:src/lib/v4/$(TARCH):src/lib/system:src/lib/system/$(CCOMP):src/lib/system/$(CCOMP)/$(TARCH):src/lib/ulm:src/lib/ulm/$(CCOMP):src/lib/ulm/$(TARCH):src/lib/ooc2:src/lib/ooc2/$(CCOMP):src/lib/ooc:src/lib/ooc/$(CCOMP):src/lib/pow:src/lib/misc:src/lib/s3:src/voc:src/voc/$(CCOMP):src/voc/$(CCOMP)/$(TARCH):src/tools/ocat:src/tools/browser:src/tools/vocparam:src/tools/vmake:src/tools/coco:src/test

VOC = voc
VOCSTATIC0 = $(SETPATH) ./vocstatic.$(TOS).$(CCOMP).$(TARCH)
VOCSTATIC = $(SETPATH) ./voc
VOCPARAM = $(shell ./vocparam > voc.par)
VERSION = GNU_Linux_$(TARCH)
LIBNAME = VishapOberon
LIBRARY = lib$(LIBNAME)

ifndef PREFIX
PREFIX = /opt/voc-$(RELEASE)
endif

CCOPT = -fPIC $(INCLUDEPATH) -g

CC = cc $(CCOPT) -c 
CL = cc $(CCOPT) 
LD = cc -shared -o $(LIBRARY).so
# s is necessary to create index inside a archive
ARCHIVE = ar rcs $(LIBRARY).a

#%.c: %.Mod
#%.o: %.c
#	$(CC) $(input)

all: stage2 stage3 stage4 stage5 stage6 stage7

# when porting to new platform:
# * put corresponding .par file into current directory. it can be generated on the target platform by compiling vocparam (stage0) and running (stage1)
# * run make port0 - this will generate C source files for the target architecture
# * move the source tree to the target machine, and compile (or compile here via crosscompiler) (port1)
port0: stage2 stage3 stage4

# now compile C source files for voc, showdef and ocat on target machine (or by using crosscompiler)
port1: stage5
# after you have "voc" compiled for target architecture. replace vocstatic with it and run make on target platform to get everything compiled

# this builds binary which generates voc.par
stage0: src/tools/vocparam/vocparam.c
	$(CL) -I src/lib -o vocparam src/tools/vocparam/vocparam.c

# this creates voc.par for a host architecture.
# comment this out if you need to build a compiler for a different architecture.
stage1: 
	#rm voc.par
	#$(shell "./vocparam > voc.par")
	#./vocparam > voc.par
	$(VOCPARAM)

# this copies necessary voc.par to the current directory.
# skip this if you are building compiler for the host architecture.
stage2:
	cp src/par/voc.par.$(CCOMP).$(TARCH) voc.par
#	cp src/par/voc.par.gnu.x86_64 voc.par
#	cp src/par/voc.par.gnu.x86 voc.par
#	cp src/par/voc.par.gnu.armv6 voc.par
#	cp src/par/voc.par.gnu.armv7 voc.par

# this prepares modules necessary to build the compiler itself
stage3:

	$(VOCSTATIC0) -siapxPS SYSTEM.Mod 
	$(VOCSTATIC0) -sPS Args.Mod Console.Mod Unix.Mod 
	$(VOCSTATIC0) -sPS oocOakStrings.Mod architecture.Mod version.Mod Kernel.Mod Modules.Mod
	$(VOCSTATIC0) -sxPS Files.Mod 
	$(VOCSTATIC0) -sxPS OakFiles.Mod 
	$(VOCSTATIC0) -sPS Reals.Mod CmdlnTexts.Mod errors.Mod

# build the compiler
stage4:
	$(VOCSTATIC0) -sPS extTools.Mod
	$(VOCSTATIC0) -sPS OPM.cmdln.Mod 
	$(VOCSTATIC0) -sxPS OPS.Mod 
	$(VOCSTATIC0) -sPS OPT.Mod OPC.Mod OPV.Mod OPB.Mod OPP.Mod
	$(VOCSTATIC0) -smPS voc.Mod
	$(VOCSTATIC0) -smPS BrowserCmd.Mod
	$(VOCSTATIC0) -smPS OCatCmd.Mod
	$(VOCSTATIC0) -sPS compatIn.Mod
	$(VOCSTATIC0) -smPS vmake.Mod

#this is to build the compiler from C sources.
#this is a way to create a bootstrap binary.
stage5:
	$(CC) SYSTEM.c Args.c Console.c Modules.c Unix.c \
	oocOakStrings.c architecture.c version.c Kernel.c Files.c OakFiles.c Reals.c CmdlnTexts.c \
	version.c extTools.c \
	OPM.c OPS.c OPT.c OPC.c OPV.c OPB.c OPP.c errors.c

	$(CL) -static  voc.c -o voc \
	SYSTEM.o Args.o Console.o Modules.o Unix.o \
	oocOakStrings.o architecture.o version.o Kernel.o Files.o Reals.o CmdlnTexts.o \
	extTools.o \
	OPM.o OPS.o OPT.o OPC.o OPV.o OPB.o OPP.o errors.o
	$(CL) BrowserCmd.c -o showdef \
	SYSTEM.o Args.o Console.o Modules.o Unix.o oocOakStrings.o architecture.o version.o Kernel.o Files.o Reals.o CmdlnTexts.o \
	OPM.o OPS.o OPT.o OPV.o OPC.o errors.o

	$(CL) OCatCmd.c -o ocat \
	SYSTEM.o Args.o Console.o Modules.o Unix.o oocOakStrings.o architecture.o version.o Kernel.o Files.o Reals.o CmdlnTexts.o
	
	$(CC) compatIn.c
	$(CL) vmake.c -o vmake SYSTEM.o Args.o compatIn.o CmdlnTexts.o Console.o Files.o Reals.o Modules.o Kernel.o Unix.o oocOakStrings.o version.o architecture.o


# build all library files
stage6:
	#more v4 libs
	$(VOCSTATIC) -sP	Printer.Mod
	$(VOCSTATIC) -sP	Strings.Mod

	#ooc libs
	$(VOCSTATIC) -sP	oocAscii.Mod
	$(VOCSTATIC) -sP	oocStrings.Mod
	$(VOCSTATIC) -sP	oocStrings2.Mod
	$(VOCSTATIC) -sP	oocCharClass.Mod
	$(VOCSTATIC) -sP	oocConvTypes.Mod
	$(VOCSTATIC) -sP	oocIntConv.Mod
	$(VOCSTATIC) -sP	oocIntStr.Mod
	$(VOCSTATIC) -sP	oocSysClock.Mod
	$(VOCSTATIC) -sP	oocTime.Mod
#	$(VOCSTATIC) -s	oocLongStrings.Mod
#	$(CC)		oocLongStrings.c
#	$(VOCSTATIC) -s	oocMsg.Mod
#	$(CC)		oocMsg.c


	#ooc2 libs
	$(VOCSTATIC) -sP ooc2Strings.Mod
	$(VOCSTATIC) -sP ooc2Ascii.Mod
	$(VOCSTATIC) -sP ooc2CharClass.Mod
	$(VOCSTATIC) -sP ooc2ConvTypes.Mod
	$(VOCSTATIC) -sP ooc2IntConv.Mod
	$(VOCSTATIC) -sP ooc2IntStr.Mod
	$(VOCSTATIC) -sP ooc2Real0.Mod
	#ooc libs
	$(VOCSTATIC) -sP oocLowReal.Mod oocLowLReal.Mod
	$(VOCSTATIC) -sP oocRealMath.Mod oocOakMath.Mod
	$(VOCSTATIC) -sP oocLRealMath.Mod
	$(VOCSTATIC) -sP oocLongInts.Mod
	$(VOCSTATIC) -sP oocComplexMath.Mod oocLComplexMath.Mod
	$(VOCSTATIC) -sP oocLRealConv.Mod oocLRealStr.Mod
	$(VOCSTATIC) -sP oocRealConv.Mod oocRealStr.Mod
	$(VOCSTATIC) -sP oocMsg.Mod oocChannel.Mod
	$(VOCSTATIC) -sP oocStrings2.Mod oocRts.Mod oocFilenames.Mod
	$(VOCSTATIC) -sP oocTextRider.Mod oocBinaryRider.Mod oocJulianDay.Mod
	$(VOCSTATIC) -sP oocFilenames.Mod
	$(VOCSTATIC) -sP oocwrapperlibc.Mod

	#Ulm's Oberon system libs
	$(VOCSTATIC) -sP ulmSys.Mod
	$(VOCSTATIC) -sP ulmSYSTEM.Mod
	$(VOCSTATIC) -sP ulmASCII.Mod
	$(VOCSTATIC) -sP ulmSets.Mod
	$(VOCSTATIC) -sP ulmObjects.Mod
	$(VOCSTATIC) -sP ulmDisciplines.Mod
	$(VOCSTATIC) -sP ulmPriorities.Mod
	$(VOCSTATIC) -sP ulmServices.Mod
	$(VOCSTATIC) -sP ulmEvents.Mod
	$(VOCSTATIC) -sP ulmResources.Mod
	$(VOCSTATIC) -sP ulmForwarders.Mod
	$(VOCSTATIC) -sP ulmRelatedEvents.Mod
	$(VOCSTATIC) -sP ulmIO.Mod
	$(VOCSTATIC) -sP ulmProcess.Mod
	$(VOCSTATIC) -sP ulmTypes.Mod
	$(VOCSTATIC) -sP ulmStreams.Mod
	$(VOCSTATIC) -sP ulmAssertions.Mod
	$(VOCSTATIC) -sP ulmIndirectDisciplines.Mod
	$(VOCSTATIC) -sP ulmStreamDisciplines.Mod
	$(VOCSTATIC) -sP ulmIEEE.Mod
	$(VOCSTATIC) -sP ulmMC68881.Mod
	$(VOCSTATIC) -sP ulmReals.Mod
	$(VOCSTATIC) -sP ulmPrint.Mod
	$(VOCSTATIC) -sP ulmWrite.Mod
	$(VOCSTATIC) -sP ulmTexts.Mod
	$(VOCSTATIC) -sP ulmStrings.Mod
	$(VOCSTATIC) -sP ulmConstStrings.Mod
	$(VOCSTATIC) -sP ulmPlotters.Mod
	$(VOCSTATIC) -sP ulmSysTypes.Mod
	$(VOCSTATIC) -sP ulmSysConversions.Mod
	$(VOCSTATIC) -sP ulmErrors.Mod
	$(VOCSTATIC) -sP ulmSysErrors.Mod
	$(VOCSTATIC) -sP ulmSysIO.Mod
	$(VOCSTATIC) -sP ulmLoader.Mod
	$(VOCSTATIC) -sP ulmNetIO.Mod
	$(VOCSTATIC) -sP ulmPersistentObjects.Mod
	$(VOCSTATIC) -sP ulmPersistentDisciplines.Mod
	$(VOCSTATIC) -sP ulmOperations.Mod
	$(VOCSTATIC) -sP ulmScales.Mod
	$(VOCSTATIC) -sP ulmTimes.Mod
	$(VOCSTATIC) -sP ulmClocks.Mod
	$(VOCSTATIC) -sP ulmTimers.Mod
	$(VOCSTATIC) -sP ulmConditions.Mod
	$(VOCSTATIC) -sP ulmStreamConditions.Mod
	$(VOCSTATIC) -sP ulmTimeConditions.Mod
	$(VOCSTATIC) -sP ulmSysConversions.Mod
	$(VOCSTATIC) -sP ulmSysStat.Mod
	$(VOCSTATIC) -sP ulmCiphers.Mod
	$(VOCSTATIC) -sP ulmCipherOps.Mod
	$(VOCSTATIC) -sP ulmBlockCiphers.Mod
	
	
	#pow32 libs
	$(VOCSTATIC) -sP powStrings.Mod

	#misc libs
	$(VOCSTATIC) -sP MultiArrays.Mod
	$(VOCSTATIC) -sP MultiArrayRiders.Mod
	$(VOCSTATIC) -sP MersenneTwister.Mod
	
	#s3 libs
	$(VOCSTATIC) -sP ethBTrees.Mod
	$(VOCSTATIC) -sP ethMD5.Mod
	$(VOCSTATIC) -sP ethSets.Mod
	$(VOCSTATIC) -sP ethZlib.Mod
	$(VOCSTATIC) -sP ethZlibBuffers.Mod
	$(VOCSTATIC) -sP ethZlibInflate.Mod
	$(VOCSTATIC) -sP ethZlibDeflate.Mod
	$(VOCSTATIC) -sP ethZlibReaders.Mod
	$(VOCSTATIC) -sP ethZlibWriters.Mod
	$(VOCSTATIC) -sP ethZip.Mod
	$(VOCSTATIC) -sP ethRandomNumbers.Mod
	$(VOCSTATIC) -sP ethGZReaders.Mod
	$(VOCSTATIC) -sP ethGZWriters.Mod


stage7:
	#objects := $(wildcard *.o)
	#$(LD) objects
	$(ARCHIVE) *.o 
	#$(ARCHIVE) objects
	$(LD) *.o
	echo "$(PREFIX)/lib" > 05vishap.conf

clean:
#	rm_objects := rm $(wildcard *.o)
#	objects
	rm *.o
	rm *.so
	rm *.h
	rm *.c
	rm *.a
	rm *.sym

install:
	test -d $(PREFIX)/bin | mkdir -p $(PREFIX)/bin
	cp voc $(PREFIX)/bin/
	cp showdef $(PREFIX)/bin/
	cp ocat $(PREFIX)/bin/
	cp vmake $(PREFIX)/bin/
	cp -a src $(PREFIX)/

	test -d $(PREFIX)/lib/voc | mkdir -p $(PREFIX)/lib/voc
	test -d $(PREFIX)/lib/voc/ | mkdir -p $(PREFIX)/lib/voc
	test -d $(PREFIX)/lib/voc/obj | mkdir -p $(PREFIX)/lib/voc/obj
	test -d $(PREFIX)/lib/voc/sym | mkdir -p $(PREFIX)/lib/voc/sym

	cp $(LIBRARY).so $(PREFIX)/lib
	cp $(LIBRARY).a $(PREFIX)/lib
	cp *.c $(PREFIX)/lib/voc/obj/
	cp *.h $(PREFIX)/lib/voc/obj/
	cp *.sym $(PREFIX)/lib/voc/sym/

	cp 05vishap.conf /etc/ld.so.conf.d/
	ldconfig

#        cp *.o $(PREFIX)/lib/voc/$(RELEASE)/obj/
uninstall:
	rm -rf $(PREFIX)
