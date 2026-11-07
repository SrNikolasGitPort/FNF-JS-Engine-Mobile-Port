package mobile.backend;

import haxe.io.Path;
import sys.FileSystem;

/**
 * Case-insensitive file lookup for Android.
 *
 * Windows (where most mods are made) does not care about upper/lower case in file names, Android does:
 * `images/Bf.png` is not `images/bf.png`. A mod that works on a computer because of that would show missing
 * images, silent scripts or a song that does not start. `resolve` finds the real file when the exact name is not there.
 */
class PathCase
{
	/** directory -> (lower-case name -> real name). Rebuilt after every state switch. */
	static final listings:Map<String, Map<String, String>> = [];
	static var hooked:Bool = false;

	/** Returns `path` if it exists, the same path with the right capitalisation if only that exists, or null. */
	public static function resolve(path:String):Null<String>
	{
		if (FileSystem.exists(path))
			return path;

		if (!hooked)
		{
			hooked = true;
			FlxG.signals.postStateSwitch.add(clear);
		}

		// walk from the start of the mods folder: everything before it is known to exist with exact case
		final root = StorageUtil.directory;
		var current:String;
		var rest:String;
		if (root != '' && StringTools.startsWith(path, root))
		{
			current = root.substr(0, root.length - 1);
			rest = path.substr(root.length);
		}
		else
		{
			current = '';
			rest = path;
		}

		for (part in rest.split('/'))
		{
			if (part == '' || part == '.')
				continue;
			final direct = current == '' ? part : current + '/' + part;
			if (FileSystem.exists(direct))
			{
				current = direct;
				continue;
			}

			final dir = current == '' ? '.' : current;
			var names = listings.get(dir);
			if (names == null)
			{
				names = [];
				if (FileSystem.exists(dir) && FileSystem.isDirectory(dir))
					for (name in FileSystem.readDirectory(dir))
						names.set(name.toLowerCase(), name);
				listings.set(dir, names);
			}

			final real = names.get(part.toLowerCase());
			if (real == null)
				return null;
			current = current == '' ? real : current + '/' + real;
		}
		return current;
	}

	public static function clear():Void
	{
		listings.clear();
	}
}
