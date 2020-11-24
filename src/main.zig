const std = @import("std");
const Allocator = std.mem.Allocator;

usingnamespace @import("elf.zig");
usingnamespace @import("utils.zig");

fn print_help() void {
    println("Usage: elfreader <options> [elf-file]", .{});
    println("Options are:", .{});
    println("  -a --all       Equivalent to --header --segments --sections", .{});
    println("  -h --header    Print the ELF header", .{});
    println("  -l --segments  List every program headers", .{});
    println("  -l --sections  List every section headers", .{});

    std.process.exit(0);
}

const CliArguments = struct {
    print_headers: bool,
    print_sections: bool,
    print_segments: bool,
    target: []const u8,

    pub fn parse(allocator: *Allocator) CliArguments {
        const args = std.process.argsAlloc(allocator) catch @panic("Cannot read command lines arguments.\n");

        if (args.len <= 1) {
            print_help();
        }

        var result = CliArguments {
            .print_headers = false,
            .print_sections = false,
            .print_segments = false,
            .target = args[args.len - 1],
        };

        // Print everything by default
        var print_all = true;

        for (args[0..args.len]) |a| {
            if (std.mem.eql(u8, a, "--help")) {
                print_help();
            }
            if (std.mem.eql(u8, a, "--headers") or std.mem.eql(u8, a, "-h")) {
                result.print_headers = true;
                print_all = false;
            } else if (std.mem.eql(u8, a, "--segments") or std.mem.eql(u8, a, "-S")) {
                result.print_segments = true;
                print_all = false;
            } else if (std.mem.eql(u8, a, "--sections") or std.mem.eql(u8, a, "-l")) {
                result.print_sections = true;
                print_all = false;
            }
        }
        
        if (print_all) {
            result.print_headers = true;
            result.print_sections = true;
            result.print_segments = true;
        }

        return result;
    }
};

fn print_header_field(comptime name: []const u8, comptime format: []const u8, value: anytype) void {
    println("  {:<30} " ++ format, .{ name ++ ":", value });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;
    const args = CliArguments.parse(allocator);

    const elf = try ElfFile.from_file(allocator, args.target);

    if (args.print_headers) {
        println("ELF Header:", .{ });

        print("  Magic:                         ", .{});
        print_bytes(elf.header.signature[0..]);
        print_header_field("Class", "{}", @tagName(elf.header.class));
        print_header_field("Endianness", "{}", @tagName(elf.header.endianness));
        print_header_field("Version", "{}", elf.header.ident_version);
        print_header_field("Os", "{}", @tagName(elf.header.os));
        print_header_field("ABI Version", "{}", elf.header.abi_version);
        print("  Padding:                       ", .{});
        print_bytes(elf.header.padding[0..]);

        print_header_field("Type", "{}", @tagName(elf.header.file_type));
        print_header_field("Architecture", "{}", @tagName(elf.header.architecture));
        print_header_field("Version", "{}", elf.header.version);
        print_header_field("Entry Point", "0x{x}", elf.header.entrypoint);
        print_header_field("Program Headers Offset", "0x{x}", elf.header.program_header_offset);
        print_header_field("Section Headers Offset", "0x{x}", elf.header.section_header_offset);
        print_header_field("Flags", "0x{x}", elf.header.flags);

        print_header_field("ELF Header Size", "0x{x}", elf.header.header_size);
        print_header_field("Size of Program Headers", "0x{x}", elf.header.program_header_size);
        print_header_field("Number of Program Headers", "{}", elf.header.program_header_count);
        print_header_field("Size of Section Headers", "0x{x}", elf.header.section_header_size);
        print_header_field("Number of Section Headers", "{}", elf.header.section_header_count);

        print_header_field("String Table Section Index", "{}", elf.header.string_table_index);
    }

    if (args.print_segments) {
        println("", .{});
        println("Program Headers:", .{});
        println("       Type           Offset   Virtual Address    Physical Address   Size on File       Size in memory     Permissions  Alignment", .{});

        for (elf.segments) |segment, i| {
            const header = segment.header;

            print("  [{:>2}] ", .{ i });
            print("{:<15}", .{ @tagName(header.program_type) });
            print("0x{x:0>6} ", .{ header.offset });
            print("0x{x:0>16} ", .{ header.virtual_address });
            print("0x{x:0>16} ", .{ header.physical_address });
            print("0x{x:0>16} ", .{ header.file_size });
            print("0x{x:0>16} ", .{ header.memory_size });
            if (segment.is_readable()) {
                print("R", .{});
            } else {
                print(" ", .{});
            }
            if (segment.is_writable()) {
                print("W", .{});
            } else {
                print(" ", .{});
            }
            if (segment.is_executable()) {
                print("X", .{});
            } else {
                print(" ", .{});
            }
            print("          0x{x:0>4} ", .{ header.alignment });

            println("", .{});
        }
    }

    if (args.print_sections) {
        println("", .{});
        println("Section Headers:", .{ });
        println("       Name                Type                Address            Offset   Size     Entry Size  Flags  Link  Info  Alignment", .{});

        for (elf.sections) |section, i| {
            const header = section.header;

            print("  [{:>2}] ", .{ i });
            print("{:<20}", .{ section.name });
            print("{:<20}", .{ @tagName(header.section_type) });
            print("0x{x:0>16} ", .{ header.address });
            print("0x{x:0>6} ", .{ header.offset });
            print("0x{x:0>6} ", .{ header.size });
            print("0x{x:0>2}        ", .{ header.entry_size });
            if (section.is_allocated()) {
                print("A", .{});
            } else {
                print(" ", .{});
            }
            if (section.is_writable()) {
                print("W", .{});
            } else {
                print(" ", .{});
            }
            if (section.is_executable()) {
                print("X", .{});
            } else {
                print(" ", .{});
            }
            if (section.has_info_link()) {
                print("I", .{});
            } else {
                print(" ", .{});
            }
            print("  {:>2} ", .{ header.link });
            print("    {:>2} ", .{ header.info });
            print("   {:>2} ", .{ header.alignment });

            println("", .{});
        }
    }
}

