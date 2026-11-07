package mobile.objects;

import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import mobile.MobileInput;

/**
 * Gameplay controls: four tall lanes that behave like the four arrow keys.
 *
 * Lanes are plain touch areas, so you can slide from lane to lane, hold sustains with one finger
 * and use all four lanes at once. A small pause button sits in the top-right corner and is
 * "exclusive", so tapping it never hits a note.
 */
class Hitbox extends FlxTypedGroup<TouchButton>
{
	/** Lane colours, left to right: purple, blue, green, red (same order as the note directions). */
	static final COLORS:Array<Int> = [0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F];

	/** Narrowest black bar (game pixels) that can hold the pause button. */
	public static inline var SIDE_MIN:Int = 110;

	public var lanes(default, null):Array<TouchButton> = [];
	public var pauseButton(default, null):TouchButton;
	public var extraButton(default, null):TouchButton;

	/** true while the lanes type keyboard keys (extra-keys scripts), false for the normal four lanes */
	public var keyMode(default, null):Bool = false;

	final laneAlpha:Float;
	final style:Int;
	final bottomOnly:Bool;
	final hideHints:Bool;
	var activeNow:Bool = true;
	var laneKeys:Array<Int> = [];

	/**
	 * @param alpha     idle opacity of the lanes (0 hides them but they keep working)
	 * @param style     0 = gradient, 1 = flat, 2 = outline only
	 * @param bottomOnly true = lanes cover the lower part of the screen only, false = the whole screen
	 * @param extra     adds the Bot Energy button
	 * @param hideHints never draw the lanes (not even when pressed); they keep working
	 */
	public function new(alpha:Float, style:Int, bottomOnly:Bool, extra:Bool, hideHints:Bool = false)
	{
		super();
		this.laneAlpha = alpha;
		this.style = style;
		this.bottomOnly = bottomOnly;
		this.hideHints = hideHints;

		buildLanes(null);

		pauseButton = new TouchButton(FlxG.width - 96 - 14, 14, PAUSE, MobileGraphics.pauseButton(96));
		pauseButton.priority = 10;
		pauseButton.exclusive = true;
		pauseButton.hitPadding = 14;
		pauseButton.pressedScale = 0.9;
		pauseButton.setIdleAlpha(0.75);
		add(pauseButton);

		if (extra)
		{
			extraButton = new TouchButton(14, 14, BOT_ENERGY, MobileGraphics.letterButton(96, 'E', 0xFFD29922));
			extraButton.priority = 10;
			extraButton.exclusive = true;
			extraButton.hitPadding = 14;
			extraButton.setIdleAlpha(0.7);
			add(extraButton);
		}
	}

	/**
	 * Matches the number of lanes to the song's key count (extra-keys scripts replace `PlayState.keysArray`).
	 * With four keys the normal lanes are used. With any other count there is one lane per key, and each lane
	 * types the keyboard key of its position, so the engine's own keyboard input path (and the script's
	 * `onKeyPress` / `onKeyRelease`) works exactly as it does on a computer.
	 *
	 * Cheap enough to call every frame: it only compares the keys, and rebuilds when they changed.
	 */
	public function syncLanes(keysArray:Array<Dynamic>):Void
	{
		final count = keysArray.length;
		final wantKeys = count != 4;

		if (!wantKeys)
		{
			if (keyMode)
				buildLanes(null);
			return;
		}

		var same = keyMode && laneKeys.length == count;
		final keys:Array<Int> = [];
		for (i in 0...count)
		{
			final binds:Array<Dynamic> = keysArray[i];
			var key = -1;
			if (binds != null)
				for (k in binds)
					if ((k : Int) > 0)
					{
						key = k;
						break;
					}
			keys.push(key);
			if (same && laneKeys[i] != key)
				same = false;
		}
		if (!same)
			buildLanes(keys);
	}

	function buildLanes(keys:Null<Array<Int>>):Void
	{
		MobileInput.releaseAll(); // a finger held on a lane that is about to disappear must not stay "down"
		for (lane in lanes)
		{
			remove(lane, true);
			lane.destroy();
		}
		lanes = [];
		keyMode = keys != null;
		laneKeys = keyMode ? keys : [];

		final count = keyMode ? keys.length : 4;
		final laneH = bottomOnly ? Std.int(FlxG.height * 0.62) : FlxG.height;
		final top = FlxG.height - laneH;
		final ids:Array<MobileButtonID> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];

		for (i in 0...count)
		{
			final x0 = Math.round(i * FlxG.width / count);
			final x1 = Math.round((i + 1) * FlxG.width / count);
			final color = keyMode ? laneColor(i, count) : COLORS[i];
			final id:Int = keyMode ? MobileInput.allocId() : ids[i];
			final lane = new TouchButton(x0, top, id, MobileGraphics.hitboxLane(x1 - x0, laneH, color, style));
			if (keyMode && keys[i] > 0)
				MobileInput.bindKey(lane, keys[i]);
			lane.pressedScale = 1; // lanes should not shrink, they tile the screen
			lane.pressedAlpha = hideHints ? 0 : Math.min(1, laneAlpha + 0.45);
			lane.setIdleAlpha(hideHints ? 0 : laneAlpha);
			lane.antialiasing = false;
			lane.touchEnabled = activeNow;
			lane.visible = activeNow;
			lane.cameras = cameras;
			lanes.push(lane);
			insert(i, lane); // under the pause / extra buttons
		}
	}

	/** Rainbow across the screen so many narrow lanes stay easy to tell apart. */
	static function laneColor(i:Int, count:Int):Int
		return 0xFFFFFF & flixel.util.FlxColor.fromHSB(300 * i / Math.max(1, count), 0.65, 1);

	/**
	 * Puts the pause button in the right black bar and the Bot Energy button in the left one.
	 * Buttons are 96 px wide, so a bar needs at least `SIDE_MIN` px.
	 */
	public function moveToBars(right:FlxCamera, left:FlxCamera, barWidth:Float):Void
	{
		final x = Math.floor((barWidth - 96) / 2);
		pauseButton.cameras = [right];
		pauseButton.setPosition(x, 14);
		if (extraButton != null)
		{
			extraButton.cameras = [left];
			extraButton.setPosition(x, 14);
		}
	}

	public function setActive(value:Bool):Void
	{
		activeNow = value;
		visible = value;
		active = value;
		for (button in members)
			if (button != null)
			{
				button.touchEnabled = value;
				button.visible = value;
			}
	}

	public function assignCamera(camera:FlxCamera):Void
	{
		cameras = [camera];
		for (button in members)
			if (button != null)
				button.cameras = [camera];
	}
}
