# Simple x86 Bootloader

A minimal yet functional x86 bootloader that transitions from 16-bit real mode to 32-bit protected mode and loads a basic kernel. This bootloader demonstrates fundamental OS development concepts including BIOS interrupts, Global Descriptor Table (GDT) setup, A20 line enabling, and kernel loading.

## Features

- **16-bit to 32-bit Mode Transition**: Switches from BIOS real mode to protected mode
- **Kernel Loading**: Loads kernel from disk using BIOS interrupts
- **A20 Line Enabling**: Enables access to memory above 1MB
- **GDT Setup**: Configures Global Descriptor Table for protected mode
- **Mixed Assembly/C Kernel**: Supports both assembly and C code in the kernel
- **Memory Management**: Proper memory layout with linker script

## Technical Specifications

### Boot Sector
- **Size**: 512 bytes (standard boot sector size)
- **Load Address**: 0x7C00 (BIOS standard)
- **Boot Signature**: 0xAA55
- **Architecture**: x86 (32-bit)

### Memory Layout
- **Bootloader**: 0x7C00 - 0x7DFF
- **Stack**: Below 0x7C00
- **Kernel Load Segment**: 0x1000 (temporary)
- **Kernel Final Address**: 0x100000 (1MB)

### GDT Configuration
- **Null Descriptor**: Required first entry
- **Code Segment**: Ring 0, executable, readable, 4GB limit
- **Data Segment**: Ring 0, writable, 4GB limit
- **Granularity**: 4KB pages
- **Mode**: 32-bit segments

### Kernel Loading
- **Sectors Read**: 8 sectors (4KB)
- **Starting Sector**: Sector 2 (after boot sector)
- **Drive**: 0x00 (first floppy/hard drive)
- **Head**: 0x00
- **Track**: 0x00

## Project Structure

```
Bootloader/
├── src/
│   ├── boot.asm         # Main bootloader (16-bit → 32-bit transition)
│   ├── kernel.asm       # Kernel entry point (32-bit)
│   ├── kernel.c         # Kernel main function (C code)
│   └── kernel.h         # Kernel header file
├── bin/                 # Compiled binaries
│   ├── boot.bin         # 512-byte boot sector
│   ├── kernel.bin       # Compiled kernel
│   └── os.bin           # Complete OS image
├── Build/               # Build artifacts
├── Makefile             # Build configuration
├── build.sh             # Build script
└── linkerScript.ld      # Memory layout specification
```

## Prerequisites

### Required Tools
- **NASM** (Netwide Assembler) - for assembly compilation
- **i686-elf-gcc** - cross-compiler for x86 targets
- **i686-elf-ld** - cross-linker for x86 targets
- **dd** - for creating disk images
- **make** - build automation

### Installing Cross-Compiler (Ubuntu/Debian)
```bash
# Install build dependencies
sudo apt update
sudo apt install build-essential nasm

# For cross-compiler, you may need to build from source or use:
# https://github.com/lordmilko/i686-elf-tools
```

## Building the Bootloader

### Using Make
```bash
cd Bootloader
make all
```

### Manual Build Process
```bash
# Compile boot sector
nasm -f bin ./src/boot.asm -o ./bin/boot.bin

# Compile kernel assembly
nasm -f elf -g ./src/kernel.asm -o ./build/kernel.asm.o

# Compile kernel C code
i686-elf-gcc -I./src -g -ffreestanding -nostdlib -nostartfiles -nodefaultlibs -Wall -O0 -std=gnu99 -c ./src/kernel.c -o ./build/kernel.o

# Link kernel objects
i686-elf-ld -g -relocatable ./build/kernel.asm.o ./build/kernel.o -o ./build/completekernel.o

# Create final kernel binary
i686-elf-gcc -g -ffreestanding -nostdlib -nostartfiles -nodefaultlibs -Wall -O0 -T ./linkerScript.ld -o ./bin/kernel.bin -ffreestanding -O0 -nostdlib ./build/completekernel.o

# Create complete OS image
dd if=./bin/boot.bin >> ./bin/os.bin
dd if=./bin/kernel.bin >> ./bin/os.bin
dd if=/dev/zero bs=512 count=8 >> ./bin/os.bin
```

### Clean Build
```bash
make clean
```

## Running the Bootloader

### Using QEMU
```bash
# Run with QEMU (recommended for testing)
qemu-system-i386 -drive file=./bin/os.bin,format=raw,if=floppy

# Or with more verbose output
qemu-system-i386 -drive file=./bin/os.bin,format=raw,if=floppy -monitor stdio
```

### Using VirtualBox
1. Create a new virtual machine
2. Use `./bin/os.bin` as a floppy disk image
3. Configure VM to boot from floppy

### Real Hardware (Advanced)
```bash
# Write to USB drive (DANGEROUS - will erase drive)
# Replace /dev/sdX with your USB device
sudo dd if=./bin/os.bin of=/dev/sdX bs=512
```

⚠️ **Warning**: Writing to real hardware will erase the target device. Use only on dedicated test hardware.

## Boot Process

1. **BIOS POST**: System initialization and hardware detection
2. **Boot Sector Load**: BIOS loads 512 bytes from sector 0 to 0x7C00
3. **Real Mode Setup**: Initialize segments and stack
4. **Kernel Loading**: Read 8 sectors from disk containing kernel
5. **A20 Line Enable**: Enable access to extended memory
6. **GDT Setup**: Configure memory segmentation for protected mode
7. **Protected Mode Switch**: Transition to 32-bit mode
8. **Kernel Jump**: Transfer control to loaded kernel at 0x100000

## Development Notes

### Current Limitations
- Basic kernel implementation (currently empty)
- No file system support
- No interrupt handling in kernel
- Fixed kernel size (8 sectors)
- Single-stage bootloader

### Extending the Bootloader
To add functionality:

1. **Modify `kernel.c`**: Add your kernel code in `kernel_main()`
2. **Update linker script**: Adjust memory layout if needed
3. **Add source files**: Include additional C/ASM files in Makefile
4. **Increase kernel size**: Modify sector count in boot.asm if kernel grows

### Memory Map
```
0x00000000 - 0x000003FF  Real Mode Interrupt Vector Table
0x00000400 - 0x000004FF  BIOS Data Area
0x00000500 - 0x00007BFF  Free conventional memory
0x00007C00 - 0x00007DFF  Bootloader
0x00007E00 - 0x0009FFFF  Free conventional memory
0x000A0000 - 0x000FFFFF  Video memory, ROM BIOS
0x00100000+              Extended memory (kernel location)
```

## Troubleshooting

### Build Issues
- **Missing cross-compiler**: Install i686-elf-gcc toolchain
- **NASM not found**: Install nasm package
- **Permission denied**: Check file permissions and disk space

### Runtime Issues
- **Boot loop**: Check boot signature (0xAA55) is present
- **Kernel not loading**: Verify disk read parameters in boot.asm
- **Protection fault**: Check GDT configuration and segment registers

### Debugging
- Use QEMU monitor for debugging: `-monitor stdio`
- Enable QEMU debugging: `-d cpu_reset,guest_errors`
- Check QEMU log output for detailed execution trace

## License

This project is provided as-is for educational purposes. Feel free to modify and use for learning operating system development concepts.

## References

- [OSDev Wiki](https://wiki.osdev.org/)
- [Intel 80386 Programmer's Reference Manual](https://pdos.csail.mit.edu/6.828/2018/readings/i386.pdf)
- [BIOS Interrupt Reference](http://www.ctyme.com/intr/int.htm)