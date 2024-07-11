const std = @import("std");
const testing = std.testing;
const ncurses = @cImport({
    @cInclude("ncurses.h");
});

const Move = enum {
    left,
    down,
    up,
    right,
};

const MoveError = error{
    InvalidMove,
};

const GameState = struct {
    grid: [4][4]u8,
    transition: [4][4]u8 = undefined,
    score: u64 = 0,
    zeros: u8 = undefined,
    move: Move = Move.left,
};

pub fn play() void {
    _ = ncurses.clear();
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    var rand = prng.random();
    const cell_width = 10;
    const cell_height = 5;
    // var game: [4][4]u8 = .{.{0} ** 4} ** 4;
    var state = GameState{
        .grid = .{.{0} ** 4} ** 4,
        .zeros = 16,
        .score = 0,
        .transition = .{.{0} ** 4} ** 4,
        .move = Move.left,
    };
    for (0..2) |_| {
        addRandomDigit(&state, &rand);
    }
    // for history, don't need this yet
    // const L= std.SinglyLinkedList([4][4]u8);
    // var list = L{};
    // list.prepend(&.{ .data = initial_game });
    while (!gameOver(state)) {
        for (state.grid, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                // _ = ncurses.move(@intCast(i * cell_height), @intCast(j * cell_width));
                const printed_value = @as(u64, 1) << @as(u6, @intCast(cell));
                // _ = ncurses.printw("%u ", @as(u64, 1) << @as(u6, @intCast(cell)));
                if (printed_value != 1) {
                    printCell(@intCast(i * cell_height), @intCast(j * cell_width), printed_value);
                } else {
                    printEmptyCell(@intCast(i * cell_height), @intCast(j * cell_width));
                }
                // _ = ncurses.printw("%u ", cell);
            }
            _ = ncurses.printw("\n");
        }
        _ = ncurses.refresh();
        const ch = ncurses.getch();
        state = switch (ch) {
            'h' => turn(state, Move.left, &rand),
            'j' => turn(state, Move.down, &rand),
            'k' => turn(state, Move.up, &rand),
            'l' => turn(state, Move.right, &rand),
            'q' => return,
            else => MoveError.InvalidMove,
        } catch state;
    }
    _ = ncurses.mvprintw(0, 0, "You have lost \n");
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

fn move(state: GameState, direction: Move) MoveError!GameState {
    var result = GameState{
        .score = state.score,
        .zeros = 0,
        .move = direction,
        .grid = undefined,
        .transition = undefined,
    };
    result.score = state.score;
    result.zeros = 0;
    switch (direction) {
        Move.left => {
            for (state.grid, &result.grid, &result.transition) |arr, *new_arr, *transition_array| {
                var i: u8 = 0;
                var prev: u8 = 0;
                var prev_index: u8 = 0;
                for (arr, 0..) |cell, index| {
                    if (cell == 0) {
                        continue;
                    } else if (cell == prev) {
                        new_arr.*[i] = prev + 1;
                        result.score += @as(u64, 1) << @as(u6, @intCast(prev + 1));
                        transition_array.*[prev_index] = i;
                        transition_array.*[index] = i;
                        prev = 0;
                    } else if (prev == 0) {
                        prev = cell;
                        prev_index = @intCast(index);
                        continue;
                    } else {
                        new_arr.*[i] = prev;
                        prev = cell;
                        transition_array.*[prev_index] = i;
                        prev_index = @intCast(index);
                    }
                    i += 1;
                }
                if (prev != 0) {
                    new_arr.*[i] = prev;
                    transition_array.*[prev_index] = i;
                    i += 1;
                }
                for (i..state.grid[0].len) |j| new_arr.*[j] = 0;
                result.zeros += @intCast(state.grid[0].len - i);
            }
        },
        Move.right => {
            for (state.grid, &result.grid, &result.transition) |arr, *new_arr, *transition_array| {
                var i: u8 = arr.len - 1;
                var prev: u8 = 0;
                var arr_cpy = arr;
                var prev_index: u8 = 0;
                std.mem.reverse(u8, arr_cpy[0..]);
                for (arr_cpy, 1..) |cell, f_index| {
                    const index: u8 = @intCast(arr.len - f_index);
                    if (cell == 0) {
                        continue;
                    } else if (cell == prev) {
                        new_arr.*[i] = prev + 1;
                        result.score += @as(u64, 1) << @as(u6, @intCast(prev + 1));
                        transition_array.*[prev_index] = i;
                        transition_array.*[index] = i;
                        prev = 0;
                    } else if (prev == 0) {
                        prev = cell;
                        prev_index = index;
                        continue;
                    } else {
                        new_arr.*[i] = prev;
                        prev = cell;
                        transition_array.*[prev_index] = i;
                        prev_index = index;
                    }
                    i -= 1;
                }
                if (prev != 0) {
                    new_arr.*[i] = prev;
                    transition_array.*[prev_index] = i;
                } else {
                    i += 1;
                }
                for (0..i) |j| new_arr.*[j] = 0;
                result.zeros += i;
            }
        },
        Move.down => {
            for (0..state.grid[0].len) |j| {
                var i_after: u8 = state.grid.len - 1;
                var prev: u8 = 0;
                var prev_index: u8 = 0;

                var i: u8 = state.grid.len - 1;
                inner: while (true) : ({
                    if (i != 0) i -= 1 else break :inner;
                }) {
                    // std.debug.print("{} ", .{i});
                    if (state.grid[i][j] == 0) {
                        continue;
                    } else if (state.grid[i][j] == prev) {
                        result.grid[i_after][j] = prev + 1;
                        result.score += @as(u64, 1) << @as(u6, @intCast(prev + 1));
                        result.transition[prev_index][j] = i_after;
                        result.transition[i][j] = i_after;
                        prev = 0;
                    } else if (prev == 0) {
                        prev = state.grid[i][j];
                        prev_index = i;
                        continue;
                    } else {
                        result.grid[i_after][j] = prev;
                        prev = state.grid[i][j];
                        result.transition[prev_index][j] = i_after;
                        prev_index = i;
                    }
                    i_after -= 1;
                }
                if (prev != 0) {
                    result.transition[prev_index][j] = i_after;
                    result.grid[i_after][j] = prev;
                } else {
                    // we are now using this to represent the number left rather than the index
                    i_after += 1;
                }
                for (0..i_after) |index| result.grid[index][j] = 0;
                result.zeros += i_after;
            }
        },
        Move.up => {
            for (0..state.grid.len) |j| {
                var i_after: u8 = 0;
                var prev: u8 = 0;
                var prev_index: u8 = 0;
                for (0..state.grid.len) |i| {
                    if (state.grid[i][j] == 0) {
                        continue;
                    } else if (state.grid[i][j] == prev) {
                        result.grid[i_after][j] = prev + 1;
                        result.score += @as(u64, 1) << @as(u6, @intCast(prev + 1));
                        result.transition[prev_index][j] = @intCast(i_after);
                        result.transition[i][j] = @intCast(i_after);
                        prev = 0;
                    } else if (prev == 0) {
                        prev = state.grid[i][j];
                        prev_index = @intCast(i);
                        continue;
                    } else {
                        result.grid[i_after][j] = prev;
                        prev = state.grid[i][j];
                        result.transition[prev_index][j] = @intCast(i_after);
                        prev_index = @intCast(i);
                    }
                    i_after += 1;
                }
                if (prev != 0) {
                    result.grid[i_after][j] = prev;
                    result.transition[prev_index][j] = @intCast(i_after);
                    i_after += 1;
                }
                for (i_after..state.grid[0].len) |index| result.grid[index][j] = 0;
                result.zeros += @intCast(state.grid[0].len - i_after);
            }
        },
    }
    if (gridEq(state.grid, result.grid)) return MoveError.InvalidMove;
    return result;
}

pub fn addRandomDigit(state: *GameState, rand: *std.Random) void {
    // const zeros = countZeros(grid.*);
    var i = rand.uintLessThan(u8, state.zeros);
    for (&state.grid) |*row| {
        for (row) |*cell| {
            if (cell.* == 0) {
                if (i == 0) {
                    cell.* = if (rand.uintLessThan(u8, 10) == 0) 2 else 1;
                    state.zeros -= 1;
                    return;
                }
                i -= 1;
            }
        }
    }
}

// pub fn countZeros(state:GameState) u8 {
//     var zeros: u8 = 0;
//     for (state.grid) |row| {
//         for (row) |cell| {
//             if (cell == 0) {
//                 zeros += 1;
//             }
//         }
//     }
//     return zeros;
// }

pub fn turn(state: GameState, direction: Move, rand: *std.Random) MoveError!GameState {
    var new_state = try move(state, direction);
    addRandomDigit(&new_state, rand);
    return new_state;
}

// pub fn hasZeros(grid: [4][4]u8) bool {
//     for (grid) |row| {
//         for (row) |cell| {
//             if (cell == 0) {
//                 return true;
//             }
//         }
//     }
//     return false;
// }

pub fn gameOver(state: GameState) bool {
    const grid = state.grid;
    if (state.zeros > 0) {
        return false;
    } else {
        for (0..grid.len) |i| {
            for (0..grid[0].len - 1) |j| {
                if (grid[i][j] == grid[i][j + 1]) return false;
            }
        }
        for (0..grid.len - 1) |i| {
            for (0..grid[0].len) |j| {
                if (grid[i][j] == grid[i + 1][j]) return false;
            }
        }
        return true;
    }
}

test "game over" {
    const game1 = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 1, 1, 0 },
            [_]u8{ 1, 0, 2, 0 },
            [_]u8{ 0, 1, 3, 0 },
            [_]u8{ 0, 1, 4, 0 },
        },
        .zeros = 8,
    };
    const game2 = GameState{
        .grid = [4][4]u8{
            [_]u8{ 1, 2, 1, 5 },
            [_]u8{ 2, 3, 3, 1 },
            [_]u8{ 2, 5, 3, 4 },
            [_]u8{ 3, 1, 4, 1 },
        },
        .zeros = 0,
    };
    const game3 = GameState{
        .grid = [4][4]u8{
            [_]u8{ 1, 2, 1, 5 },
            [_]u8{ 4, 3, 4, 1 },
            [_]u8{ 2, 5, 3, 4 },
            [_]u8{ 3, 1, 4, 1 },
        },
        .zeros = 0,
    };
    try testing.expect(!gameOver(game1));
    try testing.expect(!gameOver(game2));
    try testing.expect(gameOver(game3));
}

pub fn printCell(y: c_int, x: c_int, n: u64) void {
    _ = ncurses.mvprintw(y + 0, x, "╭────────╮");
    _ = ncurses.mvprintw(y + 1, x, "│        │");
    _ = ncurses.mvprintw(y + 2, x, "│  %4u  │", n);
    _ = ncurses.mvprintw(y + 3, x, "│        │");
    _ = ncurses.mvprintw(y + 4, x, "╰────────╯");
}

pub fn printEmptyCell(y: c_int, x: c_int) void {
    inline for (0..5) |i| {
        _ = ncurses.mvaddstr(y + @as(c_int, i), x, " " ** 10);
    }
}

fn printGrid(grid: [4][4]u8) void {
    for (grid) |arr| {
        for (arr) |val| {
            std.debug.print("{} ", .{val});
        }
        std.debug.print("\n", .{});
    }
}

fn gridEq(a: [4][4]u8, b: [4][4]u8) bool {
    for (a, b) |a_arr, b_arr| {
        if (!std.mem.eql(u8, &a_arr, &b_arr)) return false;
    }
    return true;
}
// fn checkState(before: GameState, expected: GameState, actual: GameState) !void {
//     try testing.expectEqual(expected.zeros, actual.zeros);
//     var zeros: u8 = 0;
//     for (0..expected.grid.len) |i| {
//         for (0..expected.grid[0].len) |j| {
//             try testing.expectEqual(expected.grid[i][j], actual.grid[i][j]);
//             if (before.grid[i][j] != 0) {
//                 try testing.expectEqual(expected.transition[i][j], actual.transition[i][j]);
//             }
//             if (actual.grid[i][j] == 0) {
//                 zeros += 1;
//             }
//         }
//     }
//     try testing.expectEqual(zeros, actual.zeros);
// }

test "zero" {
    const state = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
        },
        .zeros = 16,
    };
    const after = move(state, Move.left);
    try testing.expectEqual(after, MoveError.InvalidMove);
}
test "invalid move" {
    const state = GameState{
        .grid = [4][4]u8{
            [_]u8{ 1, 0, 0, 0 },
            [_]u8{ 1, 0, 0, 0 },
            [_]u8{ 1, 0, 0, 0 },
            [_]u8{ 1, 0, 0, 0 },
        },
        .zeros = 16,
    };
    const after = move(state, Move.left);
    try testing.expectEqual(after, MoveError.InvalidMove);
}
test "simple left" {
    const before = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 1, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 1, 0, 0, 1 },
        },
        .zeros = 13,
    };
    const u = undefined;
    const expected = GameState{
        .grid = [4][4]u8{
            [_]u8{ 1, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 2, 0, 0, 0 },
        },
        .zeros = 14,
        .transition = [4][4]u8{
            [_]u8{ u, 0, u, u },
            [_]u8{ u, u, u, u },
            [_]u8{ u, u, u, u },
            [_]u8{ 0, u, u, 0 },
        },
        .score = 4,
    };
    const actual = try move(before, Move.left);
    try testing.expectEqual(actual, expected);
}
test "more complicated left" {
    const before = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 1, 1, 1 },
            [_]u8{ 1, 1, 1, 1 },
            [_]u8{ 1, 2, 1, 2 },
            [_]u8{ 0, 2, 3, 4 },
        },
        .zeros = 2,
    };
    const u = undefined;
    const expected = GameState{
        .grid = [4][4]u8{
            [_]u8{ 2, 1, 0, 0 },
            [_]u8{ 2, 2, 0, 0 },
            [_]u8{ 1, 2, 1, 2 },
            [_]u8{ 2, 3, 4, 0 },
        },
        .zeros = 5,
        .transition = [4][4]u8{
            [_]u8{ u, 0, 0, 1 },
            [_]u8{ 0, 0, 1, 1 },
            [_]u8{ 0, 1, 2, 3 },
            [_]u8{ u, 0, 1, 2 },
        },
        .move = .left,
        .score = 12,
    };
    const actual = try move(before, Move.left);
    try testing.expectEqual(actual, expected);
    // try testing.expect(std.mem.eql([4][4]u8, after, expected));
}
test "simple right" {
    const before = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 1, 0, 0 },
            [_]u8{ 0, 0, 0, 1 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 1, 0, 1, 1 },
        },
        .zeros = 13,
    };
    const u = undefined;
    const expected = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 0, 0, 1 },
            [_]u8{ 0, 0, 0, 1 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 1, 2 },
        },
        .transition = [4][4]u8{
            [_]u8{ u, 3, u, u },
            [_]u8{ u, u, u, 3 },
            [_]u8{ u, u, u, u },
            [_]u8{ 2, u, 3, 3 },
        },
        .zeros = 12,
        .score = 4,
        .move = .right,
    };
    const actual = try move(before, Move.right);
    // printGrid(after.grid);
    // printGrid(after.transition);
    try testing.expectEqual(actual, expected);
}
test "not so simple up" {
    const before = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 1, 1, 0 },
            [_]u8{ 0, 0, 2, 0 },
            [_]u8{ 0, 1, 3, 0 },
            [_]u8{ 1, 1, 4, 0 },
        },
        .zeros = 8,
    };
    const u = undefined;
    const expected = GameState{
        .grid = [4][4]u8{
            [_]u8{ 1, 2, 1, 0 },
            [_]u8{ 0, 1, 2, 0 },
            [_]u8{ 0, 0, 3, 0 },
            [_]u8{ 0, 0, 4, 0 },
        },
        .transition = [4][4]u8{
            [_]u8{ u, 0, 0, u },
            [_]u8{ u, u, 1, u },
            [_]u8{ u, 0, 2, u },
            [_]u8{ 0, 1, 3, u },
        },
        .zeros = 9,
        .score = 4,
        .move = .up,
    };
    const actual = try move(before, Move.up);
    // printGrid(after.transition);
    try testing.expectEqual(expected, actual);
}
test "down" {
    const before = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 1, 1, 0 },
            [_]u8{ 1, 0, 2, 0 },
            [_]u8{ 0, 3, 3, 0 },
            [_]u8{ 0, 3, 4, 0 },
        },
        .zeros = 8,
    };
    const u = undefined;
    const expected = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 0, 1, 0 },
            [_]u8{ 0, 0, 2, 0 },
            [_]u8{ 0, 1, 3, 0 },
            [_]u8{ 1, 4, 4, 0 },
        },
        .transition = [4][4]u8{
            [_]u8{ u, 2, 0, u },
            [_]u8{ 3, u, 1, u },
            [_]u8{ u, 3, 2, u },
            [_]u8{ u, 3, 3, u },
        },
        .zeros = 9,
        .score = 16,
        .move = .down,
    };
    const actual = try move(before, Move.down);
    try testing.expectEqual(expected, actual);
}
test "rand != rand" { // sanity check
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    var rand = prng.random();
    var rand2 = rand;
    try testing.expect(rand.int(u64) != rand2.int(u64));
}
