const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const Game = @import("Game.zig");
test {
    _ = Game;
}
const ncurses = @cImport({
    @cInclude("ncurses.h");
});

pub fn play() void {
    _ = ncurses.clear();
    _ = ncurses.refresh();
    assert(ncurses.init_pair(2, ncurses.COLOR_WHITE, ncurses.COLOR_RED) == ncurses.OK);
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = prng.random();
    const cell_width = 10;
    const cell_height = 5;
    const allocator = std.heap.c_allocator;
    const main_window = ncurses.newwin(cell_height * 4 + 1, cell_width * 4 + 1, 1, 0).?;
    const score_window = ncurses.newwin(1, ncurses.COLS, 0, 0).?;
    const echo_window = ncurses.newwin(1, ncurses.COLS, cell_height * 4 + 2, 0).?;
    // var game: [4][4]u8 = .{.{0} ** 4} ** 4;
    var game = Game.init(allocator, rand);
    defer game.deinit();
    printState(cell_width, cell_height, main_window, score_window, game.state, game.history.len);
    while (!game.gameOver()) {
        const ch = ncurses.getch();
        _ = ncurses.wrefresh(echo_window);
        if (switch (ch) {
            'h', ncurses.KEY_LEFT => game.doAction(.left),
            'j', ncurses.KEY_DOWN => game.doAction(.down),
            'k', ncurses.KEY_UP => game.doAction(.up),
            'l', ncurses.KEY_RIGHT => game.doAction(.right),
            'u' => game.doAction(.undo),
            'r' => game.doAction(.redo),
            'q' => return,
            else => error.InvalidMove,
        }) {} else |err| {
            assert(ncurses.wattron(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
            _ = ncurses.mvwprintw(echo_window, 0, 0, switch (err) {
                error.InvalidMove => "Invalid Move",
                error.NoNextNode => "No Next Node",
                error.NoPreviousNode => "No Previous Node",
            });
            _ = ncurses.wrefresh(echo_window);
            _ = ncurses.wclear(echo_window);
            assert(ncurses.wattroff(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
        }
        printState(cell_width, cell_height, main_window, score_window, game.state, game.history.len);
    }
    assert(ncurses.wattron(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
    _ = ncurses.mvwprintw(echo_window, 0, 0, "You have lost, final score:%u\n", game.state.score);
    assert(ncurses.wattroff(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
    printState(cell_width, cell_height, main_window, score_window, game.state, game.history.len);
    _ = ncurses.wrefresh(echo_window);
    _ = ncurses.getch();

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

fn printState(comptime cell_width: usize, comptime cell_height: usize, main_window: *ncurses.WINDOW, score_window: *ncurses.WINDOW, state: Game.GameState, moves: usize) void {
    for (state.grid, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            const printed_value = @as(u64, 1) << @as(u6, @intCast(cell));
            if (printed_value != 1) {
                printCell(main_window, @intCast(i * cell_height), @intCast(j * cell_width), printed_value);
            } else {
                printEmptyCell(main_window, @intCast(i * cell_height), @intCast(j * cell_width));
            }
        }
    }
    _ = ncurses.wclear(score_window);
    assert(ncurses.mvwprintw(score_window, 0, 0, "Score: %u, moves: %u", state.score, moves) == ncurses.OK);
    _ = ncurses.wrefresh(main_window);
    _ = ncurses.wrefresh(score_window);
}
fn printCell(window: *ncurses.WINDOW, y: c_int, x: c_int, n: u64) void {
    _ = ncurses.mvwprintw(window, y + 0, x, "╭────────╮");
    _ = ncurses.mvwprintw(window, y + 1, x, "│        │");
    _ = ncurses.mvwprintw(window, y + 2, x, "│  %4u  │", n);
    _ = ncurses.mvwprintw(window, y + 3, x, "│        │");
    _ = ncurses.mvwprintw(window, y + 4, x, "╰────────╯");
}

pub fn printEmptyCell(window: *ncurses.WINDOW, y: c_int, x: c_int) void {
    inline for (0..5) |i| {
        _ = ncurses.mvwaddstr(window, y + @as(c_int, i), x, " " ** 10);
    }
}
