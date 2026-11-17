package mobile.objects;

import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import mobile.MobileControls;
import mobile.MobileInput;

/** One key of a `KeyPad`: caption, key, and whether a tap latches it (modifier keys). */
typedef KeySpec =
{
	var label:String;
	var key:Int;
	@:optional var sticky:Bool;
}

/**
 * A grid of small on-screen keyboard keys for the editors.
 *
 * The editors were written for a keyboard (Space, W/A/S/D, Ctrl, Shift, Esc...). Every button here
 * types the real key through `MobileInput`, so the editors work with touch without being rewritten.
 * Ctrl / Shift / Alt are "sticky": tap once to hold, tap again to release.
 * A small tab at the bottom hides/shows the whole grid so it never gets in the way.
 */
class KeyPad extends FlxTypedGroup<TouchButton>
{
	/** Stays collapsed/expanded across editors for the whole session. */
	static var collapsed:Bool = false;

	static inline var KEY_W:Int = 82;
	static inline var KEY_H:Int = 54;
	static inline var KEY_GAP:Int = 6;

	public var keys(default, null):Array<TouchButton> = [];

	var toggle:TouchButton;
	var toggleId:Int;
	var enabled:Bool = true;

	static function k(label:String, key:FlxKey, sticky:Bool = false):KeySpec
		return {label: label, key: key, sticky: sticky};

	/** Key layout of the editor class `name`, or null when it has none. */
	public static function presetFor(name:String):Null<Array<KeySpec>>
	{
		final arrows = [k('Up', UP), k('Dn', DOWN), k('Lt', LEFT), k('Rt', RIGHT)];
		return switch (name)
		{
			case 'editors.ChartingState':
				[
					k('Space', SPACE), k('W', W), k('S', S), k('A', A), k('D', D), k('Q', Q), k('E', E),
					k('R', R), k('Z', Z), k('Tab', TAB), k('Enter', ENTER), k('Esc', ESCAPE), k('[', LBRACKET), k(']', RBRACKET),
					k('Ctrl', CONTROL, true), k('Shift', SHIFT, true), k('Alt', ALT, true),
				].concat(arrows);
			case 'editors.CharacterEditorState':
				[
					k('Space', SPACE), k('W', W), k('S', S), k('A', A), k('D', D), k('Q', Q), k('E', E),
					k('R', R), k('T', T), k('I', I), k('J', J), k('K', K), k('L', L), k('F1', F1),
					k('Esc', ESCAPE), k('Shift', SHIFT, true),
				].concat(arrows);
			case 'editors.DialogueCharacterEditorState':
				[
					k('Space', SPACE), k('W', W), k('S', S), k('A', A), k('D', D), k('Q', Q), k('E', E),
					k('R', R), k('H', H), k('I', I), k('J', J), k('K', K), k('L', L), k('Enter', ENTER),
					k('Esc', ESCAPE), k('Shift', SHIFT, true),
				].concat(arrows);
			case 'editors.DialogueEditorState':
				[k('Space', SPACE), k('W', W), k('S', S), k('A', A), k('D', D), k('O', O), k('P', P), k('Enter', ENTER), k('Esc', ESCAPE)];
			case 'editors.WeekEditorState':
				[k('Enter', ENTER), k('Esc', ESCAPE), k('Up', UP), k('Dn', DOWN)];
			case 'editors.MenuCharacterEditorState':
				[k('Space', SPACE), k('Enter', ENTER), k('Esc', ESCAPE), k('Shift', SHIFT, true)].concat(arrows);
			case 'editors.NoteSplashDebugState':
				[
					k('Space', SPACE), k('W', W), k('S', S), k('A', A), k('D', D), k('Q', Q), k('E', E),
					k('C', C), k('V', V), k('Enter', ENTER), k('Esc', ESCAPE), k('Ctrl', CONTROL, true), k('Shift', SHIFT, true),
				].concat(arrows);
			default: null;
		}
	}

	public function new(spec:Array<KeySpec>, alpha:Float)
	{
		super();

		// bottom-right block, filled from the bottom up, 7 keys per row
		final perRow = 7;
		final rows = Math.ceil(spec.length / perRow);
		final x0 = MobileControls.viewW - 10 - perRow * (KEY_W + KEY_GAP) + KEY_GAP;
		final y0 = MobileControls.viewH - 10 - KEY_H - 52; // leaves room for the tab below
		for (i in 0...spec.length)
		{
			final col = i % perRow;
			final row = Std.int(i / perRow);
			final s = spec[i];
			final id = MobileInput.allocId();
			final b = new TouchButton(x0 + col * (KEY_W + KEY_GAP), y0 - (rows - 1 - row) * (KEY_H + KEY_GAP), id, MobileGraphics.pill(KEY_W, KEY_H, s.sticky == true ? 0xFFD29922 : 0xFF2F81F7));
			b.hitPadding = 2;
			b.setLabel(s.label, 22);
			b.sticky = s.sticky == true;
			MobileInput.bindKey(b, s.key);
			b.setIdleAlpha(alpha);
			keys.push(b);
			add(b);
		}

		toggleId = MobileInput.allocId();
		toggle = new TouchButton(MobileControls.viewW - 10 - 170, MobileControls.viewH - 10 - 44, toggleId, MobileGraphics.pill(170, 44, 0xFF444444));
		toggle.hitPadding = 6;
		toggle.exclusive = true;
		toggle.priority = 10;
		toggle.setLabel('Keys', 22);
		toggle.setIdleAlpha(Math.max(alpha, 0.6));
		add(toggle);

		apply();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (enabled && MobileInput.justPressed(toggleId))
		{
			collapsed = !collapsed;
			apply();
		}
	}

	function apply():Void
	{
		MobileInput.backIsEscape = enabled;
		toggle.setLabel(collapsed ? 'Keys +' : 'Keys -', 22);
		for (b in keys)
		{
			b.visible = !collapsed && enabled;
			b.touchEnabled = !collapsed && enabled;
			if (collapsed && b.latched)
				MobileInput.releaseAll(); // a hidden Ctrl/Shift must not stay held
		}
	}

	/** Used when a substate (or anything else) takes over the screen. */
	public function setActive(value:Bool):Void
	{
		enabled = value;
		visible = value;
		toggle.touchEnabled = value;
		toggle.visible = value;
		apply();
	}

	public function assignCamera(camera:FlxCamera):Void
	{
		cameras = [camera];
		for (b in members)
			if (b != null)
				b.cameras = [camera];
	}
}
