package mobile.backend;

/**
 * The prebuilt 32-bit LuaJIT library calls fseeko64/ftello64, which Android's libc only exports from API 24.
 * This project supports Android 6 (API 23), so the two functions are provided here for the 32-bit build
 * (on 64-bit `off_t` is already 64 bits and the system has them). 32-bit `long` is enough for Lua's io library.
 */
#if (android && cpp)
@:cppFileCode('
#include <stdio.h>
#include <stdint.h>
#include <sys/types.h>

#if defined(__ANDROID_API__) && __ANDROID_API__ < 24 && !defined(__LP64__)
extern "C" {
int fseeko64(FILE* file, off64_t offset, int whence) { return fseek(file, (long)offset, whence); }
off64_t ftello64(FILE* file) { return (off64_t)ftell(file); }
}
#endif
')
@:keep
#end
class AndroidLibcShims
{
	/** Referencing this from startup keeps the class (and the C++ above) in the build. */
	public static function init():Void {}
}
