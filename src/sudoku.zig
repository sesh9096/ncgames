const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const ncurses = @cImport({
    @cInclude("ncurses.h");
});

const Move = enum {
    left,
    down,
    up,
    right,
};

const Cell = union(enum) {
    clue: u4,
    not_clue: u9,
};

const GameState = struct {
    grid: [9][9]Cell,
    row: u4,
    col: u4,
};

fn mvwdrawFullCharacter(window: *ncurses.WINDOW, y: u32, x: u32, num: u4) void {
    const lines: [3][5:0]u8 = switch (num) {
        0 => .{ "     ", "     ", "     " },
        // 1=>
        // 2=>
        // 3=>
        // 4=>
        // 5=>
        // 6=>
        // 7=>
        // 8=>
        // 9=>
        _ => unreachable,
    };
    for (lines, 0..) |line, i| {
        assert(ncurses.mvwaddstr(window, y + @as(u32, i), x, line) == ncurses.OK);
    }
    //  /|
    //   |
    // __|__

    // ,"`\
    //    /
    // _<{__

    // .-`-,
    //   --{
    // `-_-"

    //  /|
    // /_|_
    //   |

    // |"""
    // "--.
    // .__/

    // /``+
    // |--.
    // \__/

    // :---o
    //    /
    //   /

    // {```}
    //  }-{
    // {___}

    // /```\
    // '---|
    // .___/
}
//  /|
//   |
// __|__

// ,"`\
//    /
// _<{__

// .-`-,
//   --{
// `-_-"

//  /|
// /_|_
//   |

// |"""
// "--.
// .__/

// /``+
// |--.
// \__/

// :---o
//    /
//   /

// {```}
//  }-{
// {___}

// /```\
// '---|
// .___/

pub fn play() void {
    _ = ncurses.clear();
    _ = ncurses.refresh();
    // var prng = std.rand.DefaultPrng.init(blk: {
    //     var seed: u64 = undefined;
    //     std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    //     break :blk seed;
    // });
    // var rand = prng.random();
    const main_window = ncurses.newwin(ncurses.LINES, ncurses.COLS, 0, 0).?;
    defer if (ncurses.delwin(main_window) == ncurses.ERR) std.debug.print("could not delete window", .{});
    printFullGrid(main_window) catch return;
    if (ncurses.wrefresh(main_window) == ncurses.ERR) unreachable;
    var game = GameState{
        .grid = undefined,
        .row = 0,
        .col = 0,
    };
    reverseCell(main_window, 1, 1, 3, 7);
    if (ncurses.wrefresh(main_window) == ncurses.ERR) unreachable;
    while (true) {
        const ch = ncurses.getch();
        unreverseCell(main_window, 1 + 4 * @as(u32, game.row), 1 + 8 * @as(u32, game.col), 3, 7);
        game = if (switch (ch) {
            'h' => move(game, Move.left),
            'j' => move(game, Move.down),
            'k' => move(game, Move.up),
            'l' => move(game, Move.right),

            '1'...'9' => |num| toggleNum(game, @intCast(num - '0')),
            // shift blocks
            '!' => toggleCell(game, 1),
            '@' => toggleCell(game, 2),
            '#' => toggleCell(game, 3),
            '$' => toggleCell(game, 4),
            '%' => toggleCell(game, 5),
            '^' => toggleCell(game, 6),
            '&' => toggleCell(game, 7),
            '*' => toggleCell(game, 8),
            '(' => toggleCell(game, 9),
            // ')' => toggleCell(game, 10),
            'q' => return,
            else => error.InvalidMove,
        }) |val| val else |err| switch (err) {
            error.InvalidMove => game,
        };
        reverseCell(main_window, 1 + 4 * @as(u32, game.row), 1 + 8 * @as(u32, game.col), 3, 7);
        if (ncurses.wrefresh(main_window) == ncurses.ERR) unreachable;
    }
}

fn unreverseCell(window: *ncurses.WINDOW, y: u32, x: u32, height: u32, width: u32) void {
    for (y..y + height) |line| {
        _ = ncurses.mvwchgat(window, @intCast(line), @intCast(x), @intCast(width), 0, 0, null);
    }
}

fn reverseCell(window: *ncurses.WINDOW, y: u32, x: u32, height: u32, width: u32) void {
    for (y..y + height) |line| {
        _ = ncurses.mvwchgat(window, @intCast(line), @intCast(x), @intCast(width), ncurses.A_REVERSE, 0, null);
    }
}

fn indexOfGretestBit(num: u9) u4 {
    // note: this is one based
    return if (num < 0b000_010_000) {
        if (num < 0b000_000_010) {
            if (num < 0b000_000_001) 0 else 1;
        } else {
            if (num < 0b000_001_000) {
                if (num < 0b000_000_001) 2 else 3;
            } else 4;
        }
    } else {
        if (num < 0b010_000_000) {
            if (num < 0b001_000_000) {
                if (num < 0b000_100_000) 5 else 6;
            } else 7;
        } else {
            if (num < 0b100_000_000) 8 else 9;
        }
    };
}
test "index fn" {
    testing.expectEqual(indexOfGretestBit(0), 0);
    for (0..8) |i| {
        testing.expectEqual(@intCast(1 << i), @intCast(i + 1));
    }
}

fn numToChar(num: u4) u8 {
    return if (num == 0) ' ' else '0' + num;
}

fn mvwDrawCell(window: *ncurses.WINDOW, game: GameState, row: u4, col: u4) void {
    switch (game.grid[row][col]) {
        .clue => {
            // drawFullCharacter();
        },
        .not_clue => |val| {
            if ((val & (val - 1)) == 0) {
                // drawFullCharacter();
            } else {
                for (0..3) |i| {
                    _ = ncurses.mvwaddch(window, 1 + 4 * @as(i32, row + i), 1 + 8 * @as(i32, col));
                    for (0..3) |j| {
                        _ = ncurses.waddch(window, numToChar(i * 3 + j));
                    }
                }
                // _ = ncurses.mvwprintf(window, 1 + 4 * @as(i32, row), 1 + 8 * @as(i32, col), " %i %i %i ", 1, 2, 3);
                // _ = ncurses.mvwprintf(window, 2 + 4 * @as(i32, row), 1 + 8 * @as(i32, col), " %i %i %i ", 4, 5, 6);
                // _ = ncurses.mvwprintf(window, 3 + 4 * @as(i32, row), 1 + 8 * @as(i32, col), " %i %i %i ", 7, 8, 9);
            }
        },
    }
}

fn printFullGrid(window: *ncurses.WINDOW) !void {
    return if (ncurses.mvwaddstr(window, 0, 0,
        \\┏━━━━━━━┯━━━━━━━┯━━━━━━━┳━━━━━━━┯━━━━━━━┯━━━━━━━┳━━━━━━━┯━━━━━━━┯━━━━━━━┓
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┣━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━┫
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┣━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━┫
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┃       │       │       ┃       │       │       ┃       │       │       ┃
        \\┗━━━━━━━┷━━━━━━━┷━━━━━━━┻━━━━━━━┷━━━━━━━┷━━━━━━━┻━━━━━━━┷━━━━━━━┷━━━━━━━┛
    ) == ncurses.ERR) error.PrintError;
}

fn move(game: GameState, action: Move) !GameState {
    return switch (action) {
        .left => if (game.col != 0) GameState{ .grid = game.grid, .col = game.col - 1, .row = game.row } else error.InvalidMove,
        .right => if (game.col != 8) GameState{ .grid = game.grid, .col = game.col + 1, .row = game.row } else error.InvalidMove,
        .up => if (game.row != 0) GameState{ .grid = game.grid, .col = game.col, .row = game.row - 1 } else error.InvalidMove,
        .down => if (game.row != 8) GameState{ .grid = game.grid, .col = game.col, .row = game.row + 1 } else error.InvalidMove,
    };
}

fn toggleNum(game: GameState, num: u4) !GameState {
    var new_game = game;
    switch (new_game.grid[game.row][game.col]) {
        .clue => return error.InvalidMove,
        .not_clue => |*val| val.* ^= (@as(u9, 1) << num),
    }
    return game;
}
fn toggleCell(game: GameState, num: u4) !GameState {
    var new_game = game;
    switch (new_game.grid[game.row][game.col]) {
        .clue => return error.InvalidMove,
        .not_clue => |*val| {
            const nval = (@as(u9, 1) << num);
            val.* = if (val.* == nval) 0 else nval;
        },
    }
    return game;
}
