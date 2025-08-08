const UnderlyingInt = u64;

pub const Time = union(enum) {
    ms: UnderlyingInt,
    s: UnderlyingInt,

    pub fn fromMillis(n: UnderlyingInt) Time {
        return .{
            .ms = n,
        };
    }

    pub fn fromSeconds(n: UnderlyingInt) Time {
        return .{
            .s = n,
        };
    }

    pub fn toMillis(self: Time) UnderlyingInt {
        return switch (self) {
            .s => |s| s * S_TO_MS,
            .ms => |ms| ms,
        };
    }

    pub fn toSeconds(self: Time) UnderlyingInt {
        return switch (self) {
            .s => |s| s,
            .ms => |ms| ms / S_TO_MS,
        };
    }

    pub fn add(self: Time, rhs: Time) Time {
        return .fromMillis(
            self.toMillis() + rhs.toMillis(),
        );
    }

    pub fn subtract(self: Time, rhs: Time) Time {
        return .fromMillis(
            self.toMillis() - rhs.toMillis(),
        );
    }

    pub fn gt(self: Time, rhs: Time) bool {
        return self.toMillis() > rhs.toMillis();
    }

    pub fn lt(self: Time, rhs: Time) bool {
        return self.toMillis() < rhs.toMillis();
    }

    const S_TO_MS = 1000;
};
