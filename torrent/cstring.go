package main

/*
#include <stdlib.h>
*/
import "C"
import "unsafe"

//export FreeCString
func FreeCString(s *C.char) {
	C.free(unsafe.Pointer(s))
}
