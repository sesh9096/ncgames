const std = @import("std");
const testing = std.testing;

pub const Move = enum {
    left,
    down,
    up,
    right,
};

pub fn move(grid_before_move: [4][4]u8, direction: Move) [4][4]u8 {
    var grid_after_move: [4][4]u8 = .{.{0} ** 4} ** 4;
    switch (direction) {
        Move.left => {
            for (grid_before_move, &grid_after_move) |arr, *new_arr| {
                var i: u8 = 0;
                var prev: u8 = 0;
                for (arr) |cell| {
                    if (cell == 0) {
                        continue;
                    } else if (cell == prev) {
                        new_arr.*[i] = prev + 1;
                        prev = 0;
                    } else if (prev == 0) {
                        prev = cell;
                        continue;
                    } else {
                        new_arr.*[i] = prev;
                        prev = cell;
                    }
                    i += 1;
                }
                if (prev != 0) {
                    new_arr.*[i] = prev;
                }
            }
        },
        Move.down => {
            for (0..grid_before_move.len) |j| {
                var i_after: u8 = grid_before_move.len - 1;
                var prev: u8 = 0;
                var i: u8 = grid_before_move.len - 1;
                inner: while (true) : ({
                    if (i != 0) i -= 1 else break :inner;
                }) {
                    // std.debug.print("{} ", .{i});
                    if (grid_before_move[i][j] == 0) {
                        continue;
                    } else if (grid_before_move[i][j] == prev) {
                        grid_after_move[i_after][j] = prev + 1;
                        prev = 0;
                    } else if (prev == 0) {
                        prev = grid_before_move[i][j];
                        continue;
                    } else {
                        grid_after_move[i_after][j] = prev;
                        prev = grid_before_move[i][j];
                    }
                    i_after -= 1;
                }
                if (prev != 0) {
                    grid_after_move[i_after][j] = prev;
                }
            }
        },
        Move.up => {
            for (0..grid_before_move.len) |j| {
                var i_after: u8 = 0;
                var prev: u8 = 0;
                for (0..grid_before_move.len) |i| {
                    if (grid_before_move[i][j] == 0) {
                        continue;
                    } else if (grid_before_move[i][j] == prev) {
                        grid_after_move[i_after][j] = prev + 1;
                        prev = 0;
                    } else if (prev == 0) {
                        prev = grid_before_move[i][j];
                        continue;
                    } else {
                        grid_after_move[i_after][j] = prev;
                        prev = grid_before_move[i][j];
                    }
                    i_after += 1;
                }
                if (prev != 0) {
                    grid_after_move[i_after][j] = prev;
                }
            }
        },
        Move.right => {
            for (grid_before_move, &grid_after_move) |arr, *new_arr| {
                var i: u8 = 3;
                var prev: u8 = 0;
                var arr_cpy = arr;
                std.mem.reverse(u8, arr_cpy[0..]);
                for (arr_cpy) |cell| {
                    if (cell == 0) {
                        continue;
                    } else if (cell == prev) {
                        new_arr.*[i] = prev + 1;
                        prev = 0;
                    } else if (prev == 0) {
                        prev = cell;
                        continue;
                    } else {
                        new_arr.*[i] = prev;
                        prev = cell;
                    }
                    i -= 1;
                }
                if (prev != 0) {
                    new_arr.*[i] = prev;
                }
            }
        },
    }
    return grid_after_move;
}

pub fn addRandomDigit(grid: *[4][4]u8) void {
    const zeros = countZeros(grid.*);
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    var i = prng.random().uintLessThan(u8, zeros);
    for (grid) |*row| {
        for (row) |*cell| {
            if (cell.* == 0) {
                if (i == 0) {
                    cell.* = 1;
                    return;
                }
                i -= 1;
            }
        }
    }
}

pub fn countZeros(grid: [4][4]u8) u8 {
    var zeros: u8 = 0;
    for (grid) |row| {
        for (row) |cell| {
            if (cell == 0) {
                zeros += 1;
            }
        }
    }
    return zeros;
}

pub fn turn(grid: [4][4]u8, direction: Move) [4][4]u8 {
    var new_grid = move(grid, direction);
    addRandomDigit(&new_grid);
    return new_grid;
}

pub fn hasZeros(grid: [4][4]u8) bool {
    for (grid) |row| {
        for (row) |cell| {
            if (cell == 0) {
                return true;
            }
        }
    }
    return false;
}

pub fn gameOver(grid: [4][4]u8) bool {
    if (hasZeros(grid)) {
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
    const game1 = [4][4]u8{
        [_]u8{ 0, 1, 1, 0 },
        [_]u8{ 1, 0, 2, 0 },
        [_]u8{ 0, 1, 3, 0 },
        [_]u8{ 0, 1, 4, 0 },
    };
    const game2 = [4][4]u8{
        [_]u8{ 1, 2, 1, 5 },
        [_]u8{ 2, 3, 3, 1 },
        [_]u8{ 2, 5, 3, 4 },
        [_]u8{ 3, 1, 4, 1 },
    };
    const game3 = [4][4]u8{
        [_]u8{ 1, 2, 1, 5 },
        [_]u8{ 4, 3, 4, 1 },
        [_]u8{ 2, 5, 3, 4 },
        [_]u8{ 3, 1, 4, 1 },
    };
    try testing.expect(!gameOver(game1));
    try testing.expect(!gameOver(game2));
    try testing.expect(gameOver(game3));
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

test "zero" {
    const game = [4][4]u8{
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
    };
    const after = move(game, Move.left);
    try testing.expect(gridEq(game, after));
    try testing.expectEqual(16, countZeros(game));
}
test "simple left" {
    const before = [4][4]u8{
        [_]u8{ 0, 1, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 1, 0, 0, 1 },
    };
    const expected = [4][4]u8{
        [_]u8{ 1, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 2, 0, 0, 0 },
    };
    const after = move(before, Move.left);
    for (after, expected) |after_arr, expected_arr| {
        try testing.expect(std.mem.eql(u8, &after_arr, &expected_arr));
    }
    // try testing.expect(std.mem.eql([4][4]u8, after, expected));
}

test "more complicated left" {
    const before = [4][4]u8{
        [_]u8{ 0, 1, 1, 1 },
        [_]u8{ 1, 1, 1, 1 },
        [_]u8{ 1, 2, 1, 2 },
        [_]u8{ 0, 2, 3, 4 },
    };
    const expected = [4][4]u8{
        [_]u8{ 2, 1, 0, 0 },
        [_]u8{ 2, 2, 0, 0 },
        [_]u8{ 1, 2, 1, 2 },
        [_]u8{ 2, 3, 4, 0 },
    };
    const after = move(before, Move.left);
    // printGrid(after);
    try testing.expect(gridEq(expected, after));
    // try testing.expect(std.mem.eql([4][4]u8, after, expected));
}

test "simple right" {
    const before = [4][4]u8{
        [_]u8{ 0, 1, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 1, 0, 0, 1 },
    };
    const expected = [4][4]u8{
        [_]u8{ 0, 0, 0, 1 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 0 },
        [_]u8{ 0, 0, 0, 2 },
    };
    const after = move(before, Move.right);
    for (after, expected) |after_arr, expected_arr| {
        try testing.expect(std.mem.eql(u8, &after_arr, &expected_arr));
    }
    // try testing.expect(std.mem.eql([4][4]u8, after, expected));
    //
    //
}

test "not so simple up" {
    const before = [4][4]u8{
        [_]u8{ 0, 1, 1, 0 },
        [_]u8{ 0, 0, 2, 0 },
        [_]u8{ 0, 1, 3, 0 },
        [_]u8{ 1, 1, 4, 0 },
    };
    const expected = [4][4]u8{
        [_]u8{ 1, 2, 1, 0 },
        [_]u8{ 0, 1, 2, 0 },
        [_]u8{ 0, 0, 3, 0 },
        [_]u8{ 0, 0, 4, 0 },
    };
    const after = move(before, Move.up);
    // printGrid(after);
    for (after, expected) |after_arr, expected_arr| {
        try testing.expect(std.mem.eql(u8, &after_arr, &expected_arr));
    }
    // try testing.expect(std.mem.eql([4][4]u8, after, expected));
}
test "down" {
    const before = [4][4]u8{
        [_]u8{ 0, 1, 1, 0 },
        [_]u8{ 1, 0, 2, 0 },
        [_]u8{ 0, 1, 3, 0 },
        [_]u8{ 0, 1, 4, 0 },
    };
    const expected = [4][4]u8{
        [_]u8{ 0, 0, 1, 0 },
        [_]u8{ 0, 0, 2, 0 },
        [_]u8{ 0, 1, 3, 0 },
        [_]u8{ 1, 2, 4, 0 },
    };
    const after = move(before, Move.down);
    // printGrid(after);
    for (after, expected) |after_arr, expected_arr| {
        try testing.expect(std.mem.eql(u8, &after_arr, &expected_arr));
    }
    // try testing.expect(std.mem.eql([4][4]u8, after, expected));
}
