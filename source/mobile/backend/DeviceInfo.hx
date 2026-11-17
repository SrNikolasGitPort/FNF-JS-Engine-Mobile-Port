package mobile.backend;

/** Small facts about the phone that the memory / performance defaults depend on. */
class DeviceInfo
{
	/** true on a 32-bit build (armv7): only ~2-3 GB of address space, so big songs / stages can run out of memory. */
	public static var is32Bit(get, never):Bool;

	static var _bits:Int = 0;

	static function get_is32Bit():Bool
	{
		if (_bits == 0)
		{
			#if cpp
			_bits = untyped __cpp__('(int)(sizeof(void*) * 8)');
			#else
			_bits = 64;
			#end
		}
		return _bits == 32;
	}
}
