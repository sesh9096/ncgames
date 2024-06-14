const ncurses = @cImport({
    @cInclude("ncurses.h");
});

pub fn main() !void {
    ncurses.initscr();
    ncurses.printw("Hello World !!!");
    ncurses.refresh();
    ncurses.getch();
    ncurses.endwin();
    return 0;
}
