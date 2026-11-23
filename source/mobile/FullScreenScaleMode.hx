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
@:access(flixel.FlxCamera)
class FullScreenScaleMode extends RatioScaleMode
{
	/** Extra width / height (game pixels) on each side of the 1280x720 picture, 0 when it already fills the display. */
	public static var padX(default, null):Int = 0;
	public static var padY(default, null):Int = 0;

	static final cams:Array<FlxCamera> = [];
	/** Cameras that must keep their own clipping (the touch controls, the side bars, the menu backdrop). */
	static final keep:Array<FlxCamera> = [];
	static var hooked:Bool = false;
	static final applied:haxe.ds.ObjectMap<FlxCamera, Array<Float>> = new haxe.ds.ObjectMap();
	static final doneX:Array<Int> = [];
	static final doneY:Array<Int> = [];

	public static var active(get, never):Bool;

	static inline function get_active():Bool
		return Std.isOfType(FlxG.scaleMode, FullScreenScaleMode);

	override function onMeasure(Width:Int, Height:Int):Void
	{
		super.onMeasure(Width, Height);
		if (!hooked)
		{
			hooked = true;
			FlxG.signals.preDraw.add(unclipAll);
		}
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

	/** The camera keeps cropping its picture to its own rectangle (used by the touch controls). */
	public static function protect(cam:FlxCamera):Void
	{
		var i = keep.length;
		while (i-- > 0) // forget cameras that are gone, so the list (searched every frame) stays tiny
			if (keep[i] == null || !keep[i].exists)
				keep.splice(i, 1);
		if (cam != null && !keep.contains(cam))
			keep.push(cam);
	}

	/**
	 * No invisible border: every camera crops what it draws to its 1280x720 rectangle, which is what cut
	 * notes, icons and menu art at the edge of the picture. Before each draw the crop is widened by the
	 * side padding on every side (positions and sizes are untouched), so whatever is drawn near the edge
	 * simply continues into the area where the black bars would be.
	 * It is set from the camera size each time (not added to), so it is safe to repeat and to undo (pad 0).
	 */
	static function unclipAll():Void
	{
		for (cam in FlxG.cameras.list)
		{
			if (cam == null || !cam.exists || keep.contains(cam) || cams.contains(cam))
				continue;
			// flixel resets the crop whenever the size, zoom or scale changes: only look when one of those did
			var sig = applied.get(cam);
			if (sig == null)
				applied.set(cam, sig = [-1.0, 0, 0, 0, 0, 0, 0, 0]);
			final sx = FlxG.scaleMode.scale.x;
			final sy = FlxG.scaleMode.scale.y;
			final same = sig[0] == padX && sig[1] == padY && sig[2] == sx && sig[3] == sy && sig[4] == cam.zoom && sig[5] == cam.width
				&& sig[6] == cam.height && sig[7] == cam.initialZoom;
			if (same)
				continue;
			sig[0] = padX;
			sig[1] = padY;
			sig[2] = sx;
			sig[3] = sy;
			sig[4] = cam.zoom;
			sig[5] = cam.width;
			sig[6] = cam.height;
			sig[7] = cam.initialZoom;
			final holder = cam._scrollRect;
			if (holder == null)
				continue;
			final rect = holder.scrollRect;
			if (rect == null || cam.width <= 0 || cam.height <= 0)
				continue;
			final baseW = cam.width * cam.initialZoom * FlxG.scaleMode.scale.x;
			final baseH = cam.height * cam.initialZoom * FlxG.scaleMode.scale.y;
			final ex = baseW * padX / cam.width;
			final ey = baseH * padY / cam.height;
			final hx = -0.5 * baseW - ex;
			final hy = -0.5 * baseH - ey;
			if (rect.x == -ex && rect.y == -ey && rect.width == baseW + ex * 2 && rect.height == baseH + ey * 2 && holder.x == hx && holder.y == hy)
				continue;
			rect.x = -ex;
			rect.y = -ey;
			rect.width = baseW + ex * 2;
			rect.height = baseH + ey * 2;
			// the crop rectangle also scrolls what is inside it: move the holder back by the same amount,
			// otherwise the whole picture (HUD, strums) is pushed to the right/down by the padding
			holder.x = hx;
			holder.y = hy;
			holder.scrollRect = rect;
		}
	}
}
