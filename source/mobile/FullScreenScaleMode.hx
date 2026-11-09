package mobile;

import flixel.FlxCamera;
import flixel.system.scaleModes.RatioScaleMode;

/**
 * "Full Screen": the normal 16:9 picture (same layout, same HUD, nothing zoomed or stretched) without black bars.
 *
 * The game keeps its 1280x720 coordinates, so the HUD, strums and menus sit exactly where they do in Ratio mode.
 * What changes is that the world camera of a song (`extend`) and a copy of each menu background (`BarBackdrop`)
 * are drawn over the area where the black bars would be.
 */
class FullScreenScaleMode extends RatioScaleMode
{
	/** Extra width / height (game pixels) on each side of the 1280x720 picture, 0 when it already fills the display. */
	public static var padX(default, null):Int = 0;
	public static var padY(default, null):Int = 0;

	static final cams:Array<FlxCamera> = [];
	static final doneX:Array<Int> = [];
	static final doneY:Array<Int> = [];

	public static var active(get, never):Bool;

	static inline function get_active():Bool
		return Std.isOfType(FlxG.scaleMode, FullScreenScaleMode);

	override function onMeasure(Width:Int, Height:Int):Void
	{
		super.onMeasure(Width, Height);
		padX = Std.int(Math.max(0, Math.ceil((Width / scale.x - FlxG.width) / 2)));
		padY = Std.int(Math.max(0, Math.ceil((Height / scale.y - FlxG.height) / 2)));
		refresh();
	}

	/** The mode was replaced by another one: give every camera its normal size back. */
	public static function deactivate():Void
	{
		padX = padY = 0;
		refresh();
	}

	/** Makes `cam` (a world camera that fills the whole game) cover the area of the black bars too. */
	public static function extend(cam:FlxCamera):Void
	{
		if (cam == null || cams.contains(cam))
			return;
		cams.push(cam);
		doneX.push(0);
		doneY.push(0);
		refresh();
	}

	static function refresh():Void
	{
		var i = cams.length;
		while (i-- > 0)
		{
			final cam = cams[i];
			if (cam == null || !cam.exists || !FlxG.cameras.list.contains(cam))
			{
				cams.splice(i, 1);
				doneX.splice(i, 1);
				doneY.splice(i, 1);
				continue;
			}
			cam.x = -padX;
			cam.y = -padY;
			cam.width = FlxG.width + padX * 2;
			cam.height = FlxG.height + padY * 2;
			// a camera that is not following something keeps showing the same part of the world
			cam.scroll.x += doneX[i] - padX;
			cam.scroll.y += doneY[i] - padY;
			doneX[i] = padX;
			doneY[i] = padY;
		}
	}
}
