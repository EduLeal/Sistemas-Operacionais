
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Recebe os argumentos da linha de comando
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 2) {
        std.debug.print("Uso: programa <arquivo>\n", .{});
        return;
    }

    const filename = args[1];

    // Carrega os primeiros 512 bytes do arquivo no buffer
    var buffer: [512]u8 = undefined;

    const bytes = std.Io.Dir.readFile(
        std.Io.Dir.cwd(),
        init.io,
        filename,
        &buffer,
    ) catch |err| {
        std.debug.print("Erro ao ler o arquivo: {}\n", .{err});
        return;
    };

    // Verifica se o arquivo possui pelo menos 512 bytes
    if (bytes.len < 512) {
        std.debug.print(
            "Erro: o arquivo tem menos de 512 bytes.\n",
            .{},
        );
        return;
    }

    // Lê os bytes 510 e 511 (índices iniciados em zero)
    const b510 = bytes[510];
    const b511 = bytes[511];

    std.debug.print("Byte 510: 0x{X:0>2}\n", .{b510});
    std.debug.print("Byte 511: 0x{X:0>2}\n", .{b511});

    // A assinatura MBR deve ser 55 AA, nesta ordem
    if (b510 != 0x55 or b511 != 0xAA) {
        std.debug.print(
            "\n>>> NAO POSSUI ASSINATURA MBR <<<\n",
            .{},
        );
        return;
    }

    std.debug.print(
        "\n>>> ASSINATURA MBR ENCONTRADA <<<\n",
        .{},
    );

    // Interpreta os dois bytes como um u16 na ordem nativa da máquina
    const valor_memoria =
        @as(*align(1) const u16, @ptrCast(&bytes[510])).*;

    std.debug.print(
        "Valor lido como u16: 0x{X:0>4}\n",
        .{valor_memoria},
    );

    // Descobre o endianness a partir da ordem dos bytes interpretados
    if (valor_memoria == 0xAA55) {
        std.debug.print(
            "Arquitetura: Little-Endian\n",
            .{},
        );
    } else if (valor_memoria == 0x55AA) {
        std.debug.print(
            "Arquitetura: Big-Endian\n",
            .{},
        );
    } else {
        std.debug.print(
            "Nao foi possivel determinar o endianness.\n",
            .{},
        );
    }
}
