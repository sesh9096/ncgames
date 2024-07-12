const Game = @This();
const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const History = std.DoublyLinkedList(GameState);
const Node = History.Node;

state: GameState = .{
    .grid = .{.{0} ** 4} ** 4,
    .zeros = 16,
    .score = 0,
    .transition = .{.{0} ** 4} ** 4,
    .prev_move = Move.left,
},
allocator: std.mem.Allocator,
rand: std.Random,
history: History,
current_node: *History.Node,

const Action = enum {
    left,
    down,
    up,
    right,
    undo,
    redo,
};

const Move = enum {
    left,
    down,
    up,
    right,
};

const ActionError = error{
    InvalidMove,
    NoPreviousNode,
    NoNextNode,
};
const MoveError = error{
    InvalidMove,
};

pub fn deinit(self: *Game) void {
    while (self.history.pop()) |node| {
        self.allocator.destroy(node);
    }
}
pub fn init(allocator: std.mem.Allocator, rand: std.Random) Game {
    var game = Game{
        .state = .{
            .grid = .{.{0} ** 4} ** 4,
            .zeros = 16,
            .score = 0,
            .transition = .{.{0} ** 4} ** 4,
            .prev_move = .left,
        },
        .allocator = allocator,
        .rand = rand,
        .history = History{},
        .current_node = undefined,
    };
    for (0..2) |_| {
        game.state.addRandomDigit(rand);
    }
    var current_node = allocator.create(Node) catch {
        std.debug.print("Cannot Allocate Memory", .{});
        unreachable;
    };
    game.current_node = current_node;
    current_node.data = game.state;
    game.history.append(current_node);
    return game;
}

pub fn doAction(self: *Game, action: Action) ActionError!void {
    // var game: [4][4]u8 = .{.{0} ** 4} ** 4;
    if (switch (action) {
        .undo => {
            if (self.current_node.prev) |prev| {
                self.current_node = prev;
                self.state = prev.data;
            } else {
                return error.NoPreviousNode;
            }
            return;
        },
        .redo => {
            if (self.current_node.next) |next| {
                self.current_node = next;
                self.state = next.data;
            } else {
                return error.NoNextNode;
            }
            return;
        },
        .left => self.turn(.left),
        .right => self.turn(.right),
        .up => self.turn(.up),
        .down => self.turn(.down),
    }) |new_state| {
        while (self.current_node != self.history.last) {
            self.allocator.destroy(self.history.pop().?);
        }
        self.current_node = self.allocator.create(Node) catch {
            std.debug.print("Cannot Allocate Memory", .{});
            return;
        };
        self.current_node.data = new_state;
        self.history.append(self.current_node);
        self.state = new_state;
    } else |err| {
        switch (err) {
            error.InvalidMove => {},
        }
    }
}

fn turn(self: Game, direction: Move) MoveError!GameState {
    var new_state = try self.state.move(direction);
    new_state.addRandomDigit(self.rand);
    return new_state;
}

pub fn gameOver(self: Game) bool {
    return self.state.gameOver();
}

pub const GameState = struct {
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

test "Memory Safety" {
    const allocator = std.testing.allocator;
    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();
    var game = Game.init(allocator, rand);
    try game.doAction(.left);
    try game.doAction(.right);
    try game.doAction(.up);
    try game.doAction(.down);
    try game.doAction(.undo);
    try game.doAction(.left);
    try game.doAction(.undo);
    try game.doAction(.redo);
    try testing.expectError(error.NoNextNode, game.doAction(.redo));
    game.deinit();
}
