const std = @import("std");
const Allocator = std.mem.Allocator;

const transmute = @import("utils.zig").transmute;

pub const ElfError = error {
    CannotReadFile,
    InvalidElfFile,
    WrongSignature,
    WrongElfVersion,
    StringNotFound,
};

pub const ElfHeader = extern struct {
    const ELF_SIGNATURE = "\x7fELF";

    signature: [4]u8,                //e_ident
    class: extern enum(u8) {
        @"32bits" = 1,
        @"64bits" = 2,
        _
    },
    endianness: extern enum(u8) {
        Little = 1,
        Big = 2,
        _
    },
    ident_version: u8,
    os: extern enum(u8) {
        SystemV = 0,
        Linux = 12,
        _
    },
    abi_version: u8,
    padding: [7]u8,
    
    file_type: extern enum(u16) {    // e_type
        None = 0,
        Relocatable = 1,
        Executable = 2,
        SharedObject = 3,
        Core = 4,
        _,
    },             
    architecture: extern enum(u16) { // e_machine
        None = 0,
        Intel386 = 3,
        x86_64 = 0x3e,
        Arm64 = 0xb7,
        _,
    },
    version: u16,                    // e_version
    entrypoint: u64,                 // e_entry
    program_header_offset: u64,      // e_phoff
    section_header_offset: u64,      // e_shoff
    flags: u32,                      // e_flags
    header_size: u16,                // e_ehsize
    program_header_size: u16,        // e_phentsize 
    program_header_count: u16,       // e_phnum
    section_header_size: u16,        // e_shentsize
    section_header_count: u16,       // e_shnum
    string_table_index: u16,         // e_shstrndx

    pub fn parse(bytes: []const u8) !ElfHeader {
        const header = try transmute(ElfHeader, bytes) catch ElfError.InvalidElfFile;

        if (!std.mem.eql(u8, header.signature[0..], ELF_SIGNATURE)) {
            return ElfError.WrongSignature;
        }

        return header;
    }
};

const expect = std.testing.expect;
const expectError = std.testing.expectError;

// From `hexdump -ve '1/1 "0x%.2x, "' -n 64 /usr/bin/strings`
const test_elf_header = [_]u8 {
    0x7f, 0x45, 0x4c, 0x46, 0x02, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x03, 0x00, 0xb7, 0x00, 0x01, 0x00, 0x00, 0x00, 0x18, 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xa0, 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x38, 0x00, 0x09, 0x00, 0x40, 0x00, 0x1a, 0x00, 0x19, 0x00,
};

test "ElfHeader.parse ok" {
    const header = try ElfHeader.parse(test_elf_header[0..]);

    expect(std.mem.eql(u8, header.signature[0..], "\x7fELF"));
    expect(header.class == .@"64bits");
    expect(header.version == 1);
    expect(header.entrypoint == 0x2318);
    expect(header.string_table_index == 25);
}

test "ElfHeader.parse not enough bytes" {
    expectError(ElfError.InvalidElfFile, ElfHeader.parse(test_elf_header[0..test_elf_header.len - 1]));
}

test "No ELF magic bytes" {
    var bytes: [64]u8 = undefined;
    std.mem.copy(u8, bytes[0..], test_elf_header[0..]);
    bytes[0] = 0xFF;

    expectError(ElfError.InvalidElfFile, try ElfHeader.parse(bytes[0..]));
}

pub const ElfSegment = struct {
    const Type = extern enum(u32) {
        Null = 0,
        Load = 1,
        Dynamic = 2,
        Interp = 3,
        Note = 4,
        ShLib = 5,
        Phdr = 6,
        GnuProperty = 0x6474e553,
        GnuEhFrame = 0x6474e550,
        GnuStack = 0x6474e551,
        GnuRelRo = 0x6474e552,
        _,
    };

    pub const Header = extern struct {
        program_type: Type,
        flags: u32,
        offset: u64,
        virtual_address: u64,
        physical_address: u64,
        file_size: u64,
        memory_size: u64,
        alignment: u64,
    };

    header: Header,
    data: []u8,

    pub fn is_readable(self: ElfSegment) bool {
        return (self.header.flags & 4) == 4;
    }

    pub fn is_writable(self: ElfSegment) bool {
        return (self.header.flags & 2) == 2;
    }

    pub fn is_executable(self: ElfSegment) bool {
        return (self.header.flags & 1)  == 1;
    }

    pub fn parse_all(allocator: *Allocator, elf_header: ElfHeader, buffer: []u8) ![]ElfSegment {
        const count = elf_header.program_header_count;
        const header_table_size = try std.math.mul(u64, count, elf_header.program_header_size);

        const headers_start = elf_header.program_header_offset;
        
        if (buffer.len < headers_start + header_table_size) {
            return ElfError.InvalidElfFile;
        }

        var result = try allocator.alloc(ElfSegment, count);
        errdefer allocator.free(result);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const segment_header = blk: {
                const start = headers_start + (elf_header.program_header_size * i);
                const end = start + elf_header.program_header_size;

                break :blk try transmute(Header, buffer[start..end]);
            };

            const data = blk: {
                const start = segment_header.offset;
                const end = start + segment_header.file_size;

                if (buffer.len <= end) {
                    return ElfError.InvalidElfFile;
                }

                break :blk buffer[start..end];
            };

            result[i] = .{
                .header = segment_header,
                .data = data,
            };
        }

        return result;
    }
};

pub const ElfSection = struct {
    const Type = extern enum(u32) {
        NULL = 0,
        PROGBITS = 1,
        SYMTAB = 2,
        STRTAB = 3,
        RELA = 4,
        HASH = 5,
        DYNAMIC = 6,
        NOTE = 7,
        NOBITS = 8,
        REL = 9,
        SHLIB = 10,
        DYNSYM = 11,
        INIT_ARRAY = 14,
        FINI_ARRAY = 15,
        PREINIT_ARRAY = 16,
        GROUP = 17,
        SYMTAB_SHNDX = 18,
        GNU_HASH = 0x6ffffff6,
        GNU_VERSION = 0x6fffffff,
        GNU_VERSION_R = 0x6ffffffe,
        _,
    };

    pub const Header = extern struct {
        name_index: u32,
        section_type: Type,
        flags: u64,
        address: u64,
        offset: u64,
        size: u64,
        link: u32,
        info: u32,
        alignment: u64,
        entry_size: u64,
    };

    header: Header,
    name: []const u8,
    data: []u8,

    pub fn is_writable(self: ElfSection) bool {
        return (self.header.flags & 1) == 1;
    }

    pub fn is_allocated(self: ElfSection) bool {
        return (self.header.flags & 2) == 2;
    }

    pub fn is_executable(self: ElfSection) bool {
        return (self.header.flags & 4)  == 4;
    }

    pub fn has_info_link(self: ElfSection) bool {
        return (self.header.flags & 0x40)  == 0x40;
    }

    pub fn parse_all(allocator: *Allocator, elf_header: ElfHeader, buffer: []u8) ![]ElfSection {
        const count = elf_header.section_header_count;
        const header_table_size = try std.math.mul(u64, count, elf_header.section_header_size);

        const headers_start = elf_header.section_header_offset;

        if (buffer.len < headers_start + header_table_size) {
            return ElfError.InvalidElfFile;
        }

        var result = try allocator.alloc(ElfSection, count);
        errdefer allocator.free(result);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const section_header = blk: {
                const start = headers_start + (elf_header.section_header_size * i);
                const end = start + elf_header.section_header_size;

                break :blk try transmute(Header, buffer[start..end]);
            };

            const data = blk: {
                const start = section_header.offset;
                var end = start + section_header.size;

                if (buffer.len <= end) {
                    //return ElfError.InvalidElfFile;
                    end = buffer.len;
                }

                break :blk buffer[start..end];
            };

            result[i] = .{
                .header = section_header,
                .name = undefined,
                .data = data,
            };
        }

        const string_table = ElfStringTable.from(result[elf_header.string_table_index]);

        i = 0;
        while (i < count) : (i += 1) {  
            const index = result[i].header.name_index;

            result[i].name = string_table.get(index) catch "(Unnamed section)";
        }

        return result;
    }
};

pub const ElfStringTable = struct {
    section: ElfSection,

    pub fn from(section: ElfSection) ElfStringTable {
        return .{
            .section = section,
        };
    }

    pub fn get(self: ElfStringTable, start: usize) ![]const u8 {
        const buffer = self.section.data;

        if (start < buffer.len) {
            if (std.mem.indexOf(u8, buffer[start..], "\x00")) |end| {
                return buffer[start..start + end];
            }
        }

        return ElfError.StringNotFound;
    }
};

pub const ElfFile = struct {
    const MAX_SIZE = 200_000_000;

    allocator: *Allocator,
    buffer: []u8,

    header: ElfHeader,
    segments: []ElfSegment,
    sections: []ElfSection,

    pub fn from_file(allocator: *Allocator, path: []const u8) !ElfFile {
        var buffer = try std.fs.cwd().readFileAlloc(allocator, path, MAX_SIZE);
        errdefer allocator.free(buffer);

        const elf_header = try ElfHeader.parse(buffer);

        const segments = try ElfSegment.parse_all(allocator, elf_header, buffer);
        errdefer allocator.free(segments);

        const sections = try ElfSection.parse_all(allocator, elf_header, buffer);
        errdefer allocator.free(sections);
        
        return ElfFile {
            .allocator = allocator,
            .buffer = buffer,
            .header = elf_header,
            .segments = segments,
            .sections = sections,
        };
    }

    pub fn deinit(self: ElfFile) void {
        self.allocator.free(self.sections);
        self.allocator.free(self.segments);
        self.allocator.free(self.buffer);
    }

    pub fn get_section_by_name(self: ElfFile, name: []const u8) ?ElfSection {
        for (self.sections) |section| {
            if (std.mem.eql(u8, section.name, name)) {
                return section;
            }
        }

        return null;
    }

    // Common sections
    pub fn text(self: ElfFile) ?[]align(1) u32 {
        if (self.get_section_by_name(".text")) |section| {
            return std.mem.bytesAsSlice(u32, section.data);
        }

        return null;
    }
};

var test_allocator = std.testing.allocator;

test "ElfFile.from_file ok" {
    var elf_file = try ElfFile.from_file(test_allocator, "/usr/bin/ls");
    defer elf_file.deinit();

    expect(elf_file.segments.len == 9);
    expect(elf_file.sections.len == 26);
}
