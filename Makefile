#License: GPL-2.0
# A Makefile written by Hu Jia <utopian.zukunft@gmail.com>
#(C) 2019 Hu Jia
##Project name (ohne empty-space)
TARGET		= LED
BUILDDIR	= ./build/
USER_DIR	= ./User/$(TARGET)/
TargetELF	:= $(TARGET).elf
TargetBIN	:= $(TARGET).bin
Openocd_Interf	:= interface/cmsis-dap.cfg
Openocd_Target	:= target/stm32f4x.cfg
# Pre-defined about MCU
# ARMv6-M	---	Cortex-M0(+)
# ARMv7-M	---	Cortex-M1
# ARMv7-M_noFP	---	Cortex_M3
# ARMv7-M_sfFP	---	Cortex_M4
# ARMv7-M_hdFP	---	Cortex_M4
ARCH	:= ARMv7E-M_hdFP

# defined(STM32F40_41xxx) || defined(STM32F427_437xx) || defined(STM32F429_439xx) 
# defined(STM32F469_479xx) || defined(STM32F413_423xx)

MCU	:= STM32F429_439xx

# Ld script: Copy the ld script from ./Project/*Template/$(MCU)/*FLASH.ld
# Modify the content: the size of _estack,FLASH, RAM, CCMRAM.
# You can also redirect the location of your program.  
# This ld script is borrowed from TrueSTUDIO, you'd better write your own's.

FlashLD	= STM32_FLASH.ld

# Compilation's tool confirm, ld uses gcc to avoid some error.
AS	:= arm-none-eabi-as
CC	:= arm-none-eabi-gcc
AR	:= arm-none-eabi-ar
LD	:= arm-none-eabi-gcc
OBJCOPY	:= arm-none-eabi-objcopy

# Compilation's flag define, some flags is related to your mcu core.
ifeq ($(ARCH),ARMv6-M)
CPUFLAGS := -mthumb -march=armv6-m
endif

ifeq ($(ARCH),ARMv7-M)
CPUFLAGS := -mthumb -march=armv7-m
endif

ifeq ($(ARCH),ARMv7E-M_noFP)
CPUFLAGS := -mthumb -march=armv7e-m
endif

ifeq ($(ARCH),ARMv7E-M_sfFP)
CPUFLAGS := -mthumb -march=armv7e-m -mfloat-abi=softfp -mfpu=fpv4-sp-d16
endif

ifeq ($(ARCH),ARMv7E-M_hdFP)
CPUFLAGS := -mthumb -march=armv7e-m -mfloat-abi=hard -mfpu=fpv4-sp-d16
endif

# GCC Flags
# Macro define to using specified MCU and Standard Libraries
CFLAGS	:= -D $(MCU) -D USE_STDPERIPH_DRIVER -Wall -g -o0
#		-D,	Macro_define for preprocessor
#		-g,	generate debug information
#		-o0,	no optimization

LDFLAGS	:= -T $(FlashLD) \
	-Wl,-Map=$(TARGET).map \
	-Wl,-cref,-u,Reset_Handler \
	-Wl,--defsym=malloc_getpagesize_P=0x80\
	-Wl,--gc-sections\
	-Wl,--start-group -lc_nano -lm -specs=nosys.specs\
	-Wl,--end-group
#	-Map,	print a link map
#	-cref,	output a cross reference table 
#	--ge-section	decides which input sectionns are used by examing symbols and relocations
#       --start-group --end-group lc_nano small_libc, -specs=nosys.specs no system, -lm math lib

# Include Files
# Turn all the letter in MCU in lower case, because startup code ist *stmf*.s, all lower case.
LowCase_MCU := `echo $(MCU) | tr A-Z a-z`

#shell command to find all the relevant file
#All the include file
Periph_inc := $(shell find Libraries/ -name "*StdPeriph_Driver*")
Device_inc := $(shell find Libraries/CMSIS/Device -type d -name "Include")
INCLUDE	= -I User/$(TARGET) \
	  -I Libraries/CMSIS/Include\
	  -I $(Device_inc) \
	  -I $(Periph_inc)/inc
#All the source file
# .s bootcode
Startup_s += $(shell find ./Libraries/ -name "*TrueSTUDIO*" -exec find {} -name "*$(LowCase_MCU)*.s" \;)
# .c, StdPeriph_Driver, Device_startup, User_Code
Lib_c += $(shell find ./Libraries/ -name "*StdPeriph_Driver*" -exec find {} -name "*.c" \;)
Device_c += $(shell find ./Libraries/ -name "Templates" -exec find {} -name "*.c" \;)
User_c += $(shell find $(USER_DIR) -name "*.c")

Startup_s_dir = $(firstword $(dir $(Startup_s)))
Lib_c_dir = $(firstword $(dir $(Lib_c)))
Device_c_dir = $(firstword $(dir $(Device_c)))
User_c_dir = $(firstword $(dir $(User_c)))

# MCU STM32F429IGT6 doesn't need fsmc.c 
Lib_c := $(filter-out %fsmc.c,$(Lib_c))

# extract the dir from the filepath and clean repeated items.
Init_OBJ = $(addprefix $(BUILDDIR),$(patsubst %s,%o,$(notdir $(Startup_s))))
Lib_OBJ = $(addprefix $(BUILDDIR),$(patsubst %c,%o,$(notdir $(Lib_c))))
Device_OBJ = $(addprefix $(BUILDDIR),$(patsubst %c,%o,$(notdir $(Device_c))))
User_OBJ = $(addprefix $(BUILDDIR),$(patsubst %c,%o,$(notdir $(User_c))))


# Start compiling
#TargetELF	:= $(TARGET).elf
.PHONY: all
all: makedir $(TargetBIN)
	@echo "Project: $(TARGET) MCU:$(MCU)"

$(TargetBIN): $(TargetELF)
	$(OBJCOPY) $< $@

$(TargetELF):  $(Init_OBJ) $(Lib_OBJ) $(Device_OBJ) $(User_OBJ)
	$(LD) $(CPUFLAGS) $(LDFLAGS) $(CFLAGS) $^ -o $@ 

$(Init_OBJ) : $(BUILDDIR)%.o : $(Startup_s_dir)%.s
	$(AS) $(CPUFLAGS) -o $@ -c $<

$(Lib_OBJ) : $(BUILDDIR)%.o : $(Lib_c_dir)%.c
	$(CC) $(CPUFLAGS) $(INCLUDE) $(CFLAGS) -c $< -o $@

$(Device_OBJ) : $(BUILDDIR)%.o : $(Device_c_dir)%.c
	$(CC) $(CPUFLAGS) $(INCLUDE) $(CFLAGS) -c $< -o $@

$(User_OBJ) : $(BUILDDIR)%.o : $(User_c_dir)%.c
	$(CC) $(CPUFLAGS) $(INCLUDE) $(CFLAGS) -c $< -o $@


.PHONY: makedir
makedir: $(BUILDDIR)
	mkdir -p $(BUILDDIR) 

.PHONY: clean
clean:
	rm -r LED.* build/*

.PHONY: download
download:
	openocd -f $(Openocd_Interf) -f $(Openocd_Target) \
		-c init\
		-c halt\
		-c "flash write_image erase $(TargetBIN)"\
		-c reset\
		-c shutdown






