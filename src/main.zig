const std = @import("std");
const lib2048 = @import("./lib2048.zig");
const ncurses = @cImport({
    @cInclude("ncurses.h");
});
const menu = @cImport({
    @cInclude("menu.h");
});
const locale = @cImport({
    @cInclude("locale.h");
});

pub fn main() !void {
    _ = locale.setlocale(locale.LC_ALL, "");
    _ = ncurses.initscr(); // initialize main screen
    defer _ = ncurses.endwin(); // free main screen
    _ = ncurses.cbreak(); // intercept all keys immediately except for C-c and C-z, also see raw()
    _ = ncurses.curs_set(0); // hide cursor
    _ = ncurses.noecho(); // disable echoing input
    _ = ncurses.keypad(ncurses.stdscr, true); // enable arrow keys
    const ItemData = struct {
        name: [*:0]const u8,
        description: [*:0]const u8,
        play: *const fn () void,
    };
    const menu_options = [_]ItemData{
        ItemData{ .name = "2048", .description = "a 2048 game", .play = lib2048.play },
        ItemData{ .name = "suduko", .description = "regular suduko", .play = lib2048.play },
    };
    var menu_items: [menu_options.len + 1]?*menu.ITEM = undefined;
    for (menu_options, 0..) |option, i| {
        menu_items[i] = menu.new_item(option.name, option.description);
    }
    menu_items[2] = null;
    defer for (menu_items[0..menu_options.len]) |menu_item| {
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
                _ = ncurses.mvprintw(20, 20, "function called!");
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
