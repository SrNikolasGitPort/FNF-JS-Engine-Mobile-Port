package debug.mem;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class MemBuild
{
	/**
	 * Adds `@:buildXml` with the ABSOLUTE path of build.xml. The old relative path (../../../../source/...) only
	 * matched the Android/desktop output folders and broke the iOS build, whose C++ build runs deeper.
	 */
	public static function build():Array<Field>
	{
		final dir = haxe.io.Path.directory(sys.FileSystem.absolutePath(Context.resolvePath('debug/mem/build.xml'))).split('\\').join('/');
		Context.getLocalClass().get().meta.add(':buildXml', [macro $v{'<include name="' + dir + '/build.xml" />'}], Context.currentPos());
		return null;
	}
}
#end
