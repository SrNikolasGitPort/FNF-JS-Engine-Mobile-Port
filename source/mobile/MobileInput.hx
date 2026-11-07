package mobile;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.IFlxInputManager;
import mobile.objects.TouchButton;

/**
 * Every virtual button the touch layer can report.
 * The first block is the D-pad / face buttons used in menus, the second block is gameplay.
 */
enum abstract MobileButtonID(Int) from Int to Int
{
	var UP = 0;
	var DOWN = 1;
	var LEFT = 2;
	var RIGHT = 3;
	var A = 4;
	var B = 5;
	var X = 6;
	var Y = 7;
	var NOTE_LEFT = 8;
	var NOTE_DOWN = 9;
	var NOTE_UP = 10;
	var NOTE_RIGHT = 11;
	var PAUSE = 12;
	var BOT_ENERGY = 13;
	var C = 14;
	var TOTAL = 15;
}

/**
 * Turns raw touches into one `FlxInput` per virtual button.
 *
 * It is registered in `FlxG.inputs`, so it is polled right before the state updates.
 * That keeps `justPressed` frame-accurate (no extra latency for rhythm input) and lets
 * `Controls` read the buttons like any other input device.
 *
 * Touches are checked against every registered `TouchButton`, so a finger that slides from one
 * hitbox lane to the next releases the old lane and presses the new one, and several fingers
 * can hold several lanes at the same time.
 */
class MobileInput implements IFlxInputManager
{
	public static var instance(default, null):MobileInput;

	static final inputs:Array<FlxInput<Int>> = [for (i in 0...(MobileButtonID.TOTAL : Int)) new FlxInput<Int>(i)];
	static final down:Array<Bool> = [for (i in 0...(MobileButtonID.TOTAL : Int)) false];
	/** ids from here on are handed out by `allocId` to keyboard-key buttons */
	static var nextId:Int = MobileButtonID.TOTAL;
	static final keyButtons:Array<TouchButton> = [];
	static final keysDown:Map<Int, Bool> = [];
	static final buttons:Array<TouchButton> = [];
	static final claimed:Array<Bool> = [];
	static final point:flixel.math.FlxPoint = flixel.math.FlxPoint.get();

	/** Set from the options menu: short vibration when a button goes down. */
	public static var vibrate:Bool = false;

	public static function init():Void
	{
		if (instance != null)
			return;
		instance = new MobileInput();
		FlxG.inputs.add(instance);

		// ORDER MATTERS (this is input latency). `FlxG.inputs` updates its managers in list order, and the Controls
		// action manager takes its snapshot of every button during its own update. When this manager ran after it,
		// the lanes were seen one frame late by everything that reads `Controls` (the whole game). Right after the
		// touch manager is the earliest possible spot: the touches are fresh and nobody has read the buttons yet.
		final list = FlxG.inputs.list;
		list.remove(instance);
		final at = list.indexOf(FlxG.touches);
		list.insert(at >= 0 ? at + 1 : 0, instance);

		// A tap that starts and ends between two frames leaves a touch that is only "just released", which would
		// be a dropped note. Remember which touches began since the last frame so that tap still counts once.
		FlxG.stage.addEventListener(openfl.events.TouchEvent.TOUCH_BEGIN, onTouchBegin);
	}

	public static inline function input(id:MobileButtonID):FlxInput<Int>
		return inputs[id];

	public static inline function pressed(id:MobileButtonID):Bool
		return inputs[id].pressed;

	public static inline function justPressed(id:MobileButtonID):Bool
		return inputs[id].justPressed;

	public static inline function justReleased(id:MobileButtonID):Bool
		return inputs[id].justReleased;

	static final freeIds:Array<Int> = [];

	/** Gives an id back (its button was destroyed) so editors that are opened again and again do not grow the tables. */
	public static function freeId(id:Int):Void
	{
		if (id >= (MobileButtonID.TOTAL : Int) && !freeIds.contains(id))
		{
			inputs[id].reset();
			down[id] = false;
			freeIds.push(id);
		}
	}

	/** Reserves a new button id (used by key buttons, which are not part of `MobileButtonID`). */
	public static function allocId():Int
	{
		if (freeIds.length > 0)
			return freeIds.pop();
		final id = nextId++;
		inputs.push(new FlxInput<Int>(id));
		down.push(false);
		return id;
	}

	/** Makes `button` type `keyCode` on the virtual keyboard. */
	public static function bindKey(button:TouchButton, keyCode:Int):Void
	{
		button.keyCode = keyCode;
		if (!keyButtons.contains(button))
			keyButtons.push(button);
	}

	/** Sends a real keyboard event, so `FlxG.keys` (and any text input) sees it like a physical key. */
	static function sendKey(keyCode:Int, isDown:Bool):Void
	{
		if (keysDown.exists(keyCode) == isDown)
			return; // already in that state
		if (isDown)
			keysDown.set(keyCode, true);
		else
			keysDown.remove(keyCode);
		final type = isDown ? openfl.events.KeyboardEvent.KEY_DOWN : openfl.events.KeyboardEvent.KEY_UP;
		FlxG.stage.dispatchEvent(new openfl.events.KeyboardEvent(type, true, false, 0, keyCode));
	}

	static final pendingUp:Array<Int> = [];

	/** Editors listen to Esc, not to the Android Back gesture: while this is true, Back types Esc. */
	public static var backIsEscape:Bool = false;

	/** Releases every key that a button is holding down (state switch, focus lost...). */
	static function releaseKeys():Void
	{
		for (code in [for (c in keysDown.keys()) c])
			sendKey(code, false);
		for (button in keyButtons)
			button.latched = false;
	}

	public static function register(button:TouchButton):Void
	{
		if (buttons.contains(button))
			return;
		buttons.push(button);
		// higher priority first, so exclusive buttons (pause...) can claim touches before the lanes
		buttons.sort((a, b) -> b.priority - a.priority);
	}

	public static function unregister(button:TouchButton):Void
	{
		buttons.remove(button);
		if (keyButtons.remove(button) && button.keyCode >= 0)
		{
			button.latched = false;
			var stillUsed = false;
			for (other in keyButtons)
				if (other.keyCode == button.keyCode && (other.latched || inputs[other.id].pressed))
					stillUsed = true;
			if (!stillUsed)
				sendKey(button.keyCode, false);
		}
	}

	public static function releaseAll():Void
	{
		releaseKeys();
		for (i in 0...inputs.length)
		{
			down[i] = false;
			inputs[i].reset();
		}
	}

	function new() {}

	static final quickTaps:Array<Int> = [];

	static function onTouchBegin(e:openfl.events.TouchEvent):Void
		quickTaps.push(e.touchPointID);

	public function update():Void
	{
		while (pendingUp.length > 0)
			sendKey(pendingUp.pop(), false);

		#if android
		if (backIsEscape && FlxG.android.justPressed.BACK)
		{
			sendKey(flixel.input.keyboard.FlxKey.ESCAPE, true);
			pendingUp.push(flixel.input.keyboard.FlxKey.ESCAPE); // released on the next frame
		}
		#end

		for (i in 0...down.length)
			down[i] = false;

		final touches = FlxG.touches.list;
		while (claimed.length < touches.length)
			claimed.push(false);
		for (i in 0...touches.length)
			claimed[i] = false;

		if (touches.length > 0)
		{
			for (button in buttons)
			{
				if (!button.exists || !button.touchEnabled)
					continue;

				final camera = button.camera;
				for (i in 0...touches.length)
				{
					final touch = touches[i];
					// pressed, just pressed, or a tap that already ended inside this very frame
if (touch == null || !(touch.pressed || touch.justPressed || (touch.justReleased && quickTaps.length > 0 && quickTaps.contains(touch.touchPointID))))
						continue;
					if (claimed[i] && !button.exclusive)
						continue;

					touch.getPositionInCameraView(camera, point);
					if (button.containsView(point.x, point.y))
					{
						down[button.id] = true;
						if (button.exclusive)
							claimed[i] = true;
					}
				}
			}
		}

		if (quickTaps.length > 0)
			quickTaps.resize(0);

		// press()/release() first, update() after: this makes JUST_PRESSED last exactly one frame,
		// the same way FlxKeyboard behaves.
		var buzz:Bool = false;
		for (i in 0...inputs.length)
		{
			final input = inputs[i];
			if (down[i] && !input.pressed)
			{
				input.press();
				buzz = true;
			}
			else if (!down[i] && input.pressed)
				input.release();
			input.update();
		}

		for (button in keyButtons)
		{
			final input = inputs[button.id];
			if (button.sticky)
			{
				if (input.justPressed)
				{
					button.latched = !button.latched;
					sendKey(button.keyCode, button.latched);
				}
			}
			else if (input.justPressed)
				sendKey(button.keyCode, true);
			else if (input.justReleased)
				sendKey(button.keyCode, false);
		}

		#if mobile
		if (buzz && vibrate)
			lime.ui.Haptic.vibrate(0, 12);
		#end
	}

	public function reset():Void
		releaseAll();

	public function destroy():Void
	{
		releaseAll();
		buttons.resize(0);
	}

	public function onFocus():Void {}

	public function onFocusLost():Void
		releaseAll();
}
