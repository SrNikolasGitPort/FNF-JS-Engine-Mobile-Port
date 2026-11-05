package mobile.objects;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

/**
 * Small framed picture of the hitbox for the Mobile Options menu.
 *
 * It sits in a corner instead of covering the whole menu, so the options stay readable
 * while the lanes still show the colors, style, opacity and position being edited.
 * It is only a picture: it does not register with `MobileInput`.
 */
class HitboxPreview extends FlxGroup
{
	public function new(x:Float, y:Float, w:Int, h:Int, alpha:Float, style:Int, bottomOnly:Bool, hideHints:Bool, extra:Bool)
	{
		super();
		final colors = [0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F];

		final frame = new FlxSprite(x - 4, y - 4).makeGraphic(w + 8, h + 8, 0xFFFFFFFF);
		frame.alpha = 0.85;
		add(frame);
		final back = new FlxSprite(x, y).makeGraphic(w, h, 0xFF15151C);
		add(back);

		final laneW = Std.int(w / 4);
		final laneH = bottomOnly ? Std.int(h * 0.62) : h;
		for (i in 0...4)
		{
			final lane = new FlxSprite(x + i * laneW, y + h - laneH, MobileGraphics.hitboxLane(laneW, laneH, colors[i], style));
			lane.alpha = hideHints ? 0 : Math.max(alpha, 0.12);
			lane.antialiasing = false;
			add(lane);
		}

		if (extra)
			add(new FlxSprite(x + 4, y + 4, MobileGraphics.letterButton(28, 'E', 0xFFD29922)));
		add(new FlxSprite(x + w - 32, y + 4, MobileGraphics.pauseButton(28)));

		final caption = new FlxText(x, y + h + 8, w, hideHints ? 'Preview (hints hidden)' : 'Preview', 16);
		caption.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		add(caption);
	}

	public function assignCamera(camera:flixel.FlxCamera):Void
	{
		cameras = [camera];
		for (member in members)
			if (member != null)
				member.cameras = [camera];
	}
}
