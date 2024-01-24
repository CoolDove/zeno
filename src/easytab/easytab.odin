package easytab

import "core:c"
import win32 "core:sys/windows"

foreign import user32 "system:User32.lib"
foreign import etb "./easytab_c/easytab_msvc.lib"


Buttons :: enum c.int32_t {
    PenTouch = 1 << 0, // Pen is touching tablet
    PenLower = 1 << 1, // Lower pen button is pressed
    PenUpper = 1 << 2, // Upper pen button is pressed
};

TrackingMode :: enum {
    System   = 0,
    Relative = 1,
}
Result :: enum {
    Ok = 0,
    // Errors
    Memory_Error           = -1,
    X11_Error              = -2,
    DLL_Load_Error         = -3,
    Wacom_WIN32_Error      = -4,
    Invalid_Function_Error = -5,

    Event_Not_Handled = -16,
}

when ODIN_OS == .Windows {
	EasyTabInfo :: struct {
		PosX, PosY: c.int32_t,
		Pressure : c.float, // Range: 0.0f to 1.0f
		Buttons : c.int32_t, // Bit field. Use with the EasyTab_Buttons_ enum.
		RangeX, RangeY : c.int32_t,
		MaxPressure : c.int32_t,

		Dll : win32.HINSTANCE ,

		// Dove: not used

		// HCTX         	 Context,
		// WTINFOA           WTInfoA,
		// WTOPENA           WTOpenA,
		// WTGETA            WTGetA,
		// WTSETA            WTSetA,
		// WTCLOSE           WTClose,
		// WTPACKET          WTPacket,
		// WTENABLE          WTEnable,
		// WTOVERLAP         WTOverlap,
		// WTSAVE            WTSave,
		// WTCONFIG          WTConfig,
		// WTRESTORE         WTRestore,
		// WTEXTSET          WTExtSet,
		// WTEXTGET          WTExtGet,
		// WTQUEUESIZESET    WTQueueSizeSet,
		// WTDATAPEEK        WTDataPeek,
		// WTPACKETSGET      WTPacketsGet,
		// WTMGROPEN         WTMgrOpen,
		// WTMGRCLOSE        WTMgrClose,
		// WTMGRDEFCONTEXT   WTMgrDefContext,
		// WTMGRDEFCONTEXTEX WTMgrDefContextEx,
	}

	@(default_calling_convention = "c")
	@(link_prefix = "EasyTab_")
	foreign etb {
		@(link_name = "EasyTab")
		EasyTab : ^EasyTabInfo
		Load :: proc(wnd: win32.HWND) -> Result ---
		Load_Ex :: proc(wnd: win32.HWND,
						mode: TrackingMode,
						relativeModeSensitivity : c.float,
						moveCursor : c.int32_t) -> Result ---
		Unload :: proc() ---
		HandleEvent :: proc(wnd: win32.HWND, msg: c.uint, lp: win32.LPARAM, wp: win32.WPARAM) -> Result ---
	}
	
}
