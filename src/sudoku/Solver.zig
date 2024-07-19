const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

pub fn solve(grid: [9][9]u4) SolverError![9][9]u4 {
    var game = SolverGrid.fromIGame(grid);
    game.deduce();
    return game.toIGame();
}

pub const SolverError = error{
    NoSolution,
    MultipleSolutions,
    Unsolved, // should not turn up in result unless something goes wrong
};
const SolverGrid = struct {
    const Cell = union {
        data: u9,
        fn singleValue(self: Cell) bool {
            return self.data != 0 and (self.data & (self.data -% 1)) == 0;
        }
        fn removeMark(self: *Cell, other: Cell) void {
            self = Cell{ .data = self.data & ~other.data };
        }
        fn indexOfGretestBit(self: Cell) u4 {
            const num = self.data;
            // note: this is one based
            // uses binary search
            return if (num < 1 << 4) {
                if (num < 1 << 1) {
                    return if (num < 1 << 0) 0 else 1;
                } else {
                    return if (num < 1 << 3) {
                        return if (num < 1 << 2) 2 else 3;
                    } else 4;
                }
            } else {
                if (num < 1 << 7) {
                    return if (num < 1 << 6) {
                        return if (num < 1 << 5) 5 else 6;
                    } else 7;
                } else {
                    return if (num < 1 << 8) 8 else 9;
                }
            };
        }
    };
    grid: [9][9]Cell,
    queue: struct {
        array: [81]Point, // this should be all that is needed
        beg: u8 = 0,
        end: u8 = 0,
        fn append(history: @This(), point: Point) void {
            history.array[history.end] = point;
            history.end += 1;
        }
        fn pop(history: @This()) ?Point {
            if (history.beg == history.end) {
                return null;
            } else {
                history.beg += 1;
                return history.array[history.beg - 1];
            }
        }
    },
    fn fromIGame(grid: [9][9]u4) SolverGrid {
        var solver_grid: SolverGrid = undefined;
        for (grid, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                solver_grid[i][j].data = if (cell != 0) 1 << (cell - 1) else ~0;
                solver_grid.queue.append(Point(i, j));
            }
        }
        return solver_grid;
    }
    fn toIGame(self: SolverGrid) [4][4]u9 {
        var i_game: [4][4]u9 = undefined;
        for (self.grid, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                i_game[i][j] = cell.indexOfGretestBit();
            }
        }
        return i_game;
    }
    fn step(self: *SolverGrid) SolverError!void {
        if (self.queue.pop()) |point| {
            const cellval = self.grid[point.row][point.col];
            assert(cellval.singleValue());
            for (point.getRelated()) |related_point| {
                const cellptr = &self.grid[related_point.row][related_point.col];
                const cell = cellptr.*;
                cellptr.removeMark(cell);
                if (!cell.singleValue() and cellptr.singleValue()) {
                    self.queue.append(related_point);
                } else if (cellptr.data == 0) {
                    return error.NoSolution;
                }
            }
        } else {
            //
        }
    }
    const Ocurrences = struct {
        row: [9][9][]Point = undefined,
        col: [9][9][]Point = undefined,
        block: [3][3][9][]Point = undefined,
        row_data: [9][9][9]?Point = undefined,
        col_data: [9][9][9]?Point = undefined,
        block_data: [3][3][9][9]?Point = undefined,
    };
    fn relations(self: SolverGrid) Ocurrences {
        // search for hidden
        // scan rows & cols for single
        var occurrences: Ocurrences = .{};
        for (0..9) |val| {
            for (0..9) |i| {
                for (0..9) |col| {
                    if (self.grid[i][col] & @as(u9, 1) << @intCast(val) != 0) {
                        const pre_slice_len = occurrences.col[col][val].len;
                        occurrences.col_data[col][val][pre_slice_len];
                        occurrences.col[col][val] = occurrences.col_data[col][val][0..pre_slice_len];
                    }
                    for (0..9) |row| {
                        if (self.grid[row][i] & @as(u9, 1) << @intCast(val) != 0) {
                            const pre_slice_len = occurrences.row[row][val].len;
                            occurrences.row_data[row][val][pre_slice_len];
                            occurrences.row[row][val] = occurrences.row_data[row][val][0..pre_slice_len];
                        }
                    }
                }
            }
        }
    }
    fn deduce(self: *SolverGrid) SolverError!void {
        while (self.queue.pop()) |point| {
            const cellval = self.grid[point.row][point.col];
            assert(cellval.singleValue());
            for (point.getRelated()) |related_point| {
                const cellptr = &self.grid[related_point.row][related_point.col];
                const cell = cellptr.*;
                cellptr.removeMark(cell);
                if (!cell.singleValue() and cellptr.singleValue()) {
                    self.queue.append(related_point);
                } else if (cellptr.data == 0) {
                    return error.NoSolution;
                }
            }
        }
    }
};

const Point = struct {
    row: u4,
    col: u4,
    fn getRelated(self: Point) [20]Point {
        var related: [20]Point = undefined;
        var i: u5 = 0;
        for (0..9) |j| {
            if (j != self.row) {
                related[i] = Point{ .row = @intCast(j), .col = self.col };
                i += 1;
            }
            if (j != self.col) {
                related[i] = Point{ .row = self.row, .col = @intCast(j) };
                i += 1;
            }
        }
        assert(i == 16);
        const brow = self.row - (self.row % 3);
        const bcol = self.col - (self.col % 3);
        for (brow..(brow + 3)) |row| {
            if (row != self.row) {
                for (bcol..(bcol + 3)) |col| {
                    if (col != self.col) {
                        related[i] = Point{ .row = @intCast(row), .col = @intCast(col) };
                        i += 1;
                    }
                }
            }
        }
        return related;
    }
};

test "get related" {
    const related = Point.getRelated(.{ .row = 5, .col = 5 });
    const expected = [_]Point{
        .{ .row = 0, .col = 5 },
        .{ .row = 1, .col = 5 },
        .{ .row = 2, .col = 5 },
        .{ .row = 3, .col = 5 },
        .{ .row = 4, .col = 5 },
        .{ .row = 6, .col = 5 },
        .{ .row = 7, .col = 5 },
        .{ .row = 8, .col = 5 },
        .{ .row = 5, .col = 0 },
        .{ .row = 5, .col = 1 },
        .{ .row = 5, .col = 2 },
        .{ .row = 5, .col = 3 },
        .{ .row = 5, .col = 4 },
        .{ .row = 5, .col = 6 },
        .{ .row = 5, .col = 7 },
        .{ .row = 5, .col = 8 },
        .{ .row = 3, .col = 3 },
        .{ .row = 4, .col = 3 },
        .{ .row = 3, .col = 4 },
        .{ .row = 4, .col = 4 },
    };
    outer: for (expected) |point| {
        for (related) |rpoint| {
            if (point.row == rpoint.row and point.col == rpoint.col) continue :outer;
        }
        return error.ElementNotInSet;
    }
}
