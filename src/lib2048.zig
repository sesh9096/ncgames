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

const MoveError = error{
    InvalidMove,
};

const GameState = struct {
    grid: [4][4]u8,
    transition: [4][4]u8 = undefined,
    score: u64 = 0,
    zeros: u8 = undefined,
    prev_move: Move = Move.left,
    fn addRandomDigit(state: *GameState, rand: std.Random) void {
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
    fn move(state: GameState, direction: Move) MoveError!GameState {
        var result = GameState{
            .score = state.score,
            .zeros = 0,
            .prev_move = direction,
            .grid = undefined,
            .transition = undefined,
        };
        result.score = state.score;
        result.zeros = 0;
        switch (direction) {
            .left => {
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
            .right => {
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
            .down => {
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
            .up => {
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

    fn turn(state: GameState, direction: Move, rand: std.Random) MoveError!GameState {
        var new_state = try move(state, direction);
        new_state.addRandomDigit(rand);
        return new_state;
    }

    fn gameOver(state: GameState) bool {
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
};

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
    var state = GameState{
        .grid = .{.{0} ** 4} ** 4,
        .zeros = 16,
        .score = 0,
        .transition = .{.{0} ** 4} ** 4,
        .prev_move = Move.left,
    };
    for (0..2) |_| {
        state.addRandomDigit(rand);
    }
    const L = std.DoublyLinkedList(GameState);
    const Node = L.Node;
    var history = L{};
    defer while (history.pop()) |node| {
        allocator.destroy(node);
    };
    var current_node = allocator.create(Node) catch {
        std.debug.print("Cannot Allocate Memory", .{});
        return;
    };
    current_node.data = state;
    history.append(current_node);
    printState(cell_width, cell_height, main_window, score_window, state, history.len);
    while (!state.gameOver()) {
        const ch = ncurses.getch();
        _ = ncurses.wrefresh(echo_window);
        if (switch (ch) {
            'h', ncurses.KEY_LEFT => state.turn(.left, rand),
            'j', ncurses.KEY_DOWN => state.turn(.down, rand),
            'k', ncurses.KEY_UP => state.turn(.up, rand),
            'l', ncurses.KEY_RIGHT => state.turn(.right, rand),
            'u' => {
                if (current_node.prev) |prev| {
                    current_node = prev;
                    state = prev.data;
                    printState(cell_width, cell_height, main_window, score_window, state, history.len);
                } else {
                    assert(ncurses.wattron(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
                    _ = ncurses.mvwprintw(echo_window, 0, 0, "No previous history");
                    assert(ncurses.wattroff(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
                    _ = ncurses.wrefresh(echo_window);
                    _ = ncurses.wclear(echo_window);
                }
                continue;
            },
            'r' => {
                if (current_node.next) |next| {
                    current_node = next;
                    state = next.data;
                    printState(cell_width, cell_height, main_window, score_window, state, history.len);
                } else {
                    assert(ncurses.wattron(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
                    _ = ncurses.mvwprintw(echo_window, 0, 0, "No next history");
                    assert(ncurses.wattroff(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
                    _ = ncurses.wrefresh(echo_window);
                    _ = ncurses.wclear(echo_window);
                }
                continue;
            },
            'q' => return,
            else => MoveError.InvalidMove,
        }) |new_state| {
            while (current_node != history.last) {
                _ = history.pop();
            }
            current_node = allocator.create(Node) catch {
                std.debug.print("Cannot Allocate Memory", .{});
                return;
            };
            current_node.data = new_state;
            history.append(current_node);
            state = new_state;
        } else |err| {
            switch (err) {
                error.InvalidMove => {
                    assert(ncurses.wattron(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
                    _ = ncurses.mvwprintw(echo_window, 0, 0, "Invalid Move");
                    assert(ncurses.wattroff(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
                    _ = ncurses.wrefresh(echo_window);
                    _ = ncurses.wclear(echo_window);
                },
            }
        }
        printState(cell_width, cell_height, main_window, score_window, state, history.len);
    }
    assert(ncurses.wattron(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
    _ = ncurses.mvwprintw(echo_window, 0, 0, "You have lost, final score:%u\n", state.score);
    assert(ncurses.wattroff(echo_window, ncurses.COLOR_PAIR(2)) == ncurses.OK);
    printState(cell_width, cell_height, main_window, score_window, state, history.len);
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
    try testing.expect(!game1.gameOver());
    try testing.expect(!game2.gameOver());
    try testing.expect(game3.gameOver());
}

fn printState(comptime cell_width: usize, comptime cell_height: usize, main_window: *ncurses.WINDOW, score_window: *ncurses.WINDOW, state: GameState, moves: usize) void {
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
    const state = GameState{
        .grid = [4][4]u8{
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
            [_]u8{ 0, 0, 0, 0 },
        },
        .zeros = 16,
    };
    const after = state.move(Move.left);
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
    const after = state.move(Move.left);
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
    const actual = try before.move(Move.left);
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
        .prev_move = .left,
        .score = 12,
    };
    const actual = try before.move(Move.left);
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
        .prev_move = .right,
    };
    const actual = try before.move(Move.right);
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
        .prev_move = .up,
    };
    const actual = try before.move(Move.up);
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
        .prev_move = .down,
    };
    const actual = try before.move(Move.down);
    try testing.expectEqual(expected, actual);
}
test "rand != rand" { // sanity check
    var prng = std.rand.DefaultPrng.init(0);
    const rand = prng.random();
    try testing.expect(rand.int(u64) != rand.int(u64));
}
