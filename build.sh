#!/bin/bash
set -e

NASM=nasm
LD=ld
OUTDIR=build
rm -rf $OUTDIR
mkdir -p $OUTDIR

echo "building genz..."
$NASM -f elf32 kernel/boot.asm -o $OUTDIR/boot.o
$NASM -f elf32 kernel/kernel.asm -o $OUTDIR/kernel.o
$NASM -f elf32 kernel/drivers/keyboard.asm -o $OUTDIR/keyboard.o
$NASM -f elf32 kernel/login/login.asm -o $OUTDIR/login.o
$NASM -f elf32 kernel/shell/shell.asm -o $OUTDIR/shell.o

echo "linking obj files..."
$LD -m elf_i386 -T linker.ld -o $OUTDIR/kernel.bin \
    $OUTDIR/boot.o \
    $OUTDIR/kernel.o \
    $OUTDIR/keyboard.o \
    $OUTDIR/login.o \
    $OUTDIR/shell.o

mkdir -p $OUTDIR/iso/boot/grub
cp $OUTDIR/kernel.bin $OUTDIR/iso/boot/
cp boot/grub.cfg $OUTDIR/iso/boot/grub/
grub-mkrescue -o $OUTDIR/GENZ.iso $OUTDIR/iso

echo "build successful!!! just run with: qemu-system-x86_64 -cdrom $OUTDIR/GENZ.iso"
