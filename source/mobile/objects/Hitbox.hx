package mobile.objects;

import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import mobile.MobileControls;
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

	final laneAlpha:Float;
	final style:Int;
	final bottomOnly:Bool;
	final hideHints:Bool;
	var activeNow:Bool = true;

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

		buildLanes();

		pauseButton = new TouchButton(MobileControls.viewW - 96 - 14, 14, PAUSE, MobileGraphics.pauseButton(96));
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

	function buildLanes():Void
	{
		final laneH = bottomOnly ? Std.int(MobileControls.viewH * 0.62) : MobileControls.viewH;
		final top = MobileControls.viewH - laneH;
		final ids:Array<MobileButtonID> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];

		for (i in 0...4)
		{
			final x0 = Math.round(i * MobileControls.viewW / 4);
			final x1 = Math.round((i + 1) * MobileControls.viewW / 4);
			final lane = new TouchButton(x0, top, ids[i], MobileGraphics.hitboxLane(x1 - x0, laneH, COLORS[i], style));
			lane.pressedScale = 1; // lanes should not shrink, they tile the screen
			lane.pressedAlpha = hideHints ? 0 : Math.min(1, laneAlpha + 0.45);
			lane.setIdleAlpha(hideHints ? 0 : laneAlpha);
			lane.antialiasing = false;
			lane.touchEnabled = activeNow;
			lane.visible = activeNow;
			lane.cameras = cameras;
			lanes.push(lane);
			add(lane); // added first, so the pause / extra buttons draw above
		}
	}

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
