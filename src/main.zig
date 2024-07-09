const std = @import("std");
const lib2048 = @import("./lib2048.zig");
const sudoku = @import("./sudoku.zig");
const assert = std.debug.assert;

const ncurses = @cImport({
    @cInclude("ncurses.h");
});
const menu = @cImport({
    @cInclude("menu.h");
});
const locale = @cImport({
    @cInclude("locale.h");
});

test {
    _ = lib2048;
}
test {
    _ = sudoku;
}
pub fn main() !void {
    assert(locale.setlocale(locale.LC_ALL, "") != null);
    _ = ncurses.initscr(); // initialize main screen
    defer _ = ncurses.endwin(); // free main screen
    _ = ncurses.cbreak(); // intercept all keys immediately except for C-c and C-z, also see raw()
    _ = ncurses.curs_set(0); // hide cursor
    _ = ncurses.noecho(); // disable echoing input
    _ = ncurses.start_color();
    _ = ncurses.keypad(ncurses.stdscr, true); // enable arrow keys
    const ItemData = struct {
        name: [*:0]const u8,
        description: [*:0]const u8,
        play: *const fn () void,
    };
    const menu_options = [_]ItemData{
        ItemData{ .name = "2048", .description = "a 2048 game", .play = lib2048.play },
        ItemData{ .name = "suduko", .description = "regular suduko", .play = sudoku.play },
        ItemData{ .name = "dino", .description = "chrome dinosaur game", .play = sudoku.play },
        ItemData{ .name = "typer", .description = "improve your typing skills", .play = sudoku.play },
    };
    var menu_items: [menu_options.len:null]?*menu.ITEM = undefined;
    // even with the type, if initialized as undefined, the null pointer is not included, this may be a bug in zig 0.12
    menu_items[menu_options.len] = null;
    for (menu_options, 0..) |option, i| {
        menu_items[i] = menu.new_item(option.name, option.description);
    }
    defer for (menu_items) |menu_item| {
        _ = menu.free_item(menu_item);
    };
    // for (0..3) |i| {
    //     std.debug.print("item {}, {*}\n", .{ i, menu_items[i] });
    // }

    const ptr = &menu_items[0];
    const game_menu = menu.new_menu(ptr);
    defer _ = menu.free_menu(game_menu);

    _ = menu.post_menu(game_menu);
    defer _ = menu.unpost_menu(game_menu);
    _ = ncurses.refresh();

    menu_loop: while (true) {
        switch (ncurses.getch()) {
            'k', ncurses.KEY_UP => {
                _ = menu.menu_driver(game_menu, menu.REQ_UP_ITEM);
            },
            'j', ncurses.KEY_DOWN => {
                _ = menu.menu_driver(game_menu, menu.REQ_DOWN_ITEM);
            },
            10 => { // enter key
                const ret = menu.item_index(menu.current_item(game_menu));
                const index: usize = if (ret >= 0) @intCast(ret) else continue :menu_loop;
                menu_options[index].play();
                break :menu_loop;
            },
            'q' => {
                break :menu_loop;
            },
            else => {
                continue;
            },
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
