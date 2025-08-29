const std = @import("std");
const microzig = @import("microzig");

const rp2xxx = microzig.hal;
const usb = rp2xxx.usb;

const hid = usb.hid;

fn info(args: anytype) std.builtin.Type.Struct {
    return @typeInfo(@TypeOf(args)).@"struct";
}

fn len(args: anytype) usize {
    var length: usize = 0;
    inline for (info(args).fields) |field| {
        length += @field(args, field.name).len;
    }
    return length;
}

fn flatten(args: anytype) [len(args)]u8 {
    var array: [len(args)]u8 = undefined;

    var i: usize = 0;
    inline for (info(args).fields) |field| {
        const value: []const u8 = &@field(args, field.name);

        const length = value.len;
        defer i += length;

        @memcpy(array[i .. i + length], value);
    }

    return array;
}

pub const report_descriptor = flatten(.{
    hid.hid_usage_page(1, hid.UsageTable.desktop),
    hid.hid_usage(1, hid.DesktopUsage.keyboard),
    hid.hid_collection(.Application),
    hid.hid_usage_page(1, hid.UsageTable.keyboard),
    // FIXME: next 2 lines' values look wrong
    hid.hid_usage_min(1, .{0xe2}), // left alt
    hid.hid_usage_max(1, .{0xe6}), // right_shift
    hid.hid_logical_min(1, .{0x00}),
    hid.hid_logical_max(1, .{0x01}),
    hid.hid_report_size(1, .{0x01}),
    hid.hid_report_count(1, .{0x08}),
    hid.hid_input(hid.HID_DATA | hid.HID_VARIABLE | hid.HID_ABSOLUTE),
    hid.hid_report_count(1, .{0x06}),
    hid.hid_report_size(1, .{0x08}),
    hid.hid_logical_max(1, .{0x65}),
    hid.hid_usage_min(1, .{0x00}),
    hid.hid_usage_max(1, .{0x65}),
    hid.hid_input(hid.HID_DATA | hid.HID_ARRAY | hid.HID_ABSOLUTE),
    hid.hid_collection_end(),
});

pub const endpoint_address = rp2xxx.usb.Endpoint.to_address(1, .In);

const usb_packet_size = 7;
const usb_config_len = usb.templates.config_descriptor_len + usb.templates.hid_in_descriptor_len;

const interface_descriptor: usb.types.InterfaceDescriptor = .{
    .interface_number = 1,
    .alternate_setting = 0,
    .num_endpoints = 1,
    .interface_class = 3,
    .interface_subclass = 1,
    .interface_protocol = 1,
    .interface_s = 5,
};

const hid_descriptor: hid.HidDescriptor = .{
    .bcd_hid = 0x0111,
    .country_code = 0,
    .num_descriptors = 1,
    .report_length = report_descriptor.len,
};

const endpoint_descriptor: usb.types.EndpointDescriptor = .{
    .endpoint_address = endpoint_address,
    .attributes = @intFromEnum(usb.types.TransferType.Interrupt),
    .max_packet_size = usb_packet_size,
    .interval = 10,
};

pub const descriptor = flatten(.{
    usb.templates.config_descriptor(1, 1, 0, usb_config_len, 0x80, 500),
    interface_descriptor.serialize(),
    hid_descriptor.serialize(),
    endpoint_descriptor.serialize(),
});
