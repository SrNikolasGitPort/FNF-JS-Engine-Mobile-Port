package mobile;

import flixel.system.scaleModes.BaseScaleMode;

/**
 * "Full Screen": the normal picture, same proportions, no zoom and no cropping, but without black bars.
 * Instead of leaving bars, the game's logical size is made as wide (or tall) as the display, so what you see is
 * the usual screen with a little more scenery on the sides. HUD and strums stay centered.
 */
@:access(flixel.FlxG)
class FullScreenScaleMode extends BaseScaleMode
{
	static inline final MIN_ASPECT:Float = 1.2;
	static inline final MAX_ASPECT:Float = 2.6;

	override function onMeasure(Width:Int, Height:Int):Void
	{
		final oldW = FlxG.width;
		final oldH = FlxG.height;
		final iw = FlxG.initialWidth;
		final ih = FlxG.initialHeight;
		final aspect = Math.max(MIN_ASPECT, Math.min(MAX_ASPECT, Width / Math.max(1, Height)));

		if (aspect >= iw / ih)
		{
			FlxG.width = Math.round(ih * aspect);
			FlxG.height = ih;
		}
		else
		{
			FlxG.width = iw;
			FlxG.height = Math.round(iw / aspect);
		}

		updateGameSize(Width, Height);
		updateDeviceSize(Width, Height);
		updateScaleOffset();
		updateGamePosition();

		// cameras made for the previous logical size follow the new one
		if (oldW != FlxG.width || oldH != FlxG.height)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null && cam.width == oldW && cam.height == oldH)
				{
					cam.width = FlxG.width;
					cam.height = FlxG.height;
				}
			}
		}
	}

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		final scale = Math.min(Width / FlxG.width, Height / FlxG.height);
		gameSize.x = Math.round(FlxG.width * scale);
		gameSize.y = Math.round(FlxG.height * scale);
	}
}
