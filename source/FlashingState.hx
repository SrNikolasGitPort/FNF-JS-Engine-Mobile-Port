package;

import flixel.effects.FlxFlicker;
import lime.app.Application;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	override function create()
	{
#if mobile
mobilePadMode = AB;
#end
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		MusicBeatState.windowNameSuffix = " - Flashing Lights Warning Screen";

		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		#if mobile
		final accept = 'Tap A to disable them now or go to Options Menu.';
		final ignore = 'Tap B to ignore this message.';
		#else
		final accept = 'Press ENTER to disable them now or go to Options Menu.';
		final ignore = 'Press ESCAPE to ignore this message.';
		#end
		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n\nThis Mod contains some flashing lights!\n\n" + accept + "\n\n" + ignore + "\n\nYou've been warned!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							FlxG.switchState(TitleState.new);
						});
					});
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							FlxG.switchState(TitleState.new);
						}
					});
				}
			}
		}
		super.update(elapsed);
	}
}
