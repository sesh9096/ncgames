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
    fn singleValue(self: Cell) bool {
        return switch (self) {
            .clue => true,
            .not_clue => |val| val != 0 and (val & (val -% 1)) == 0,
        };
    }
    fn asMask(self: Cell) u9 {
        return switch (self) {
            .clue => |val| 1 << val,
            .not_clue => |val| val,
        };
    }
    fn asIndex(self: Cell) !u4 {
        return switch (self) {
            .clue => |val| val,
            .not_clue => |val| if (isBitmaskWithOneOne(u9, val)) indexOfGretestBit(val) else error.NotSingleValue,
        };
    }
};

fn isBitmaskWithOneOne(T: type, val: T) bool {
    return val != 0 and (val & (val -% 1)) == 0;
}

const ImportGame = [9][9]u4;

const GameState = struct {
    grid: [9][9]Cell,
    row: u4,
    col: u4,
    fn solved(game: GameState) bool {
        // const zeroToNine = [_]u4{ 0, 1, 2, 3, 4, 5, 6, 7, 8 };
        var rows: [9]u9 = .{0} ** 9;
        var cols: [9]u9 = .{0} ** 9;
        var boxes: [3][3]u9 = .{0} ** 9;
        for (game.grid, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                const val = cell.asMask();
                if (!cell.singleValue()) return false;
                if (rows[i] & val == 1) return false;
                if (cols[j] & val == 1) return false;
                if (boxes[i / 3][j / 3] & val == 1) return false;
                rows[i] |= val;
                cols[j] |= val;
                boxes[i / 3][j / 3] |= val;
            }
        }
        return true;
    }
};

fn iGameToGameState(game: ImportGame) GameState {
    var state = GameState{ .col = 0, .row = 0, .grid = undefined };
    for (game, &state.grid) |game_row, *state_row| {
        for (game_row, state_row) |num, *cell| {
            cell.* = if (num == 0) .{ .not_clue = 0 } else .{ .clue = num };
        }
    }
    return state;
}

fn mvwDrawFullCharacter(window: *ncurses.WINDOW, y: u32, x: u32, num: u4) void {
    const lines: [3]*const [7:0]u8 = switch (num) {
        0 => .{ "       ", "       ", "       " },
        1 => .{ "  /|   ", "   |   ", " __|__ " },
        2 => .{ " ,\"`\\  ", "    /  ", " _<{__ " },
        3 => .{ " .-`-, ", "   --{ ", " `-_-\" " },
        4 => .{ "  /|   ", " /_|_, ", "   |   " },
        5 => .{ " |\"\"\"\" ", " \"---. ", " .___/ " },
        6 => .{ " /```+ ", " |---. ", " \\___/ " },
        7 => .{ " :---o ", "    /  ", "   /   " },
        8 => .{ " {```} ", "  }-{  ", " {___} " },
        9 => .{ " /```\\ ", " '---| ", " .___/ " },
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
    // /_|_,
    //   |

    // |""""
    // "---.
    // .___/

    // /```+
    // |---.
    // \___/

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

// .{
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//     .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 },
// }
pub fn play() void {
    _ = ncurses.clear();
    _ = ncurses.refresh();
    _ = ncurses.init_pair(2, ncurses.COLOR_CYAN, ncurses.COLOR_BLACK);
    _ = ncurses.init_pair(3, ncurses.COLOR_RED, ncurses.COLOR_BLACK);
    // var prng = std.rand.DefaultPrng.init(blk: {
    //     var seed: u64 = undefined;
    //     std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    //     break :blk seed;
    // });
    // var rand = prng.random();
    var main_window: *ncurses.WINDOW = undefined;
    // 73 columns+\n
    if (ncurses.LINES > 37 and ncurses.COLS > 74) {
        main_window = ncurses.newwin(37, 74, 0, 0).?;
    } else {
        return;
    }
    defer if (ncurses.delwin(main_window) == ncurses.ERR) std.debug.print("could not delete window", .{});
    var game = iGameToGameState(.{
        .{ 0, 0, 6, 0, 4, 0, 0, 0, 9 },
        .{ 0, 0, 0, 0, 0, 9, 4, 0, 7 },
        .{ 0, 0, 7, 0, 0, 1, 5, 0, 8 },
        .{ 0, 0, 0, 0, 0, 3, 0, 0, 2 },
        .{ 9, 0, 5, 0, 0, 0, 7, 0, 3 },
        .{ 2, 0, 0, 5, 0, 0, 0, 0, 0 },
        .{ 6, 0, 4, 8, 0, 0, 9, 0, 0 },
        .{ 7, 0, 1, 9, 0, 0, 0, 0, 0 },
        .{ 8, 0, 0, 0, 2, 0, 3, 0, 0 },
    });
    drawFullGrid(main_window) catch return;
    drawAllCells(main_window, game);
    drawFocusedCell(main_window, game);
    assert(ncurses.wrefresh(main_window) == ncurses.OK);
    mvwDrawCell(main_window, game, game.row, game.col);
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
        drawFocusedCell(main_window, game);
        if (ncurses.wrefresh(main_window) == ncurses.ERR) unreachable;
        mvwDrawCell(main_window, game, game.row, game.col);
    }
}

fn drawFocusedCell(window: *ncurses.WINDOW, game: GameState) void {
    assert(ncurses.wattron(window, ncurses.A_REVERSE) == ncurses.OK);
    defer assert(ncurses.wattroff(window, ncurses.A_REVERSE) == ncurses.OK);
    mvwDrawCell(window, game, game.row, game.col);
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
            mvwDrawFullCharacter(window, 1 + 4 * @as(u32, row), 1 + 8 * @as(u32, col), val);
        },
        .not_clue => |val| {
            _ = ncurses.wattron(window, ncurses.COLOR_PAIR(2));
            defer _ = ncurses.wattroff(window, ncurses.COLOR_PAIR(2));
            if ((val & (val -% 1)) == 0) {
                mvwDrawFullCharacter(window, 1 + 4 * @as(u32, row), 1 + 8 * @as(u32, col), indexOfGretestBit(val));
            } else {
                const zeroToThree = [_]u4{ 0, 1, 2 };
                for (zeroToThree) |i| {
                    _ = ncurses.mvwaddch(window, 1 + 4 * @as(i32, row) + i, 1 + 8 * @as(i32, col), ' ');
                    for (zeroToThree) |j| {
                        const n = i * 3 + j;
                        const ch = numToChar(if (@as(u9, 1) << n & val == 0) 0 else n + 1);
                        _ = ncurses.waddch(window, ch);
                        _ = ncurses.waddch(window, ' ');
                    }
                }
            }
        },
    }
}

fn drawAllCells(window: *ncurses.WINDOW, game: GameState) void {
    for (0..9) |row| {
        for (0..9) |col| {
            mvwDrawCell(window, game, @intCast(row), @intCast(col));
        }
    }
}

fn drawFullGrid(window: *ncurses.WINDOW) !void {
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

// fn range(comptime T: type, start: T, end: T) [end - start]T {
//     var vals:[]T = undefined;
//     return vals;
// }
/// returns a 2d array of bools indicating if there are conflicts in the gameState
/// true means the cell is invalid, false means it is valid
/// this function only checks cells which have only 1 value
fn detectBadCells(game: GameState) [9][9]bool {
    // iterate through the grid and keep track of the position of each digit in row, column, or box
    // if overlap, mark the current cell and the stored cell
    // otherwise, save the location of the cell.
    const Pair = struct { row: u4, col: u4 };
    var rows: [9][9]?Pair = .{.{null} ** 9} ** 9;
    var cols: [9][9]?Pair = .{.{null} ** 9} ** 9;
    var boxes: [3][3][9]?Pair = .{.{.{null} ** 9} ** 3} ** 3;
    var bad_cells: [9][9]bool = .{.{false} ** 9} ** 9;
    for (game.grid, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            const cellVal = cell.asIndex() catch continue;
            if (rows[i][cellVal] != null) {
                bad_cells[rows[i][cellVal].?.row][rows[i][cellVal].?.col] = true;
                bad_cells[i][j] = true;
            } else {
                rows[i][cellVal] = Pair{ .row = @intCast(i), .col = @intCast(j) };
            }
            if (cols[j][cellVal] != null) {
                bad_cells[cols[j][cellVal].?.row][cols[j][cellVal].?.col] = true;
                bad_cells[i][j] = true;
            } else {
                cols[j][cellVal] = Pair{ .row = @intCast(i), .col = @intCast(j) };
            }
            const box = &boxes[i / 3][j / 3][cellVal];
            if (box.* != null) {
                bad_cells[box.*.?.row][box.*.?.col] = true;
                bad_cells[i][j] = true;
            } else {
                box.* = Pair{ .row = @intCast(i), .col = @intCast(j) };
            }
        }
    }
    return bad_cells;
}

test "bad cells" {
    const game = iGameToGameState(.{
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 1, 4 },
        .{ 0, 3, 0, 0, 2, 0, 0, 4, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 3, 0, 0, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 5, 0, 0, 0, 0, 0, 5 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 },
    });
    const expected: [9][9]bool = .{
        .{ false, false, false, false, false, false, false, false, false },
        .{ false, false, false, false, false, false, false, false, true },
        .{ false, true, false, false, false, false, false, true, false },
        .{ false, false, false, false, false, false, false, false, false },
        .{ false, true, false, false, false, false, false, false, false },
        .{ false, false, false, false, false, false, false, false, false },
        .{ false, false, true, false, false, false, false, false, true },
        .{ false, false, false, false, false, false, false, false, false },
        .{ false, false, false, false, false, false, false, false, false },
    };
    const actual = detectBadCells(game);
    try testing.expectEqual(expected, actual);
}
