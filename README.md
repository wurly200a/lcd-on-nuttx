# lcd-on-nuttx
Using LCD on NuttX

## Write FlashROM

### Setup

```
python3 -m venv ./venv
. venv/bin/activate
pip3 install esptool==v4.7.0
deactivate
```

### Write

```
. venv/bin/activate
PORT=/dev/ttyUSB0
esptool.py --chip esp32 --port ${PORT} --baud 921600 --before default_reset erase_flash;
esptool.py --chip esp32 --port ${PORT} --baud 921600 write_flash 0x1000 nuttx/bootloader-esp32.bin 0x8000 nuttx/partition-table-esp32.bin 0x10000 nuttx/nuttx.bin
deactivate
```
