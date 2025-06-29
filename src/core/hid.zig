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

    pub fn from(value: u8) Modifiers {
        return @bitCast(value);
    }

    pub fn mask(self: Modifiers) u8 {
        return @bitCast(self);
    }

    pub fn add(lhs: Modifiers, rhs: Modifiers) Modifiers {
        return .from(lhs.mask() | rhs.mask());
    }

    pub fn pop(lhs: Modifiers, rhs: Modifiers) Modifiers {
        return .from(lhs.mask() & ~rhs.mask());
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
};

pub const Report = extern struct {
    modifiers: Modifiers,
    keycodes: [N]Keycode,

    pub fn initEmpty() Report {
        return .{
            .modifiers = .empty,
            .keycodes = .{0} ** N,
        };
    }

    pub fn eql(self: *const Report, rhs: Report) bool {
        return std.mem.eql(
            u8,
            std.mem.asBytes(self),
            std.mem.asBytes(&rhs),
        );
    }

    pub fn addModifiers(self: *Report, modifiers: Modifiers) void {
        self.modifiers = self.modifiers.add(modifiers);
    }

    pub fn popModifiers(self: *Report, modifiers: Modifiers) void {
        self.modifiers = self.modifiers.pop(modifiers);
    }

    pub fn addKeycode(self: *Report, keycode: Keycode) !void {
        for (&self.keycodes) |*kc| {
            // already in place
            if (kc.* == keycode) {
                return;
            }

            // empty slot
            if (kc.* == 0) {
                kc.* = keycode;
                return;
            }
        }

        return error.OutOfMemory;
    }

    pub fn popKeycode(self: *Report, keycode: Keycode) !void {
        for (&self.keycodes) |*kc| {
            if (kc.* == keycode) {
                kc.* = 0;
                return;
            }
        }

        return error.NotFound;
    }

    const N = 6;
};

pub const HostLeds = packed struct(u8) {
    num: bool,
    caps: bool,
    scroll: bool,
    compose: bool,
    kana: bool,
    _: u3,

    pub const empty: HostLeds = @bitCast(@as(u8, 0));
};

pub const State = extern struct {
    report: Report,
    host_leds: HostLeds,

    pub fn init() State {
        return .{
            .report = .initEmpty(),
            .host_leds = .empty,
        };
    }
};

const std = @import("std");
