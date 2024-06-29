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

fn mvwDrawFullCharacter(window: *ncurses.WINDOW, y: u32, x: u32, num: u4) void {
    const lines: [3]*const [5:0]u8 = switch (num) {
        0 => .{ "     ", "     ", "     " },
        1 => .{ " /|  ", "  |  ", "__|__" },
        2 => .{ ",\"`\\ ", "   / ", "_<{__" },
        3 => .{ ".-`-,", "  --{", "`-_-\"" },
        4 => .{ "  /| ", " /_|_", "   | " },
        5 => .{ "|\"\"\" ", "\"--. ", ".__/ " },
        6 => .{ "/``+ ", "|--. ", "\\__/ " },
        7 => .{ ":---o", "   / ", "  /  " },
        8 => .{ "{```}", " }-{ ", "{___}" },
        9 => .{ "/```\\", "'---|", ".___/" },
        else => unreachable,
    };
    for (lines, 0..) |line, i| {
        assert(ncurses.mvwaddstr(window, @intCast(y + i), @intCast(x), line) == ncurses.OK);
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
        .grid = .{.{Cell{ .not_clue = 0 }} ** 9} ** 9,
        .row = 0,
        .col = 0,
    };
    reverseCell(main_window, 1, 1, 3, 7);
    if (ncurses.wrefresh(main_window) == ncurses.ERR) unreachable;
    unreverseCell(main_window, 1 + 4 * @as(u32, game.row), 1 + 8 * @as(u32, game.col), 3, 7);
    while (true) {
        const ch = ncurses.getch();
        game = if (switch (ch) {
            'h' => move(game, Move.left),
            'j' => move(game, Move.down),
            'k' => move(game, Move.up),
            'l' => move(game, Move.right),

            '1'...'9' => |num| toggleNum(game, @intCast(num - '1')),
            // shift blocks
            '!' => toggleCell(game, 0),
            '@' => toggleCell(game, 1),
            '#' => toggleCell(game, 2),
            '$' => toggleCell(game, 3),
            '%' => toggleCell(game, 4),
            '^' => toggleCell(game, 5),
            '&' => toggleCell(game, 6),
            '*' => toggleCell(game, 7),
            '(' => toggleCell(game, 8),
            // ')' => toggleCell(game, 10),

            'q' => return,
            else => error.InvalidMove,
        }) |val| val else |err| switch (err) {
            error.InvalidMove => game,
        };
        // std.debug.print("{}", .{game.grid[game.row][game.col].not_clue});
        reverseCell(main_window, 1 + 4 * @as(u32, game.row), 1 + 8 * @as(u32, game.col), 3, 7);
        mvwDrawCell(main_window, game, game.row, game.col);
        if (ncurses.wrefresh(main_window) == ncurses.ERR) unreachable;
        unreverseCell(main_window, 1 + 4 * @as(u32, game.row), 1 + 8 * @as(u32, game.col), 3, 7);
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
    // uses binary search
    return if (num < 0b000_010_000) {
        if (num < 0b000_000_010) {
            return if (num < 0b000_000_001) 0 else 1;
        } else {
            return if (num < 0b000_001_000) {
                return if (num < 0b000_000_100) 2 else 3;
            } else 4;
        }
    } else {
        if (num < 0b010_000_000) {
            return if (num < 0b001_000_000) {
                return if (num < 0b000_100_000) 5 else 6;
            } else 7;
        } else {
            return if (num < 0b100_000_000) 8 else 9;
        }
    };
}
test "index fn" {
    try testing.expectEqual(indexOfGretestBit(0), 0);
    for (0..8) |i| {
        try testing.expectEqual(@as(u4, @intCast(i + 1)), indexOfGretestBit(@as(u9, 1) << @intCast(i)));
    }
}

fn numToChar(num: u4) u8 {
    return if (num == 0) ' ' else '0' + @as(u8, num);
}

fn mvwDrawCell(window: *ncurses.WINDOW, game: GameState, row: u4, col: u4) void {
    switch (game.grid[row][col]) {
        .clue => |val| {
            mvwDrawFullCharacter(window, 1 + 4 * @as(u32, row), 2 + 8 * @as(u32, col), val);
        },
        .not_clue => |val| {
            if ((val & (val -% 1)) == 0) {
                mvwDrawFullCharacter(window, 1 + 4 * @as(u32, row), 2 + 8 * @as(u32, col), indexOfGretestBit(val));
            } else {
                const zeroToThree = [_]u4{ 0, 1, 2 };
                const oneToTwo = [_]u4{ 1, 2 };
                for (zeroToThree) |i| {
                    const n1 = i * 3;
                    const ch1 = numToChar(if (@as(u9, 1) << n1 & val == 0) 0 else n1 + 1);
                    _ = ncurses.mvwaddch(window, 1 + 4 * @as(i32, row) + i, 2 + 8 * @as(i32, col), ch1);
                    for (oneToTwo) |j| {
                        const n = i * 3 + j;
                        const ch = numToChar(if (@as(u9, 1) << n & val == 0) 0 else n + 1);
                        _ = ncurses.waddch(window, ' ');
                        _ = ncurses.waddch(window, ch);
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
        .not_clue => |*val| {
            val.* ^= (@as(u9, 1) << num);
            // std.debug.print("{}", .{val.*});
        },
    }
    assert(new_game.grid[game.row][game.col].not_clue != game.grid[game.row][game.col].not_clue);
    return new_game;
}
fn toggleCell(game: GameState, num: u4) !GameState {
    var new_game = game;
    switch (new_game.grid[game.row][game.col]) {
        .clue => return error.InvalidMove,
        .not_clue => |*val| {
            const nval = (@as(u9, 1) << num);
            val.* = if (val.* == nval) 0 else nval;
            // std.debug.print("{}", .{val.*});
        },
    }
    return new_game;
}
