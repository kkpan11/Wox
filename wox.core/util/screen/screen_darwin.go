package screen

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa

typedef struct {
    int width;
    int height;
    int x;
    int y;
} ScreenInfo;

ScreenInfo getMouseScreenSize();
ScreenInfo getActiveScreenSize();
*/
import "C"

func GetMouseScreen() Size {
	screenInfo := C.getMouseScreenSize()
	return Size{
		Width:  int(screenInfo.width),
		Height: int(screenInfo.height),
		X:      int(screenInfo.x),
		Y:      int(screenInfo.y),
	}
}

func GetActiveScreen() Size {
	screenInfo := C.getActiveScreenSize()
	return Size{
		Width:  int(screenInfo.width),
		Height: int(screenInfo.height),
		X:      int(screenInfo.x),
		Y:      int(screenInfo.y),
	}
}
