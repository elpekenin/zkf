const zkf = @import("zkf");

const Trigger = union(enum) {
    positions: []const zkf.keys.Id,
    keycodes: []const zkf.Keycode,
};

trigger: Trigger,
action: zkf.Keycode,
