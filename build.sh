#!/bin/bash

BUILD_PREFIX_DIR=.

BOARD=esp32-devkitc
CONFIG=wifi
#CONFIG=nsh

#BOARD=sim
#CONFIG=vpnkit

NUTTX_DIR=${BUILD_PREFIX_DIR}/nuttx
NUTTX_GIT_URL=https://github.com/apache/incubator-nuttx
NUTTX_GIT_TAG=releases/12.6
#NUTTX_GIT_TAG=master

NUTTX_APPS_DIR=${BUILD_PREFIX_DIR}/apps
NUTTX_APPS_GIT_URL=https://github.com/apache/incubator-nuttx-apps
NUTTX_APPS_GIT_TAG=releases/12.6
#NUTTX_APPS_GIT_TAG=master

NUTTX_APPS_EXTERNAL_DIR=${NUTTX_APPS_DIR}/external

MY_APP_NAME=hello
MY_APP_DIR=${BUILD_PREFIX_DIR}/${MY_APP_NAME}
MY_APP_EXTERNAL_DIR=${NUTTX_APPS_EXTERNAL_DIR}/${MY_APP_NAME}

function setenv() {
    HOME=/home/builder
    PATH=${ESP_PATH}:${HOME}/.local/bin/:${PATH}
}

function configure() {
    # clone incubator-nuttx
    if [ ! -d ${NUTTX_DIR} ]; then
        mkdir -p $(dirname ${NUTTX_DIR})
        git clone ${NUTTX_GIT_URL} -b ${NUTTX_GIT_TAG} ${NUTTX_DIR}
    fi

    # clone incubator-nuttx-apps
    if [ ! -d ${NUTTX_APPS_DIR} ]; then
        mkdir -p $(dirname ${NUTTX_APPS_DIR})
        git clone ${NUTTX_APPS_GIT_URL} -b ${NUTTX_APPS_GIT_TAG} ${NUTTX_APPS_DIR}
    fi

#    # apps/external setting
#    if [ ! -d ${NUTTX_APPS_EXTERNAL_DIR} ]; then
#        mkdir -p ${NUTTX_APPS_EXTERNAL_DIR}
#        cat << 'EOS' > ${NUTTX_APPS_EXTERNAL_DIR}/Makefile
#MENUDESC = "External"
#
#include $(APPDIR)/Directory.mk
#EOS
#        cat << 'EOS' > ${NUTTX_APPS_EXTERNAL_DIR}/Make.defs
#EXTERNAL_DIR=$(APPDIR)/external
#include $(wildcard $(APPDIR)/external/*/Make.defs)
#EOS
#    fi
#
#    # hello
#    if [ ! -d ${MY_APP_EXTERNAL_DIR} ]; then
#        ln -s $(pwd)/${MY_APP_NAME} ${MY_APP_EXTERNAL_DIR}
#    fi

    cd nuttx
    ./tools/configure.sh -l ${BOARD}:${CONFIG}

    # Debug
    kconfig-tweak --enable DEBUG_ASSERTIONS
    kconfig-tweak --enable DEBUG_FEATURES
    kconfig-tweak --enable DEBUG_SYMBOLS

    make olddefconfig

#    # hello
#    kconfig-tweak --enable APP_HELLO
#    kconfig-tweak --set-val APP_HELLO_PRIORITY 100
#    kconfig-tweak --set-val APP_HELLO_STACKSIZE 2048

#    System Type  --->
#      ESP32 Chip Selection (ESP32-WROVER)  --->
    kconfig-tweak --enable ARCH_CHIP_ESP32WROVER

#      ESP32 Peripheral Selection  --->
#        [*] SPI 3
#        [*] SPI RAM
    kconfig-tweak --enable ESP32_SPI3
    kconfig-tweak --enable ESP32_SPIRAM

#        [*] I2C 0
#        [ ] I2C 1
    kconfig-tweak --enable ESP32_I2C
    kconfig-tweak --enable ESP32_I2C0

#      Memory Configuration  --->
#        *** Additional Heaps ***
#            SPI RAM heap function (Separated userspace heap)  --->
#        [ ] Use the rest of IRAM as a separete heap
    kconfig-tweak --disable ESP32_SPIRAM_COMMON_HEAP
    kconfig-tweak --enable ESP32_SPIRAM_USER_HEAP

#      I2C Configuration  --->
#        (22) I2C0 SCL Pin
#        (23) I2C0 SDA Pin
#        (26) I2C1 SCL Pin
#        (25) I2C1 SDA Pin
    kconfig-tweak --set-val ESP32_I2C0_SCLPIN 22
    kconfig-tweak --set-val ESP32_I2C0_SDAPIN 23
    kconfig-tweak --set-val ESP32_I2CTIMEOSEC 0 
    kconfig-tweak --set-val ESP32_I2CTIMEOMS 500

#      SPI Configuration  --->
#        (14) SPI3 CS Pin
#        (18) SPI3 CLK Pin
#        (23) SPI3 MOSI Pin
#        (19) SPI3 MISO Pin
#        SPI3 master I/O mode (Read & Write)  --->
#          (X) Read & Write
#    kconfig-tweak --set-val ESP32_SPI3_CSPIN 14
#    kconfig-tweak --set-val ESP32_SPI3_CLKPIN 18
#    kconfig-tweak --set-val ESP32_SPI3_MOSIPIN 23
#    kconfig-tweak --set-val ESP32_SPI3_MISOPIN 19
#    kconfig-tweak --enable ESP32_SPI3_MASTER_IO_RW
#      SPI Flash Configuration  --->
#        (0x300000) Storage MTD base adddress in SPI Flash
#        (0x100000) Storage MTD size in SPI Flash
#        [*] Support PSRAM As Task Stack
#        [*] Create MTD partitions from Partition Table
    kconfig-tweak --set-val ESP32_STORAGE_MTD_OFFSET 0x300000
    kconfig-tweak --set-val ESP32_STORAGE_MTD_SIZE 0x100000
    kconfig-tweak --enable ESP32_SPI_FLASH_SUPPORT_PSRAM_STACK
    kconfig-tweak --enable ESP32_PARTITION_TABLE
#
#      SPI RAM Configuration  --->
#        Type of SPI RAM chip in use (Auto-detect)  --->
#
#
#    Board Selection  --->
#      *** Board Common Options ***
#      [*]   Mount SPI Flash MTD on bring-up (LittleFS)
    kconfig-tweak --enable ESP32_SPIFLASH_LITTLEFS
#
#    RTOS Features  --->
#      Tasks and Scheduling  --->
#        [*] Auto-mount etc banked-in ROMFS image  ----
#    kconfig-tweak --enable ETC_ROMFS
#

#
#    Message Queue Options
#
    kconfig-tweak --set-val MQ_MAXMSGSIZE 64

#    Device Drivers  --->
#      [*] I2C Driver Support  --->
    kconfig-tweak --enable I2C
    kconfig-tweak --enable I2C_DRIVER

#      -*- SPI Driver Support  --->
#        [*] SPI exchange
#        [*] SPI CMD/DATA
#
#
#      [*] Video Device Support  --->
#        [*] Framebuffer character driver
#
#
#      [*] LCD Driver Support  --->
#        [*] Graphic LCD Driver Support  --->
#          [*] LCD framebuffer front end
#          [*] LCD driver selection  --->
#            [*] Generic SPI Interface Driver (for ILI9341 or others)
#            (1) Number of SSD1306 displays 
#                SSD1306 Interface (SSD1306 on I2C Interface)  --->

    kconfig-tweak --enable LCD
    kconfig-tweak --enable LCD_PACKEDMSFIRST
    kconfig-tweak --enable LCD_FRAMEBUFFER

    # LCD driver selection
    kconfig-tweak --set-val LCD_MAXCONTRAST 63
    kconfig-tweak --set-val LCD_MAXPOWER 1
    kconfig-tweak --enable LCD_SH1106_OLED_132
    kconfig-tweak --enable LCD_SSD1306
    kconfig-tweak --set-val SSD1306_NUMDEVS 1
    kconfig-tweak --enable LCD_SSD1306_I2C
    kconfig-tweak --set-val SSD1306_I2CADDR 60
    kconfig-tweak --set-val SSD1306_I2CFREQ 400000
    kconfig-tweak --enable LCD_LANDSCAPE

#    Timer Driver Support
    kconfig-tweak --enable FB_UPDATE
#
#
#
#    Networking Support  --->
#
#
#    File Systems  --->
#      [*] ROMFS file system
#    kconfig-tweak --enable FS_ROMFS
#
#    Graphic Support  --->
#      [*] NX Graphics

    kconfig-tweak --enable NX
    kconfig-tweak --enable NX_LCDDRIVER
    kconfig-tweak --set-val NX_NDISPLAYS 1
    kconfig-tweak --set-val NX_NPLANES 1
    kconfig-tweak --enable NX_NOCURSOR
    kconfig-tweak --set-val NX_BGCOLOR 0x0

# Supported Pixel Depths
    kconfig-tweak --enable NX_DISABLE_1BPP
    kconfig-tweak --enable NX_DISABLE_2BPP
    kconfig-tweak --enable NX_DISABLE_4BPP
    kconfig-tweak --enable NX_DISABLE_8BPP
    kconfig-tweak --enable NX_DISABLE_16BPP
    kconfig-tweak --enable NX_DISABLE_24BPP
    kconfig-tweak --enable NX_DISABLE_32BPP
    kconfig-tweak --enable NX_PACKEDMSFIRST

#
# Input Devices
#
    kconfig-tweak --enable NX_XYINPUT_NONE

#
# Framed Window Borders
#
    kconfig-tweak --set-val NXTK_BORDERWIDTH 4
    kconfig-tweak --enable NXTK_DEFAULT_BORDERCOLORS

#
# NX server options
#
    kconfig-tweak --enable NX_BLOCKING
    kconfig-tweak --set-val NX_MXSERVERMSGS 32
    kconfig-tweak --set-val NX_MXCLIENTMSGS 16

    kconfig-tweak --set-val NXSTART_SERVERPRIO 110
    kconfig-tweak --set-val NXSTART_SERVERSTACK 4096
    kconfig-tweak --set-val NXSTART_DEVNO 0
    kconfig-tweak --enable NXFONTS

#
# Font Selections
#
    kconfig-tweak --set-val NXFONTS_CHARBITS 7
    kconfig-tweak --enable NXFONT_SANS20X26

#
# Font Cache Pixel Depths
#
    kconfig-tweak --enable NXFONTS_DISABLE_1BPP
    kconfig-tweak --enable NXFONTS_DISABLE_2BPP
    kconfig-tweak --enable NXFONTS_DISABLE_4BPP
    kconfig-tweak --enable NXFONTS_DISABLE_8BPP
    kconfig-tweak --enable NXFONTS_DISABLE_16BPP
    kconfig-tweak --enable NXFONTS_DISABLE_24BPP
    kconfig-tweak --enable NXFONTS_DISABLE_32BPP
    kconfig-tweak --enable NXFONTS_PACKEDMSFIRST
    kconfig-tweak --enable NXGLIB

#    Memory Management
#      (0x3F800000) Start address of second user heap region
#      (4194304) Start address of second user heap region
    kconfig-tweak --set-val HEAP2_BASE 0x3F800000
    kconfig-tweak --set-val HEAP2_SIZE 4194304
#
#    Application Configuration  --->
#      Examples  --->
#        [*] Framebuffer driver example
#
#      Network Utiliteis  --->
#        -*- Network initialization
#              IP Address Configuration  --->
#                [*] Use DHCP to get IP address
#          [*] Use DNS
    kconfig-tweak --enable NETINIT_DHCPC
    kconfig-tweak --enable NETINIT_DNS
#

#      System Libraries and NSH Add-Ons  --->
#        [*] I2C tool  --->

    kconfig-tweak --enable SYSTEM_I2CTOOL
    kconfig-tweak --set-val I2CTOOL_MINBUS 0
    kconfig-tweak --set-val I2CTOOL_MAXBUS 3
    kconfig-tweak --set-val I2CTOOL_MINADDR 0x03
    kconfig-tweak --set-val I2CTOOL_MAXADDR 0x77   
    kconfig-tweak --set-val I2CTOOL_MAXREGADDR 0xff
    kconfig-tweak --set-val I2CTOOL_DEFFREQ 400000 

#    kconfig-tweak --enable PSEUDOFS_SOFTLINKS
#    kconfig-tweak --enable FS_RAMMAP

    kconfig-tweak --enable EXAMPLES_NXHELLO
    kconfig-tweak --set-str EXAMPLES_NXHELLO_PROGNAME "nxhello"
    kconfig-tweak --set-val EXAMPLES_NXHELLO_PRIORITY 100
    kconfig-tweak --set-val EXAMPLES_NXHELLO_STACKSIZE 4096
    kconfig-tweak --set-val EXAMPLES_NXHELLO_BPP 32

# Example Color Configuration
    kconfig-tweak --enable EXAMPLES_NXHELLO_DEFAULT_COLORS

# Example Font Configuration
    kconfig-tweak --enable EXAMPLES_NXHELLO_DEFAULT_FONT

# NX Server Options
    kconfig-tweak --set-val EXAMPLES_NXHELLO_LISTENER_STACKSIZE 4096
    kconfig-tweak --set-val EXAMPLES_NXHELLO_CLIENTPRIO 100
    kconfig-tweak --set-val EXAMPLES_NXHELLO_SERVERPRIO 120
    kconfig-tweak --set-val EXAMPLES_NXHELLO_LISTENERPRIO 80


#######################################################################



#######################################################################

    cd ..
}

function menuconfig() {
    cd ${NUTTX_DIR}
    make menuconfig
    cd ..
}

function clean() {
    cd ${NUTTX_DIR}
#    make clean_context all
    make clean
    cd ..
}

function create_etc_romfs() {
    cd ${NUTTX_DIR}

#    if [ -e rc.sysinit.template ]; then
#        rm rc.sysinit.template
#    fi
#    if [ -e rcS.template ]; then
#        rm rcS.template
#    fi
#    
#    touch rc.sysinit.template
#    touch rcS.template
#    echo "#! /bin/nsh" > rcS.template
#    echo "hello &" >> rcS.template
#    ./tools/mkromfsimg.sh -nofat ./ rc.sysinit.template rcS.template
#    mv etc_romfs.c boards/xtensa/esp32/esp32-devkitc/src/
#
#    target_file="boards/xtensa/esp32/esp32-devkitc/src/Make.defs"
#    if ! grep -Fq "ifeq (\$(CONFIG_ETC_ROMFS),y)" "$target_file"; then
#        insert_text="ifeq (\$(CONFIG_ETC_ROMFS),y)\nCSRCS += etc_romfs.c\nendif\n"
#        line_num=$(($(wc -l < "$target_file") - 3))
#        sed -i "${line_num}i\\
#$insert_text" "$target_file"
#    fi

    cd ..
}

function build() {
    cd ${NUTTX_DIR}
    make -j$(nproc) ESPTOOL_BINDIR=. V=1
    cd ..
}

function build_bootloader() {
    if [ "${BOARD}" != "sim" ]; then
        cd ${NUTTX_DIR}
#        make bootloader
        wget https://github.com/espressif/esp-nuttx-bootloader/releases/download/latest/bootloader-esp32.bin -P ./
        cd ..
    fi
}

function build_partition_table() {
    cd ${NUTTX_DIR}
    python3 ../partition/gen_esp32part.py ../partition/esp32-partitions.csv partition-table-esp32.bin
    cd ..
}

function allclean() {
    echo "Cleaning up generated files..."
    if [ -d ${NUTTX_DIR} ]; then
        rm -rf ${NUTTX_DIR}
    fi
    if [ -d ${NUTTX_APPS_DIR} ]; then
        rm -rf ${NUTTX_APPS_DIR}
    fi
#    if [ -d ${ESP_IDF_ILI9340_DIR} ]; then
#        rm -rf ${ESP_IDF_ILI9340_DIR}
#    fi
}

case "$1" in
    allclean)
        setenv
        clean
        allclean
        ;;
    clean)
        setenv
        clean
        ;;
    configure)
        setenv
        configure
        ;;
    menuconfig)
        setenv
        menuconfig
        ;;
    build)
        setenv
        build
        ;;
    etcromfs)
        setenv
        create_etc_romfs
        ;;
    bootloader)
        setenv
        build_bootloader
        ;;
    partition)
        setenv
        build_partition_table
        ;;
    *)
        setenv
        configure
        build_bootloader
        build_partition_table
        build
        ;;
esac
