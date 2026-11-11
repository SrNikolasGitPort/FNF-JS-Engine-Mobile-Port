package mobile.objects;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import mobile.FullScreenScaleMode;

/**
 * Full Screen: fills the area next to a menu with a darkened, enlarged copy of the menu's own background,
 * so there are no black bars while every menu element stays exactly where it is in Ratio mode.
 */
class BarBackdrop extends FlxSprite
{
	var source:FlxSprite;

	function new(source:FlxSprite, w:Int, h:Int)
	{
		super();
		this.source = source;
		frames = source.frames;
		scrollFactor.set();
		antialiasing = source.antialiasing;
		final s = Math.max(w / Math.max(1, source.frameWidth), h / Math.max(1, source.frameHeight));
		scale.set(s, s);
		updateHitbox();
		setPosition((w - width) / 2, (h - height) / 2);
	}

	override function draw():Void
	{
		if (source == null || !source.exists)
			return;
		frame = source.frame;
		color = FlxColor.interpolate(source.color, FlxColor.BLACK, 0.45);
		alpha = source.alpha;
		super.draw();
	}

	/** Called for every state that is not a song. */
	public static function attach(state:FlxState):Void
	{
		clear(state);
		final px = FullScreenScaleMode.padX;
		final py = FullScreenScaleMode.padY;
		if (!FullScreenScaleMode.active || (px <= 0 && py <= 0))
			return;
		final bg = findBackground(state);
		if (bg == null)
			return;

		final w = FlxG.width + px * 2;
		final h = FlxG.height + py * 2;
		final cam = new FlxCamera(-px, -py, w, h);
		cam.bgColor = FlxColor.BLACK;
		FlxG.cameras.add(cam, false);
		FlxG.cameras.list.remove(cam);
		FlxG.cameras.list.unshift(cam); // keeps `cameras.list[last]` pointing at the state's own camera
		FlxG.game.setChildIndex(cam.flashSprite, 0); // drawn under everything

		final copy = new BarBackdrop(bg, w, h);
		copy.cameras = [cam];
		state.insert(0, copy);
		current = copy;
		currentCam = cam;
	}

	static var current:BarBackdrop;
	static var currentCam:FlxCamera;

	/** The Screen option can change while a menu is open: drop the old backdrop before (maybe) making a new one. */
	static function clear(state:FlxState):Void
	{
		if (current != null)
		{
			state.remove(current, true);
			current.destroy();
		}
		if (currentCam != null && FlxG.cameras.list.contains(currentCam))
			FlxG.cameras.remove(currentCam, true);
		current = null;
		currentCam = null;
	}

	static function findBackground(state:FlxState):Null<FlxSprite>
	{
		for (member in state.members)
		{
			final spr:FlxSprite = Std.isOfType(member, FlxSprite) ? cast member : null;
			if (spr != null && spr.exists && spr.visible && spr.frames != null && spr.camera == FlxG.camera
				&& Math.abs(spr.frameWidth * spr.scale.x) >= FlxG.width * 0.9 && Math.abs(spr.frameHeight * spr.scale.y) >= FlxG.height * 0.9)
				return spr;
		}
		return null;
	}

	/**
	 * Songs: sprites of the stage with scroll factor 0 are drawn relative to the (wider) camera, so they are moved
	 * by the same amount and a full-screen one is enlarged to cover the extra area.
	 */
	public static function fixFixedSprites(state:FlxState, cam:FlxCamera):Void
	{
		final px = FullScreenScaleMode.padX;
		final py = FullScreenScaleMode.padY;
		if (!FullScreenScaleMode.active || (px <= 0 && py <= 0))
			return;
		walk(state, cam, px, py, true);
	}

	/**
	 * `onCam`: whether the objects of this group are drawn on `cam`. A group (or a sprite) that has its own `cameras`
	 * decides for itself (the strums, health bar etc. are put on the HUD camera through their group, so they must be
	 * left alone); everything else uses the default camera, which is the world camera in a song.
	 */
	static function walk(group:FlxGroup, cam:FlxCamera, px:Int, py:Int, onCam:Bool):Void
	{
		for (member in group.members)
		{
			if (member == null)
				continue;
			if (Std.isOfType(member, FlxGroup))
			{
				final g:FlxGroup = cast member;
				final own = g.cameras != null && g.cameras.length > 0;
				walk(g, cam, px, py, own ? g.cameras.contains(cam) : onCam);
				continue;
			}
			final spr:FlxSprite = Std.isOfType(member, FlxSprite) ? cast member : null;
			if (spr == null)
				continue;
			final own = spr.cameras != null && spr.cameras.length > 0;
			if (!(own ? spr.cameras.contains(cam) : onCam))
				continue;
			if (spr.scrollFactor.x == 0 && spr.frames != null && Math.abs(spr.frameWidth * spr.scale.x) >= FlxG.width * 0.9)
			{
				final k = Math.max((FlxG.width + px * 2) / FlxG.width, (FlxG.height + py * 2) / FlxG.height);
				spr.scale.set(spr.scale.x * k, spr.scale.y * k); // grows around its centre, no updateHitbox
			}
			if (spr.scrollFactor.x == 0)
				spr.x += px;
			if (spr.scrollFactor.y == 0)
				spr.y += py;
		}
	}
}
