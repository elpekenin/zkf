//! platform-specific logic
//!
//! to be provided by user, as the "glue" for the lib to interact with hardware

const zkf = @import("zkf");

pub const GetTime = *const fn () zkf.Time;
pub const SendHid = *const fn (*const zkf.hid.KbToHost) void;
pub const ScanKeys = *const fn (*const zkf.Keyboard) zkf.keys.State;

getTime: GetTime,
sendHid: SendHid,
scanKeys: ScanKeys,
