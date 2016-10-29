# Name of the binaries.
PROJ_NAME=stm32-template

######################################################################
#                         SETUP TOOLS                                #
######################################################################

# Board/CPU info
CPU_FAMILY_UC = STM32F4xx
CPU_FAMILY_LC = stm32f4xx
CPU_LINE_UC   = STM32F411xE
CPU_LINE_LC   = stm32f411xe
CPU_NAME      = STM32F411RETx

# The tools we use
CC      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
GDB     = arm-none-eabi-gdb
AS      = arm-none-eabi-as

## Preprocessor options

# directories to be searched for header files
INCLUDE = $(addprefix -I,$(INC_DIRS))

### defines needed when working with the STM library
DEFS    = -DUSE_STDPERIPH_DRIVER
# if you use the following option, you must implement the function
#    assert_failed(uint8_t* file, uint32_t line)
# because it is conditionally used in the library
# DEFS   += -DUSE_FULL_ASSERT

##### Assembler options

AFLAGS  = -mcpu=cortex-m4
AFLAGS += -mthumb
AFLAGS += -mthumb-interwork
AFLAGS += -mlittle-endian
AFLAGS += -mfloat-abi=hard
AFLAGS += -mfpu=fpv4-sp-d16

## Compiler options

CFLAGS  = --specs=nosys.specs
CFLAGS += -ggdb
# please do not optimize anything because we are debugging
CFLAGS += -O0
CFLAGS += -Wall -Wextra -Warray-bounds
CFLAGS += $(AFLAGS)
CFLAGS += -D$(CPU_LINE_UC)

## Linker options

# tell ld which linker file to use
LFLAGS  = -T./SW4STM32/$(PROJ_NAME)/$(CPU_NAME)_FLASH.ld


######################################################################
#                         SETUP SOURCES                              #
######################################################################

# This is where the source files are located,
# which are not in the current directory
# (the sources of the standard peripheral library, which we use)
# see also "info:/make/Selective Search" in Konqueror
MY_SRC_DIR       = ./Src
STM_SRC_DIR      = ./Drivers/CMSIS/Device/ST/$(CPU_FAMILY_UC)/Source/Templates/gcc
STM_SRC_DIR     += ./Drivers/CMSIS/Device/ST/$(CPU_FAMILY_UC)/Source/Templates
STM_SRC_DIR     += ./Drivers/$(CPU_FAMILY_UC)_HAL_Driver/Src/
STM_STARTUP_DIR += ./Drivers/CMSIS/Device/ST/$(CPU_FAMILY_UC)/Source/Templates/gcc/

# Tell make to look in that folder if it cannot find a source
# in the current directory
vpath %.c $(MY_SRC_DIR)
vpath %.c $(STM_SRC_DIR)
vpath %.s $(STM_STARTUP_DIR)


################################################################################
#                         SETUP HEADER FILES                                   #
################################################################################

# The header files we use are located here
INC_DIRS  = ./Inc
INC_DIRS += ./Drivers/CMSIS/Device/ST/$(CPU_FAMILY_UC)/Include/
INC_DIRS += ./Drivers/CMSIS/Include/
INC_DIRS += ./Drivers/$(CPU_FAMILY_UC)_HAL_Driver/Inc/


################################################################################
#                   SOURCE FILES TO COMPILE                                    #
################################################################################

# My source file
SRCS   = main.c

# Files containing initialisation code and must be compiled into
# our project.
# Some files are in the same folder of main source file
SRCS  += $(CPU_FAMILY_LC)_it.c
SRCS  += $(CPU_FAMILY_LC)_hal.c
# others are produced by STCubeMX (or can be downloaded from ST website)
SRCS  += system_$(CPU_FAMILY_LC).c
SRCS  += $(CPU_FAMILY_LC)_hal_gpio.c
SRCS  += $(CPU_FAMILY_LC)_hal_rcc.c
SRCS  += $(CPU_FAMILY_LC)_hal_msp.c
SRCS  += $(CPU_FAMILY_LC)_hal_pwr.c
SRCS  += $(CPU_FAMILY_LC)_hal_cortex.c
# example of other files...
#SRCS  += $(CPU_FAMILY_LC)_hal_rtc.c
#SRCS  += $(CPU_FAMILY_LC)_hal_usart.c

# Startup file written by ST
# The assembly code in this file is the first one to be
# executed. Normally you do not change this file.
ASRC = startup_$(CPU_LINE_LC).s

# in case we have to many sources and don't want
# to compile all sources every time
OBJS = $(SRCS:.c=.o)
OBJS += $(ASRC:.s=.o)


######################################################################
#                         SETUP TARGETS                              #
######################################################################

TEMP_DIR = ./temp
OUT_DIR = ./out

.PHONY: all

all: $(PROJ_NAME).elf
	@echo -e "\nDone!"

%.o : %.c
	@echo "[Compiling  ]  $^"
	@mkdir -p ${TEMP_DIR}
	@$(CC) -c -o $(TEMP_DIR)/$@ $(INCLUDE) $(DEFS) $(CFLAGS) $^

%.o : %.s
	@echo "[Assembling ] $^"
	@mkdir -p ${TEMP_DIR}
	@$(AS) $(AFLAGS) $< -o $(TEMP_DIR)/$@

$(PROJ_NAME).elf: $(OBJS)
	@echo "[Linking    ]  $@"
	@mkdir -p ${OUT_DIR}
	@$(CC) $(CFLAGS) $(LFLAGS) $(foreach file, $^, $(TEMP_DIR)/$(file)) -o $(OUT_DIR)/$@
	@$(OBJCOPY) -O ihex $(OUT_DIR)/$(PROJ_NAME).elf   $(OUT_DIR)/$(PROJ_NAME).hex
	@$(OBJCOPY) -O binary $(OUT_DIR)/$(PROJ_NAME).elf $(OUT_DIR)/$(PROJ_NAME).bin

clean:
	@rm -f *.o $(OUT_DIR)/* $(TEMP_DIR)/*

flash: all
	st-flash write $(OUT_DIR)/$(PROJ_NAME).bin 0x8000000

debug:
# before you start gdb, you must start st-util
	@read -p "start st-util, then press enter..." -n1 -s
	$(GDB) --eval-command="target remote localhost:4242" -tui $(OUT_DIR)/$(PROJ_NAME).elf
