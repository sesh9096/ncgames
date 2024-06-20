const std = @import("std");
const testing = std.testing;
const ncurses = @cImport({
    @cInclude("ncurses.h");
});

const GameState = struct {
    game: [9][9][10]bool,
};

pub fn play() void {
    _ = ncurses.clear();
    _ = ncurses.refresh();
    // var prng = std.rand.DefaultPrng.init(blk: {
    //     var seed: u64 = undefined;
    //     std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    //     break :blk seed;
    // });
    // var rand = prng.random();
    const background = ncurses.newwin(ncurses.LINES, ncurses.COLS, 0, 0).?;
    defer if (ncurses.delwin(background) == ncurses.ERR) std.debug.print("could not delete window", .{});
    printFullGrid(background) catch return;
    _ = ncurses.wrefresh(background);
    _ = ncurses.getch();
    _ = ncurses.mvprintw(0, 0, "You have lost \n");
    _ = ncurses.getch();
}

pub fn printFullGrid(window: *ncurses.WINDOW) !void {
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
