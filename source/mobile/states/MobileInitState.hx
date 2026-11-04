package mobile.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import mobile.backend.AssetExtractor;
import mobile.backend.StorageUtil;

/**
 * First state on phones. Copies the game files out of the APK when needed (first launch / new build),
 * shows progress, then hands over to the normal `InitState`.
 *
 * It only uses code-drawn graphics and flixel's built-in font, since the assets it is preparing
 * are not available as files yet.
 */
class MobileInitState extends FlxState
{
	var extractor:AssetExtractor;
	var bar:FlxSprite;
	var barBack:FlxSprite;
	var title:FlxText;
	var info:FlxText;
	var skipFrames:Int = 2; // let one frame draw before the heavy work starts
	var waitingForAccess:Bool = false;
	var accessTimer:Float = 0;
	var asked:Bool = false;

	override function create():Void
	{
		super.create();
		FlxG.autoPause = false;
		bgColor = 0xFF101018;

		waitingForAccess = !StorageUtil.hasAccess();
		if (!waitingForAccess)
			StorageUtil.setup(true);

		if (!waitingForAccess && !AssetExtractor.needed())
		{
			FlxG.switchState(() -> new InitState());
			return;
		}

		if (!waitingForAccess)
			extractor = new AssetExtractor();

		title = new FlxText(0, 250, FlxG.width, waitingForAccess ? "Storage access needed" : "Preparing game files", 40);
		title.alignment = CENTER;
		add(title);

		info = new FlxText(60, 480, FlxG.width - 120, waitingForAccess ? "The game keeps its files in the\n.JSEMobile folder (assets and mods).\nAllow access to files, then come back.\n\nTap the screen to open the permission screen again." : "This only happens the first time\n(and after an update).", 24);
		info.alignment = CENTER;
		info.color = 0xFFAAAAAA;
		add(info);

		barBack = new FlxSprite((FlxG.width - 760) / 2, 400).makeGraphic(760, 28, 0xFF2A2A38);
		add(barBack);
		bar = new FlxSprite(barBack.x, barBack.y).makeGraphic(760, 28, 0xFF5CE08A);
		bar.origin.set(0, 0);
		bar.scale.x = 0;
		add(bar);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (waitingForAccess)
		{
			accessTimer += elapsed;
			if (!asked && accessTimer > 0.5)
			{
				asked = true;
				StorageUtil.requestAccess();
			}
			else if (FlxG.mouse.justPressed || FlxG.touches.justStarted().length > 0)
				StorageUtil.requestAccess();

			if (asked && accessTimer > 1 && StorageUtil.hasAccess())
			{
				waitingForAccess = false;
				StorageUtil.setup(true);
				if (!AssetExtractor.needed())
				{
					FlxG.switchState(() -> new InitState());
					return;
				}
				extractor = new AssetExtractor();
				title.text = "Preparing game files";
				info.text = "This only happens the first time\n(and after an update).";
			}
			return;
		}

		if (extractor == null)
			return;

		if (skipFrames > 0)
		{
			skipFrames--;
			return;
		}

		extractor.step();

		final progress = extractor.total == 0 ? 1.0 : extractor.done / extractor.total;
		bar.scale.x = progress;
		title.text = 'Preparing game files  ${Std.int(progress * 100)}%';

		if (extractor.error != null)
		{
			title.text = "Something went wrong";
			title.color = FlxColor.RED;
			info.text = extractor.error;
			info.color = FlxColor.WHITE;
			extractor = null;
		}
		else if (extractor.finished)
		{
			extractor = null;
			FlxG.switchState(() -> new InitState());
		}
	}
}
