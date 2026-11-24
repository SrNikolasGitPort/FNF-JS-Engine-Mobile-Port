package mobile.backend;

/**
 * hxvlc's iOS libvlc contains an OpenGL ES video view that calls the EGL functions, which iOS does not have
 * (it uses EAGL). The code is never used by the game, but the linker still wants the symbols, so provide
 * empty ones. Without this the iOS link fails with "Undefined symbols ... _eglGetDisplay ...".
 */
#if ios
@:keep
@:cppFileCode('
extern "C" {
void* eglGetDisplay(void* id) { return 0; }
unsigned int eglInitialize(void* d, int* major, int* minor) { return 0; }
unsigned int eglTerminate(void* d) { return 0; }
unsigned int eglChooseConfig(void* d, const int* attribs, void** configs, int size, int* num) { return 0; }
void* eglCreateContext(void* d, void* config, void* share, const int* attribs) { return 0; }
void* eglCreateWindowSurface(void* d, void* config, void* win, const int* attribs) { return 0; }
unsigned int eglDestroyContext(void* d, void* ctx) { return 0; }
unsigned int eglDestroySurface(void* d, void* surf) { return 0; }
void* eglGetCurrentContext() { return 0; }
unsigned int eglMakeCurrent(void* d, void* draw, void* read, void* ctx) { return 0; }
unsigned int eglSwapBuffers(void* d, void* surf) { return 0; }
}
')
class IosStubs
{
	public static function init():Void {}
}
#end
