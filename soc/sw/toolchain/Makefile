#Makefile for building OR1200 tool-chains
#Version 0.1 by Tao Xiao
#Date: 23/02/2009
#
##Versions
BINUTILS    :=binutils-2.16.1
GCC         :=gcc-3.4.4
LINUX       :=linux-2.6.23
SIM         :=or1ksim-0.2.0
GDB         :=gdb-6.8
UCLIC       :=uClibc-0.9.28.3
BUSYBOX     :=busybox-1.7.5

sub-tools := $(BINUTILS) $(GCC) $(LINUX) $(SIM) $(GDB)
PHONY :=
PHONY += sub-tools

##Patches
$(BINUTILS)-PATCH     :=$(BINUTILS)_unified.diff_rgd_fixed.bz2
$(GCC)-PATCH          :=$(GCC)-or32-unified.diff.bz2
$(LINUX)-PATCH        :=linux_2.6.23_or32_unified_simtested.bz2
$(GDB)-PATCH          :=or32-gdb-6.8-patch-2.0.bz2
$(SIM)-PATCH          :=or1ksim-0.2.0-patch-2.0.bz2

$(UCLIC)-PATCH1       :=uClibc-0.9.28-or32-unified.bz2
$(UCLIC)-PATCH2       :=uClibc-0.9.28-or32-libc-support.bz2
$(UCLIC)-PATCH3       :=embecosm-esp2-or32-uclibc-0.9.28.3-patch-2.0.bz2

##Configs
CONFIG1         :=rgd_uc_28_2.6.23_dotconfig
CONFIG2         :=rgd_bb_1.75dotconfig
CONFIG3         :=DOT_CONFIG_2.6.23_OR32

##Tarballs (for some goddam reason passing -j to tar sometimes corrupts files)
INITRD_FB       :=initrd-fb-03.ext2.last.work.1.7.5.bz2
SIM_GDB         :=sim_gdb.cfg

##Log file name
LOGFILE         :=$(CURDIR)/install.log

HOST            ?=linuxdevel.3322.org
ULAB_ORSOC_DIR  ?=ftp/OpenRISC/toolchain

FILELIST += $($(BINUTILS)-PATCH) $($(GCC)-PATCH) $($(LINUX)-PATCH) $($(GDB)-PATCH) $($(SIM)-PATCH) \
			$($(UCLIC)-PATCH1) $($(UCLIC)-PATCH2) $($(UCLIC)-PATCH3)

FILELIST += $(INITRD_FB) $(patsubst %, %.tar.bz2, $(sub-tools) $(UCLIC) $(BUSYBOX))

FILELIST += $(CONFIG1) $(CONFIG2) $(CONFIG3) $(SIM_GDB)

PHONY += $(FILELIST)
$(FILELIST) : FORCE $(DOWNLOAD_DIR)
		@cd $(DOWNLOAD_DIR) ; [ -f $@ ] || wget $(HOST)/$(ULAB_ORSOC_DIR)/$@

PHONY += BUILD_DIR DOWNLOAD_DIR
BUILD_DIR    := $(CURDIR)/build
DOWNLOAD_DIR := $(CURDIR)/download

export PATH := $(BUILD_DIR)/tools/or32-uclinux/bin:$(PATH)

$(BUILD_DIR) $(DOWNLOAD_DIR) : FORCE
		@[ -d $@ ] || mkdir $@

$(sub-tools)  : $(DOWNLOAD_DIR) $(BUILD_DIR) $(FILELIST)
		@cd $(BUILD_DIR);\
			[ -d $@ ] || { \
			tar jxf $(DOWNLOAD_DIR)/$@.tar.bz2 ;\
			cd $@;\
			bzip2 -dc $(DOWNLOAD_DIR)/$($@-PATCH) | patch -p1; }

$(BUSYBOX)    : $(DOWNLOAD_DIR) $(BUILD_DIR) $(FILELIST)
		@cd $(BUILD_DIR);\
			[ -d $@ ] || { \
			tar jxf $(DOWNLOAD_DIR)/$@.tar.bz2;\
			cp $(DOWNLOAD_DIR)/$(CONFIG2) $(BUILD_DIR)/$(BUSYBOX)/.config;\
			cp $(DOWNLOAD_DIR)/$(CONFIG2) $(BUILD_DIR)/$(BUSYBOX)/.config.old;}
			
$(UCLIC)      : $(DOWNLOAD_DIR) $(BUILD_DIR) $(FILELIST)
		@cd $(BUILD_DIR);\
			[ -d $@ ] || { ;\
			tar jxf $(DOWNLOAD_DIR)/$@.tar.bz2;\
			cd $@;
			bzip2 -dc $(DOWNLOAD_DIR)/$($(UCLIC)-PATCH1) | patch -p1;\
			cd libc;\
			bzip2 -dc $(DOWNLOAD_DIR)/$($(UCLIC)-PATCH2) | patch -p1;\
			cd ..;\
			bzip2 -dc $(DOWNLOAD_DIR)/$($(UCLIC)-PATCH3) | patch -p1;\
			sed -r "s:KERNEL_SOURCE=.*:KERNEL_SOURCE=\"$(BUILD_DIR)/$(LINUX)\":" \
				$(DOWNLOAD_DIR)/$(CONFIG1) > $(BUILD_DIR)/$(UCLIC)/.config;\
			cp $(BUILD_DIR)/$(UCLIC)/.config  $(BUILD_DIR)/$(UCLIC)/.config.old;\
			make oldconfig;\
			ln -s extra/Configs/Config.or32 Config ;}

PHONY += prepare
prepare : $(sub-tools) $(UCLIC) $(BUSYBOX)

PHONY += tools 
tools	: prepare binutils gcc libc gcc_final sim linux_final gdb busybox FORCE

PHONY += binutils
binutils: $(BINUTILS) prepare
		@[ -d $(BUILD_DIR)/b-b ] || { \
			mkdir $(BUILD_DIR)/b-b;\
			cd $(BUILD_DIR)/b-b;\
			$(BUILD_DIR)/$(BINUTILS)/configure --target=or32-uclinux \
				--prefix=$(BUILD_DIR)/tools/or32-uclinux;}
		$(MAKE) -C $(BUILD_DIR)/b-b -j4 all
		$(MAKE) -C $(BUILD_DIR)/b-b install

PHONY += linux_prepare
linux_prepare: $(LINUX) prepare
		@cp $(DOWNLOAD_DIR)/$(CONFIG3) $(BUILD_DIR)/$(LINUX)/.config
		$(MAKE) -C $(BUILD_DIR)/$(LINUX) oldconfig

PHONY += gcc_prepare
gcc_prepare: $(LINUX) prepare
		@cd $(BUILD_DIR);\
			[ -d tools/or32-uclinux/include ] || { \
			mkdir tools/or32-uclinux/include;\
			cd tools/or32-uclinux/;\
			ln -s include sys-include;\
			mkdir asm linux;\
			cp -f -dR $(BUILD_DIR)/$(LINUX)/include/linux/* linux;\
			cp -f -dR $(BUILD_DIR)/$(LINUX)/include/asm-or32/* asm;}

gcc        : $(GCC) gcc_prepare prepare
		@[ -d $(BUILD_DIR)/b-gcc ] || { \
			mkdir $(BUILD_DIR)/b-gcc;\
			cd $(BUILD_DIR)/b-gcc;\
			$(BUILD_DIR)/$(GCC)/configure --target=or32-uclinux \
				--prefix=$(BUILD_DIR)/tools/or32-uclinux \
				--with-local-prefix=$(BUILD_DIR)/tools/or32-uclinux/or32-uclinux \
				--enable-languages=c;}
		$(MAKE) -C $(BUILD_DIR)/b-gcc -j4 all
		$(MAKE) -C $(BUILD_DIR)/b-gcc install

PHONY += linux
linux   : linux_prepare
		$(MAKE) -C $(BUILD_DIR)/$(LINUX) -j4 vmlinux ARCH=or32 CROSS_COMPILE=or32-uclinux-

PHONY += libc
libc    : $(UCLIC) prepare
		$(MAKE) -C $(BUILD_DIR)/$(UCLIC) CC=or32-uclinux-gcc -j4 all
		$(MAKE) -C $(BUILD_DIR)/$(UCLIC) CC=or32-uclinux-gcc install

PHONY += gcc_final
gcc_final : libc
		@cd $(BUILD_DIR)/b-gcc;\
			$(BUILD_DIR)/$(GCC)/configure --target=or32-uclinux --prefix=$(BUILD_DIR)/tools/or32-uclinux \
					--with-local-prefix=$(BUILD_DIR)/tools/or32-uclinux/or32-uclinux --enable-languages=c
		$(MAKE) -C $(BUILD_DIR)/b-gcc -j4 all
		$(MAKE) -C $(BUILD_DIR)/b-gcc install
		@cd $(BUILD_DIR)/tools/or32-uclinux/or32-uclinux;\
			ln -s ../include sys-include;\
			cd lib;\
			cp -f -dR ../../lib/* .

PHONY += gdb
gdb : $(GDB)
		@cd $(BUILD_DIR)/$(GDB);\
			./configure --target=or32-uclinux --prefix=$(BUILD_DIR)/tools/or32-uclinux
		$(MAKE) -C $(BUILD_DIR)/$(GDB) all
		$(MAKE) -C $(BUILD_DIR)/$(GDB) install

PHONY += linux_final
linux_final : gcc_final linux
		$(MAKE) -C $(BUILD_DIR)/$(LINUX) -j4 vmlinux ARCH=or32 CROSS_COMPILE=or32-uclinux-

PHONY += sim
sim        : $(SIM)
		@cd $(BUILD_DIR)/$(SIM);\
			./configure --target=or32-uclinux --prefix=$(BUILD_DIR)/tools/or32-uclinux;\
		$(MAKE) -C $(BUILD_DIR)/$(SIM) -j4 all
		$(MAKE) -C $(BUILD_DIR)/$(SIM) install

PHONY += busybox
busybox   : $(BUSYBOX)
		$(MAKE) -C $(BUILD_DIR)/$(BUSYBOX) -j4 ARCH=or32 CROSS_COMPILE=or32-uclinux-
		$(MAKE) -C $(BUILD_DIR)/$(BUSYBOX) install ARCH=or32 CROSS_COMPILE=or32-uclinux-

PHONY += FORCE
FORCE:

.PHONY : $(PHONY)
