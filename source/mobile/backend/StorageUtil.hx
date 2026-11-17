package mobile.backend;

import haxe.io.Path;
#if sys
import sys.FileSystem;
#end

/**
 * Where the game keeps its files on a phone: the shared (external) storage, in a hidden folder.
 *
 *   /storage/emulated/0/.JSEMobile/
 *     assets/   the game's assets, copied out of the APK on first launch (see AssetExtractor)
 *     mods/     put your mods here
 *
 * The APK is read-only and its `assets/` cannot be opened with `sys.FileSystem`, which the engine
 * (and every mod) uses everywhere, so the game works from this normal folder instead.
 *
 * Reaching the shared storage needs the storage permission: "All files access" on Android 11+,
 * the classic read/write permission on Android 6 to 10. `MobileInitState` asks for it.
 * If the phone has no usable shared storage at all, the app's own external folder is used.
 */
class StorageUtil
{
	public static inline var FOLDER_NAME:String = '.JSEMobile';

	public static var directory(default, null):String = '';

	/** Call first thing at startup, before anything touches the file system. */
	public static function init():Void
	{
		#if android
		// until the permission is granted the app's own folder is the working directory (crash logs etc.)
		setup(hasAccess());
		#end
	}

	/** true when the shared storage can be written */
	public static function hasAccess():Bool
	{
		#if android
		try
		{
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R)
				return android.os.Environment.isExternalStorageManager();
			return android.Permissions.getGrantedPermissions().contains('android.permission.WRITE_EXTERNAL_STORAGE');
		}
		catch (e) {}
		return false;
		#else
		return true;
		#end
	}

	/** Shows the system screen / dialog where the user grants storage access. */
	public static function requestAccess():Void
	{
		#if android
		try
		{
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R)
				android.Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
			else
				android.Permissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
		}
		catch (e) {}
		#end
	}

	/** Picks the game folder (shared storage when `shared`), creates it and makes it the working directory. */
	public static function setup(shared:Bool):Void
	{
		#if android
		directory = '';
		if (shared)
		{
			try
			{
				final root = android.os.Environment.getExternalStorageDirectory();
				if (root != null && root != '')
				{
					final dir = Path.addTrailingSlash(Path.addTrailingSlash(root) + FOLDER_NAME);
					if (!FileSystem.exists(dir))
						FileSystem.createDirectory(dir);
					if (FileSystem.isDirectory(dir))
						directory = dir;
				}
			}
			catch (e) {}
		}
		if (directory == '')
			directory = fallback();

		for (folder in [directory, directory + 'mods', directory + 'crash'])
			if (!FileSystem.exists(folder))
				try FileSystem.createDirectory(folder) catch (e) {}
		try Sys.setCwd(directory) catch (e) {}
		#end
	}

	#if android
	static function fallback():String
	{
		var dir:String = null;
		try
		{
			dir = android.content.Context.getExternalFilesDir(null);
		}
		catch (e) {}

		if (dir == null || dir == '')
		{
			try
			{
				dir = android.content.Context.getFilesDir();
			}
			catch (e) {}
		}
		if (dir == null || dir == '')
			dir = lime.system.System.applicationStorageDirectory;

		return Path.addTrailingSlash(dir);
	}
	#end
}
