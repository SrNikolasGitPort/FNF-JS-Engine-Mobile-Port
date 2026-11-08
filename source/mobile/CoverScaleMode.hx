package mobile;

import flixel.system.scaleModes.BaseScaleMode;

/**
 * "Full Screen": the game keeps its proportions (nothing is stretched) and is scaled until it covers the whole
 * display, so there are no black bars. On a phone wider than 16:9 a thin strip at the top and bottom
 * falls outside the screen; the touch buttons are laid out inside the visible part (see `MobileControls.computeView`).
 */
class CoverScaleMode extends BaseScaleMode
{
	override function updateGameSize(Width:Int, Height:Int):Void
	{
		final scale = Math.max(Width / FlxG.width, Height / FlxG.height);
		gameSize.x = Math.ceil(FlxG.width * scale);
		gameSize.y = Math.ceil(FlxG.height * scale);
	}
}
