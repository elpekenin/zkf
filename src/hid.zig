const std = @import("std");

pub const Keycode = u8;

pub const Modifiers = packed struct(u8) {
    left_control: bool,
    left_shift: bool,
    left_alt: bool,
    left_gui: bool,
    right_control: bool,
    right_shift: bool,
    right_alt: bool,
    right_gui: bool,

    pub fn add(self: *Modifiers, other: Modifiers) void {
        self.* = .from(self.mask() | other.mask());
    }

    pub fn remove(self: *Modifiers, other: Modifiers) void {
        self.* = .from(self.mask() & ~other.mask());
    }

    pub const empty: Modifiers = @bitCast(@as(u8, 0));

    pub const lc: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.left_control = true;
        break :blk value;
    };

    pub const ls: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.left_shift = true;
        break :blk value;
    };

    pub const la: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.left_alt = true;
        break :blk value;
    };

    pub const lg: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.left_gui = true;
        break :blk value;
    };

    pub const rc: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.right_control = true;
        break :blk value;
    };

    pub const rs: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.right_shift = true;
        break :blk value;
    };

    pub const ra: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.right_alt = true;
        break :blk value;
    };

    pub const rg: Modifiers = blk: {
        var value: Modifiers = .empty;
        value.right_gui = true;
        break :blk value;
    };

    fn from(value: u8) Modifiers {
        return @bitCast(value);
    }

    fn mask(self: Modifiers) u8 {
        return @bitCast(self);
    }
};

pub const KbToHost = extern struct {
    modifiers: Modifiers,

    keycodes: [n_keycodes]Keycode,

    pub const empty: KbToHost = .{
        .modifiers = .empty,
        .keycodes = @splat(0),
    };

    pub fn eql(self: *const KbToHost, other: KbToHost) bool {
        return self.modifiers == other.modifiers and std.mem.eql(Keycode, self.keycodes, other.keycodes);
    }

    pub fn addMods(self: *KbToHost, modifiers: Modifiers) void {
        self.modifiers.add(modifiers);
    }

    pub fn removeMods(self: *KbToHost, modifiers: Modifiers) void {
        self.modifiers.remove(modifiers);
    }

    pub fn addKc(self: *KbToHost, keycode: Keycode) void {
        for (&self.keycodes) |*kc| {
            // already in place
            if (kc.* == keycode) {
                return;
            }

            // empty slot
            if (kc.* == 0) {
                kc.* = keycode;
                std.log.debug("{} added to report", .{keycode});
                return;
            }
        }

        std.log.err("HID report is full, can't add {}", .{keycode});
    }

    pub fn removeKc(self: *KbToHost, keycode: Keycode) void {
        for (&self.keycodes) |*kc| {
            if (kc.* == keycode) {
                kc.* = 0;
                std.log.debug("{} removed from report", .{keycode});
                return;
            }
        }

        std.log.err("{} not in HID report, can't remove it", .{keycode});
    }

    const n_keycodes = 6;
};

pub const HostToKb = packed struct(u8) {
    num: bool,
    caps: bool,
    scroll: bool,
    compose: bool,
    kana: bool,
    _: u3,

    pub const empty: HostToKb = @bitCast(@as(u8, 0));
};

pub const State = extern struct {
    report: KbToHost,
    host_leds: HostToKb,

    pub const empty: State = .{
        .report = .empty,
        .host_leds = .empty,
    };
};

const t = std.testing;

test "Modifiers.add" {
    var expected: Modifiers = .empty;
    expected.left_shift = true;
    expected.left_control = true;

    var actual: Modifiers = .empty;
    actual.add(.ls);
    actual.add(.lc);

    try t.expectEqual(expected, actual);
}

test "Modifiers.pop" {
    const expected: Modifiers = .lc;

    var actual: Modifiers = .ls;
    actual.add(.lc);
    actual.remove(.ls);

    try t.expectEqual(expected, actual);
}

test "Report.addKeycode" {
    var report: KbToHost = .empty;

    const keycode: Keycode = 123;
    report.addKc(keycode);

    for (report.keycodes) |actual| {
        if (actual == keycode) {
            break;
        }
    } else {
        return error.KeycodeNotAdded;
    }
}
