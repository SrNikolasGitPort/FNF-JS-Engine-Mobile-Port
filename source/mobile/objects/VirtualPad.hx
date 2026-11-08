package mobile.objects;

import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import mobile.MobileControls;
import mobile.MobileInput;

enum PadMode
{
	/** no pad at all */
	NONE;

	/** D-pad + A + B (the default for menus) */
	FULL;

	/** D-pad + A + B + X + Y + C, no captions (generic) */
	FULL_EXTRA;

	/** only A and B */
	AB;

	/** only A */
	A_ONLY;

	/** only the D-pad */
	DPAD;

	/** main menu: up/down + A + B + the "Editors" button */
	MAIN;

	/** story mode: D-pad + A + B + X (Changers) + Y (Reset) */
	STORY;

	/** freeplay: D-pad + A + B + X (Changers) + Y (Reset) + C (Listen) */
	FREEPLAY;

	/** lists that only scroll vertically (credits...): up/down + A + B */
	LIST;

	/** D-pad + A + B + Y (Reset): options, achievements... */
	RESETTABLE;
}

/** What a pad shows. `null` = not shown, a string = caption ('' for none). dpad: 0 none, 1 full, 2 up/down only, 3 left/right only */
typedef PadConfig =
{
	var dpad:Int;
	var a:Null<String>;
	var b:Null<String>;
	var x:Null<String>;
	var y:Null<String>;
	var c:Null<String>;
	var editors:Bool;
}

/**
 * On-screen D-pad and face buttons for menus.
 *
 * Layout is in game coordinates (1280x720). Because everything is drawn on its own camera, the pad
 * stays on top of every state and substate and is not affected by their camera effects.
 */
class VirtualPad extends FlxTypedGroup<TouchButton>
{
	public var mode(default, null):PadMode;

	public var buttonUp:TouchButton;
	public var buttonDown:TouchButton;
	public var buttonLeft:TouchButton;
	public var buttonRight:TouchButton;
	public var buttonA:TouchButton;
	public var buttonB:TouchButton;
	public var buttonX:TouchButton;
	public var buttonY:TouchButton;
	public var buttonC:TouchButton;

	public static function configFor(mode:PadMode):PadConfig
	{
		return switch (mode)
		{
			case NONE: {dpad: 0, a: null, b: null, x: null, y: null, c: null, editors: false};
			case FULL: {dpad: 1, a: 'OK', b: 'Back', x: null, y: null, c: null, editors: false};
			case FULL_EXTRA: {dpad: 1, a: 'OK', b: 'Back', x: '', y: '', c: '', editors: false};
			case AB: {dpad: 0, a: 'OK', b: 'Back', x: null, y: null, c: null, editors: false};
			case A_ONLY: {dpad: 0, a: 'OK', b: null, x: null, y: null, c: null, editors: false};
			case DPAD: {dpad: 1, a: null, b: null, x: null, y: null, c: null, editors: false};
			case MAIN: {dpad: 2, a: 'OK', b: 'Back', x: null, y: null, c: null, editors: true};
			case STORY: {dpad: 1, a: 'Play', b: 'Back', x: 'Changers', y: 'Reset', c: null, editors: false};
			case FREEPLAY: {dpad: 1, a: 'Play', b: 'Back', x: 'Changers', y: 'Reset', c: 'Listen', editors: false};
			case LIST: {dpad: 2, a: 'OK', b: 'Back', x: null, y: null, c: null, editors: false};
			case RESETTABLE: {dpad: 1, a: 'OK', b: 'Back', x: null, y: 'Reset', c: null, editors: false};
		}
	}

	public function new(mode:PadMode, alpha:Float)
	{
		super();
		this.mode = mode;
		final cfg = configFor(mode);

		final S = 108; // d-pad button size
		final cx = 20 + S * 1.5; // d-pad centre x
		final cy = MobileControls.viewH - 20 - S * 1.5; // d-pad centre y

		if (cfg.dpad == 1 || cfg.dpad == 2)
		{
			buttonUp = make(cx - S * .5, cy - S * 1.5, UP, MobileGraphics.arrowButton(S, 0));
			buttonDown = make(cx - S * .5, cy + S * .5, DOWN, MobileGraphics.arrowButton(S, 1));
		}
		if (cfg.dpad == 1 || cfg.dpad == 3)
		{
			buttonLeft = make(cx - S * 1.5, cy - S * .5, LEFT, MobileGraphics.arrowButton(S, 2));
			buttonRight = make(cx + S * .5, cy - S * .5, RIGHT, MobileGraphics.arrowButton(S, 3));
		}

		final R = 128; // face button size
		final rx = MobileControls.viewW - 20 - R;
		final ry = MobileControls.viewH - 20 - R;
		if (cfg.a != null)
			buttonA = face(rx, ry - 20, A, 'A', 0xFF2EA043, cfg.a);
		if (cfg.b != null)
			buttonB = face(rx - R - 12, ry + 20, B, 'B', 0xFFD73A49, cfg.b);
		if (cfg.x != null)
			buttonX = face(rx - R - 12, ry - R - 4, X, 'X', 0xFF2F81F7, cfg.x);
		if (cfg.y != null)
			buttonY = face(rx, ry - R - 44, Y, 'Y', 0xFFD29922, cfg.y);
		if (cfg.c != null)
			buttonC = face(rx - R * 2 - 24, ry + 20, C, 'C', 0xFF8957E5, cfg.c);

		if (cfg.editors)
		{
			// custom wide button that opens the editors (replaces the old unlabeled "X")
			buttonX = new TouchButton(MobileControls.viewW - 20 - 250, ry - R - 70, X, MobileGraphics.pill(250, 84, 0xFF8957E5));
			buttonX.hitPadding = 8;
			buttonX.setLabel('Editors', 30);
			add(buttonX);
		}

		setAlpha(alpha);
	}

	function face(x:Float, y:Float, id:MobileButtonID, letter:String, color:Int, caption:String):TouchButton
	{
		final button = make(x, y, id, MobileGraphics.letterButton(128, letter, color));
		button.setLabel(caption, 20, true);
		return button;
	}

	function make(x:Float, y:Float, id:MobileButtonID, graphic:flixel.graphics.FlxGraphic):TouchButton
	{
		final button = new TouchButton(x, y, id, graphic);
		button.hitPadding = 8; // fingers are bigger than the drawn button
		add(button);
		return button;
	}

	public function setAlpha(value:Float):Void
	{
		for (button in members)
			if (button != null)
				button.setIdleAlpha(value);
	}

	/** Shows/hides the pad and keeps `MobileInput` from reading touches on a hidden pad. */
	public function setActive(value:Bool):Void
	{
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
