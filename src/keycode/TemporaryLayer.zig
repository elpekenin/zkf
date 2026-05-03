const zkf = @import("zkf");

const Layers = @import("../Layers.zig");

const TemporaryLayer = @This();

layer: Layers.Id,

pub fn process(self: TemporaryLayer, keyboard: *zkf.Keyboard, event: *const zkf.KeyEvent) void {
    if (event.pressed) {
        keyboard.layers.enable(self.layer);
    } else {
        keyboard.layers.disable(self.layer);
    }
}
