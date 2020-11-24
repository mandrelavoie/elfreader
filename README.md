# Elfreader

A simple ELF parser I had lying around from another project. I added a small CLI to let you print headers info.

# How to Build
```
$ zig build
```

# Usage Example
```
$ elfreader --headers --segments --sections /usr/bin/ls

ELF Header:
  Magic:                         7f 45 4c 46
  Class:                         64bits
  Endianness:                    Little
  Version:                       1
  Os:                            SystemV
  ABI Version:                   0
  Padding:                       00 00 00 00 00 00 00
  Type:                          SharedObject
  Architecture:                  x86_64
  Version:                       1
  Entry Point:                   0x67d0
  Program Headers Offset:        0x40
  Section Headers Offset:        0x223c0
  Flags:                         0x0
  ELF Header Size:               0x40
  Size of Program Headers:       0x38
  Number of Program Headers:     13
  Size of Section Headers:       0x40
  Number of Section Headers:     30
  String Table Section Index:    29

Program Headers:
       Type           Offset   Virtual Address    Physical Address   Size on File       Size in memory     Permissions  Alignment
  [ 0] Phdr           0x000040 0x0000000000000040 0x0000000000000040 0x00000000000002d8 0x00000000000002d8 R            0x0008 
  [ 1] Interp         0x000318 0x0000000000000318 0x0000000000000318 0x000000000000001c 0x000000000000001c R            0x0001 
  [ 2] Load           0x000000 0x0000000000000000 0x0000000000000000 0x00000000000036a8 0x00000000000036a8 R            0x1000 
  [ 3] Load           0x004000 0x0000000000004000 0x0000000000004000 0x0000000000013581 0x0000000000013581 R X          0x1000 
  [ 4] Load           0x018000 0x0000000000018000 0x0000000000018000 0x0000000000008b50 0x0000000000008b50 R            0x1000 
  [ 5] Load           0x021010 0x0000000000022010 0x0000000000022010 0x0000000000001258 0x0000000000002548 RW           0x1000 
  [ 6] Dynamic        0x021a58 0x0000000000022a58 0x0000000000022a58 0x0000000000000200 0x0000000000000200 RW           0x0008 
  [ 7] Note           0x000338 0x0000000000000338 0x0000000000000338 0x0000000000000020 0x0000000000000020 R            0x0008 
  [ 8] Note           0x000358 0x0000000000000358 0x0000000000000358 0x0000000000000044 0x0000000000000044 R            0x0004 
  [ 9] GnuProperty    0x000338 0x0000000000000338 0x0000000000000338 0x0000000000000020 0x0000000000000020 R            0x0008 
  [10] GnuEhFrame     0x01d24c 0x000000000001d24c 0x000000000001d24c 0x000000000000092c 0x000000000000092c R            0x0004 
  [11] GnuStack       0x000000 0x0000000000000000 0x0000000000000000 0x0000000000000000 0x0000000000000000 RW           0x0010 
  [12] GnuRelRo       0x021010 0x0000000000022010 0x0000000000022010 0x0000000000000ff0 0x0000000000000ff0 R            0x0001 

Section Headers:
       Name                Type                Address            Offset   Size     Entry Size  Flags  Link  Info  Alignment
  [ 0]                     NULL                0x0000000000000000 0x000000 0x000000 0x00               0      0     0 
  [ 1] .interp             PROGBITS            0x0000000000000318 0x000318 0x00001c 0x00        A      0      0     1 
  [ 2] .note.gnu.property  NOTE                0x0000000000000338 0x000338 0x000020 0x00        A      0      0     8 
  [ 3] .note.gnu.build-id  NOTE                0x0000000000000358 0x000358 0x000024 0x00        A      0      0     4 
  [ 4] .note.ABI-tag       NOTE                0x000000000000037c 0x00037c 0x000020 0x00        A      0      0     4 
  [ 5] .gnu.hash           GNU_HASH            0x00000000000003a0 0x0003a0 0x0000e4 0x00        A      6      0     8 
  [ 6] .dynsym             DYNSYM              0x0000000000000488 0x000488 0x000d08 0x18        A      7      1     8 
  [ 7] .dynstr             STRTAB              0x0000000000001190 0x001190 0x00064c 0x00        A      0      0     1 
  [ 8] .gnu.version        GNU_VERSION         0x00000000000017dc 0x0017dc 0x000116 0x02        A      6      0     2 
  [ 9] .gnu.version_r      GNU_VERSION_R       0x00000000000018f8 0x0018f8 0x000070 0x00        A      7      1     8 
  [10] .rela.dyn           RELA                0x0000000000001968 0x001968 0x001350 0x18        A      6      0     8 
  [11] .rela.plt           RELA                0x0000000000002cb8 0x002cb8 0x0009f0 0x18        A  I   6     25     8 
  [12] .init               PROGBITS            0x0000000000004000 0x004000 0x00001b 0x00        A X    0      0     4 
  [13] .plt                PROGBITS            0x0000000000004020 0x004020 0x0006b0 0x10        A X    0      0    16 
  [14] .plt.got            PROGBITS            0x00000000000046d0 0x0046d0 0x000030 0x10        A X    0      0    16 
  [15] .plt.sec            PROGBITS            0x0000000000004700 0x004700 0x0006a0 0x10        A X    0      0    16 
  [16] .text               PROGBITS            0x0000000000004da0 0x004da0 0x0127d2 0x00        A X    0      0    16 
  [17] .fini               PROGBITS            0x0000000000017574 0x017574 0x00000d 0x00        A X    0      0     4 
  [18] .rodata             PROGBITS            0x0000000000018000 0x018000 0x005249 0x00        A      0      0    32 
  [19] .eh_frame_hdr       PROGBITS            0x000000000001d24c 0x01d24c 0x00092c 0x00        A      0      0     4 
  [20] .eh_frame           PROGBITS            0x000000000001db78 0x01db78 0x002fd8 0x00        A      0      0     8 
  [21] .init_array         INIT_ARRAY          0x0000000000022010 0x021010 0x000008 0x08        AW     0      0     8 
  [22] .fini_array         FINI_ARRAY          0x0000000000022018 0x021018 0x000008 0x08        AW     0      0     8 
  [23] .data.rel.ro        PROGBITS            0x0000000000022020 0x021020 0x000a38 0x00        AW     0      0    32 
  [24] .dynamic            DYNAMIC             0x0000000000022a58 0x021a58 0x000200 0x10        AW     7      0     8 
  [25] .got                PROGBITS            0x0000000000022c58 0x021c58 0x0003a0 0x08        AW     0      0     8 
  [26] .data               PROGBITS            0x0000000000023000 0x022000 0x000268 0x00        AW     0      0    32 
  [27] .bss                NOBITS              0x0000000000023280 0x022268 0x0012d8 0x00        AW     0      0    32 
  [28] .gnu_debuglink      PROGBITS            0x0000000000000000 0x022268 0x000034 0x00               0      0     4 
  [29] .shstrtab           STRTAB              0x0000000000000000 0x02229c 0x00011d 0x00               0      0     1 
```