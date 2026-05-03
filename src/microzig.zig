const microzig = @import("microzig");
const zkf = @import("zkf");

pub const scan = @import("microzig/scan.zig");
pub const usb = @import("microzig/usb.zig");

pub fn getTime() zkf.Time {
    return .us(microzig.hal.time.get_time_since_boot().to_us());
}
