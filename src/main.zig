const std = @import("std");
const lib2048 = @import("./lib2048.zig");
const ncurses = @cImport({
    @cInclude("ncurses.h");
});
const locale = @cImport({
    @cInclude("locale.h");
});

pub fn main() !void {
    _ = locale.setlocale(locale.LC_ALL, "");
    _ = ncurses.initscr();
    defer _ = ncurses.endwin();
    _ = ncurses.cbreak();
    _ = ncurses.curs_set(0);
    _ = ncurses.noecho();
    // _ = ncurses.printw("All your %s are belong to us.\n", "codebase");

    var game: [4][4]u8 = .{.{0} ** 4} ** 4;
    // for history, don't need this yet
    // const L= std.SinglyLinkedList([4][4]u8);
    // var list = L{};
    // list.prepend(&.{ .data = initial_game });
    while (!lib2048.gameOver(game)) {
        for (game) |row| {
            for (row) |cell| {
                const printed_value = @as(u64, 1) << @as(u6, @intCast(cell));
                // _ = ncurses.printw("%u ", @as(u64, 1) << @as(u6, @intCast(cell)));
                _ = ncurses.printw("%u ", printed_value);
                // _ = ncurses.printw("%u ", cell);
            }
            _ = ncurses.printw("\n");
        }
        _ = ncurses.refresh();
        _ = ncurses.move(0, 0);
        game = switch (ncurses.getch()) {
            'h' => lib2048.turn(game, lib2048.Move.left),
            'j' => lib2048.turn(game, lib2048.Move.down),
            'k' => lib2048.turn(game, lib2048.Move.up),
            'l' => lib2048.turn(game, lib2048.Move.right),
            'q' => return,
            else => game,
        };
    }
    _ = ncurses.move(0, 0);
    _ = ncurses.printw("You have lost \n");
    _ = ncurses.getch();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!
    // ╭────────╮
    // │        │
    // │  2048  │
    // │        │
    // ╰────────╯
    // ┌────┬────┐
    // │    │    │
    // ├────┼────┤
    // │    │    │
    // └────┴────┘

}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
