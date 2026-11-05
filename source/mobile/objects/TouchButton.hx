package mobile.objects;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import mobile.MobileInput;

/**
 * A screen area that reports touches to `MobileInput`.
 * It never reads the touches itself: `MobileInput` tests every registered button once per frame.
 */
class TouchButton extends FlxSprite
{
	public var id:Int;

	/** Buttons with a higher priority get to look at the touches first. */
	public var priority:Int = 0;

	/** An exclusive button takes the touches it catches away from the buttons below it. */
	public var exclusive:Bool = false;

	/** When false the button is ignored by `MobileInput` (used when a layer is hidden). */
	public var touchEnabled:Bool = true;

	/** Extra touch area around the sprite, in game pixels. */
	public var hitPadding:Float = 0;

	/**
	 * >= 0: this button types a keyboard key (see `MobileInput`), so keyboard-only code such as the editors
	 * reacts to it exactly as if the key was pressed on a physical keyboard.
	 */
	public var keyCode:Int = -1;

	/** Key buttons only: a tap latches the key down until the next tap (for Ctrl / Shift / Alt). */
	public var sticky:Bool = false;

	/** Key buttons only: true while a sticky key is latched. */
	public var latched:Bool = false;

	/** Small caption drawn on (or above) the button. Set with `setLabel`. */
	public var caption(default, null):flixel.text.FlxText;

	var captionAbove:Bool = false;

	public var idleAlpha:Float = 0.6;
	public var pressedAlpha:Float = 1.0;

	/** Scale applied while the button is held (a tiny "pressed" cue that costs nothing). */
	public var pressedScale:Float = 0.92;

	var wasPressed:Bool = false;

	public function new(x:Float, y:Float, id:Int, graphic:FlxGraphic)
	{
		super(x, y);
		this.id = id;
		loadGraphic(graphic);
		scrollFactor.set();
		moves = false;
		immovable = true;
		alpha = idleAlpha;
		antialiasing = true;
		MobileInput.register(this);
	}

	public inline function containsView(px:Float, py:Float):Bool
	{
		return px >= x - hitPadding && px <= x + width + hitPadding && py >= y - hitPadding && py <= y + height + hitPadding;
	}

	override function update(elapsed:Float):Void
	{
		// no super.update(): the button has no animation and does not move, so skipping it is free
		final isPressed = MobileInput.pressed(id) && touchEnabled;
		if (isPressed != wasPressed)
		{
			wasPressed = isPressed;
			alpha = isPressed ? pressedAlpha : idleAlpha;
			final s = isPressed ? pressedScale : 1.0;
			scale.set(s, s);
		}
	}

	/**
	 * Adds a caption. `above` puts it over the button (round face buttons), otherwise it is centred inside
	 * (pill buttons).
	 */
	public function setLabel(text:String, size:Int = 20, above:Bool = false):Void
	{
		if (text == null || text == '')
			return;
		if (caption == null)
		{
			caption = new flixel.text.FlxText(0, 0, 0, text, size);
			caption.setFormat(Paths.font('vcr.ttf'), size, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
			caption.borderSize = 2;
			caption.scrollFactor.set();
			caption.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			caption.text = text;
			caption.size = size;
		}
		captionAbove = above;
	}

	override function draw():Void
	{
		super.draw();
		if (caption != null && visible)
		{
			caption.cameras = cameras;
			caption.alpha = Math.min(1, alpha + 0.25);
			caption.x = x + (width - caption.width) * .5;
			caption.y = captionAbove ? y - caption.height + 4 : y + (height - caption.height) * .5;
			caption.draw();
		}
	}

	/** Re-applies the idle alpha (used when the alpha option changes). */
	public function setIdleAlpha(value:Float):Void
	{
		idleAlpha = value;
		if (!wasPressed)
			alpha = value;
	}

	override function destroy():Void
	{
		MobileInput.unregister(this);
		MobileInput.freeId(id);
		if (caption != null)
			caption.destroy();
		caption = null;
		super.destroy();
	}
}
