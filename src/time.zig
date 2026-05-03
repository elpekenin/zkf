const Int = u64;

pub const Time = enum(Int) {
    _, // value in us

    pub fn us(n: Int) Time {
        return @enumFromInt(n);
    }

    pub fn ms(n: Int) Time {
        return .us(n * 1000);
    }

    pub fn s(n: Int) Time {
        return .ms(n * 1000);
    }

    pub fn toUs(self: Time) Int {
        return @intFromEnum(self);
    }

    pub fn toMs(self: Time) Int {
        return self.toUs() * 1000;
    }

    pub fn toS(self: Time) Int {
        return self.toMs() * 1000;
    }

    pub fn add(self: Time, other: Time) Time {
        return .us(self.toUs() + other.toUs());
    }

    pub fn subtract(self: Time, other: Time) Time {
        return .us(self.toUs() - other.toUs());
    }

    pub fn gt(self: Time, other: Time) bool {
        return self.toUs() > other.toUs();
    }

    pub fn lt(self: Time, other: Time) bool {
        return self.toUs() < other.toUs();
    }
};
