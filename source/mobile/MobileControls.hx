package mobile;

import flixel.FlxCamera;
import flixel.FlxState;
import flixel.util.FlxColor;
import mobile.MobileInput;
import mobile.objects.Hitbox;
import mobile.objects.KeyPad;
import mobile.objects.VirtualPad;

/**
 * Owns the touch controls of the current state: one transparent camera that is drawn above
 * everything, a `VirtualPad` for menus and (in songs) a `Hitbox`.
 *
 * Which of the two is shown is decided every frame:
 *  - a state without a hitbox always shows the pad;
 *  - a state with a hitbox shows the hitbox while playing, and swaps to the pad while any substate
 *    (pause menu, game over, options...) or a cutscene is on screen.
 */
@:access(flixel.FlxGame)
class MobileControls
{
	/** Controls of the state that is on screen right now (null on non-touch builds or before the first state). */
	public static var instance(default, null):MobileControls;

	public var camera(default, null):FlxCamera;
	public var pad(default, null):VirtualPad;
	public var hitbox(default, null):Hitbox;
	public var keypad(default, null):KeyPad;

	/**
	 * Cameras over the black bars next to the game (Screen: Ratio on a phone wider than 16:9), or null when there are none.
	 * The pause button lives in the right one, the Bot Energy button in the left one.
	 */
	public var rightBar(default, null):FlxCamera;
	public var leftBar(default, null):FlxCamera;

	/** Set by gameplay while a cutscene / dialogue is running: shows the pad instead of the hitbox. */
	public var cutsceneMode:Bool = false;

	var state:FlxState;
	var lastShowPad:Null<Bool> = null;

	/** Applies the "Screen" option: keep 16:9 with black bars (Ratio) or stretch to the whole display (Fill). */
	public static function applyScaleMode():Void
	{
		if (ClientPrefs.mobileScaleMode == 'Fill') // old name of "Stretched"
			ClientPrefs.mobileScaleMode = 'Stretched';

		switch (ClientPrefs.mobileScaleMode)
		{
			case 'Stretched':
				if (!Std.isOfType(FlxG.scaleMode, flixel.system.scaleModes.FillScaleMode))
					FlxG.scaleMode = new flixel.system.scaleModes.FillScaleMode();
			case 'Full Screen':
				if (!Std.isOfType(FlxG.scaleMode, CoverScaleMode))
					FlxG.scaleMode = new CoverScaleMode();
			default:
				if (!Std.isOfType(FlxG.scaleMode, flixel.system.scaleModes.RatioScaleMode))
					FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode();
		}
	}

	/**
	 * The part of the 1280x720 game that is really on screen, in game pixels. It is the whole game except in Full Screen,
	 * where a thin strip is cut off. The touch buttons are laid out inside this rectangle so none of them is hidden.
	 */
	public static var viewX(default, null):Int = 0;
	public static var viewY(default, null):Int = 0;
	public static var viewW(default, null):Int = 1280;
	public static var viewH(default, null):Int = 720;

	static function computeView():Void
	{
		final mode = FlxG.scaleMode;
		if (Std.isOfType(mode, CoverScaleMode) && mode.scale.x > 0 && mode.scale.y > 0)
		{
			viewX = Std.int(Math.max(0, Math.round(-mode.offset.x / mode.scale.x)));
			viewY = Std.int(Math.max(0, Math.round(-mode.offset.y / mode.scale.y)));
			viewW = Std.int(Math.min(FlxG.width, Math.round(mode.deviceSize.x / mode.scale.x)));
			viewH = Std.int(Math.min(FlxG.height, Math.round(mode.deviceSize.y / mode.scale.y)));
		}
		else
		{
			viewX = viewY = 0;
			viewW = FlxG.width;
			viewH = FlxG.height;
		}
	}

	/** Width of one black bar, in game pixels (0 when the game fills the display). */
	public static function barWidth():Float
	{
		final mode = FlxG.scaleMode;
		return (mode != null && mode.scale != null && mode.scale.x > 0) ? Math.max(0, mode.offset.x / mode.scale.x) : 0;
	}

	/**
	 * Hooked to `FlxG.signals.postStateSwitch`: runs after every state has finished `create()`,
	 * so all of the state's cameras exist and the touch camera ends up on top of them.
	 */
	public static function onStateSwitched():Void
	{
		final state = FlxG.state;
		var padMode:PadMode = NONE;
		var withHitbox = false;
		if (Std.isOfType(state, MusicBeatState))
		{
			final beat:MusicBeatState = cast state;
			padMode = beat.mobilePadMode;
			withHitbox = beat.mobileHitbox;
		}
		attach(state, padMode, withHitbox);
	}

	/** Editors have no pad: they get a grid of keyboard keys instead (see `KeyPad`). */
	static function keyPresetOf(state:FlxState):Null<Array<mobile.objects.KeyPad.KeySpec>>
		return KeyPad.presetFor(Type.getClassName(Type.getClass(state)));

	/**
	 * Creates the controls for `state` and adds them to it.
	 * Call after the state has built its own cameras (MusicBeatState does it from `createPost`).
	 */
	public static function attach(state:FlxState, padMode:PadMode, withHitbox:Bool):MobileControls
	{
		detach();
		MobileInput.init();
		MobileInput.vibrate = ClientPrefs.mobileVibration;
		final keys = keyPresetOf(state);
		instance = new MobileControls(state, keys != null ? NONE : padMode, withHitbox, keys);
		return instance;
	}

	public static function detach():Void
	{
		if (instance != null)
			instance.destroy();
		instance = null;
	}

	function new(state:FlxState, padMode:PadMode, withHitbox:Bool, ?keys:Array<mobile.objects.KeyPad.KeySpec>)
	{
		this.state = state;

		computeView();
		camera = new FlxCamera(viewX, viewY, viewW, viewH);
		camera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camera, false);
		// Many menus (options, pause...) draw on `FlxG.cameras.list[last]`. If that was this camera their
		// backgrounds would be drawn over the buttons, so it goes to the front of the list. It is still the
		// top layer on screen: that depends on the display order, which `onPreUpdate` keeps.
		FlxG.cameras.list.remove(camera);
		FlxG.cameras.list.unshift(camera);

		if (padMode != NONE || withHitbox)
		{
			pad = new VirtualPad(padMode == NONE ? FULL : padMode, ClientPrefs.mobilePadAlpha);
			pad.assignCamera(camera);
			state.add(pad);
		}

		// the black bars of a wide phone are free screen space: the pause button goes there, off the notes
		final bar = Math.floor(barWidth());
		if (withHitbox && bar >= Hitbox.SIDE_MIN)
		{
			rightBar = sideCamera(FlxG.width, bar);
			leftBar = sideCamera(-bar, bar);
		}

		if (withHitbox)
		{
			hitbox = new Hitbox(ClientPrefs.hitboxAlpha, hitboxStyle(), ClientPrefs.hitboxPosition == 'Bottom', ClientPrefs.mobileExtraButtons,
				ClientPrefs.hideHitboxHints);
			hitbox.assignCamera(camera);
			if (rightBar != null)
				hitbox.moveToBars(rightBar, leftBar, bar);
			state.add(hitbox);
			// the chart editor's test play ends with Esc, not with the pause control
			if (Std.isOfType(state, editors.EditorPlayState))
				MobileInput.bindKey(hitbox.pauseButton, flixel.input.keyboard.FlxKey.ESCAPE);
		}

		if (keys != null)
		{
			keypad = new KeyPad(keys, Math.max(ClientPrefs.mobilePadAlpha, 0.45));
			keypad.assignCamera(camera);
			state.add(keypad);
		}

		FlxG.signals.preUpdate.add(onPreUpdate);
		onPreUpdate();
	}

	static function sideCamera(x:Float, width:Float):FlxCamera
	{
		final cam = new FlxCamera(Std.int(x), 0, Std.int(width), FlxG.height);
		cam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(cam, false);
		FlxG.cameras.list.remove(cam);
		FlxG.cameras.list.unshift(cam);
		return cam;
	}

	static function hitboxStyle():Int
	{
		return switch (ClientPrefs.hitboxStyle)
		{
			case 'Flat': 1;
			case 'Outline': 2;
			default: 0;
		}
	}

	/** True when something besides the main state is being shown (pause menu, options, fades...). */
	static inline function substateOpen():Bool
		return FlxG.state != null && FlxG.state.subState != null;

	function onPreUpdate():Void
	{
		// something that adds a camera after ours would be drawn over the buttons: keep ours on top
		final game = FlxG.game;
		final top = game.getChildIndex(game._inputContainer) - 1;
		if (game.getChildIndex(camera.flashSprite) != top)
			game.setChildIndex(camera.flashSprite, top);
		// the bar cameras never overlap the game area, so they only need to stay above what is added later
		if (rightBar != null && game.getChildIndex(rightBar.flashSprite) != top - 1)
		{
			game.setChildIndex(rightBar.flashSprite, top - 1);
			game.setChildIndex(leftBar.flashSprite, top - 1);
		}

		if (hitbox == null)
		{
			if (pad != null && lastShowPad != true)
			{
				lastShowPad = true;
				pad.setActive(true);
			}
			return;
		}

		final showPad = substateOpen() || cutsceneMode;
		if (showPad == lastShowPad)
			return;
		lastShowPad = showPad;

		hitbox.setActive(!showPad);
		if (pad != null)
			pad.setActive(showPad);
		if (showPad)
			MobileInput.releaseAll(); // do not carry a held lane into the menu
	}

	/** Rebuilds the buttons of the state on screen (the screen mode changed, so the visible area did). */
	public static function reload():Void
	{
		if (instance != null)
			onStateSwitched();
	}

	/** Re-reads the alpha options, so the Mobile Options menu can preview changes live. */
	public function refresh():Void
	{
		if (pad != null)
			pad.setAlpha(ClientPrefs.mobilePadAlpha);
		MobileInput.vibrate = ClientPrefs.mobileVibration;
	}

	function destroy():Void
	{
		FlxG.signals.preUpdate.remove(onPreUpdate);
		// the objects are destroyed together with the state, the camera together with FlxG.cameras.reset()
		pad = null;
		hitbox = null;
		keypad = null;
		MobileInput.backIsEscape = false;
		state = null;
		camera = null;
		rightBar = null;
		leftBar = null;
		MobileInput.releaseAll();
	}
}
