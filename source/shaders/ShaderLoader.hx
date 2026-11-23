package shaders;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/**
 * Finds and prepares runtime shaders (.frag and/or .vert) for both Lua and Haxe scripts.
 *
 * - looks in the mods folders (current mod, global mods, root `mods/shaders`) and then in `assets/shaders`
 * - a shader may have only a .frag, only a .vert, or both
 * - the source is adapted to phones (OpenGL ES): `#version` lines are dropped (they make GLES refuse the shader)
 *   and a fragment shader without a precision statement gets `precision mediump float;`
 */
class ShaderLoader
{
	/** `[fragment, vertex]` (either can be null) or null when nothing was found. */
	public static function load(name:String):Null<Array<String>>
	{
		#if (sys && SHADERS_ALLOWED)
		final folders:Array<String> = [Paths.mods('shaders/')];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			folders.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));
		for (mod in Mods.getGlobalMods())
			folders.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in folders)
		{
			if (!FileSystem.exists(folder))
				continue;
			final found = read(folder + name + '.frag', folder + name + '.vert');
			if (found != null)
				return found;
		}

		// the game's own shaders (assets/shaders), same behaviour on every platform
		final base = Paths.getPath('shaders/$name', TEXT);
		return read(base + '.frag', base + '.vert');
		#else
		return null;
		#end
	}

	#if sys
	static function read(fragPath:String, vertPath:String):Null<Array<String>>
	{
		var frag:String = null;
		var vert:String = null;
		try
		{
			if (FileSystem.exists(fragPath))
				frag = adapt(File.getContent(fragPath), true);
			if (FileSystem.exists(vertPath))
				vert = adapt(File.getContent(vertPath), false);
		}
		catch (e:Dynamic)
		{
			trace('Could not read shader $fragPath / $vertPath: $e');
		}
		return (frag == null && vert == null) ? null : [frag, vert];
	}
	#end

	/** Makes a desktop shader acceptable to OpenGL ES. Harmless on desktop. */
	public static function adapt(source:String, isFragment:Bool):String
	{
		#if mobile
		source = source.replace('\r\n', '\n');
		final lines = source.split('\n');
		final out:Array<String> = [];
		var hasPrecision = false;
		var usesHeader = false;
		for (line in lines)
		{
			final t = line.trim();
			if (t.startsWith('#version'))
				continue; // GLES picks the version itself
			if (t.startsWith('#pragma header'))
				usesHeader = true; // the engine's header already declares the precision
			if (t.startsWith('precision '))
				hasPrecision = true;
			out.push(line);
		}
		source = out.join('\n');
		if (isFragment && !hasPrecision && !usesHeader)
			source = '#ifdef GL_ES\nprecision mediump float;\n#endif\n' + source;
		return source;
		#else
		return source;
		#end
	}
}
