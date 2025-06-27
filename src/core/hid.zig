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
