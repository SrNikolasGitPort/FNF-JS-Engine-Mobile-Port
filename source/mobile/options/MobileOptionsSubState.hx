package mobile.options;

import mobile.MobileControls;
import mobile.objects.HitboxPreview;
import options.BaseOptionsMenu;
import options.Option;

/**
 * "Mobile Options": everything about the touch controls.
 * The hitbox preview at the back redraws live while you change the options.
 */
class MobileOptionsSubState extends BaseOptionsMenu
{
	var preview:HitboxPreview;

	public function new()
	{
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu';

		var option:Option = new Option('Pad Opacity', 'How visible the menu buttons (D-pad, A, B) are.', 'mobilePadAlpha', 'percent', 0.6);
		option.scrollSpeed = 1;
		option.minValue = 0.1;
		option.maxValue = 1;
		option.changeValue = 0.05;
		option.decimals = 2;
		option.onChange = refresh;
		addOption(option);

		option = new Option('Hitbox Opacity', 'How visible the four lanes are while playing.\nAt 0% they are invisible but still work.', 'hitboxAlpha', 'percent', 0.35);
		option.scrollSpeed = 1;
		option.minValue = 0;
		option.maxValue = 1;
		option.changeValue = 0.05;
		option.decimals = 2;
		option.onChange = refresh;
		addOption(option);

		option = new Option('Hitbox Style:', 'Gradient fades the lanes from the bottom,\nFlat is a solid color, Outline only draws the borders.', 'hitboxStyle',
			'string', 'Gradient', ['Gradient', 'Flat', 'Outline']);
		option.onChange = refresh;
		addOption(option);

		option = new Option('Hitbox Position:', 'Full uses the whole screen height,\nBottom only the lower part (fewer accidental taps).', 'hitboxPosition',
			'string', 'Full', ['Full', 'Bottom']);
		option.onChange = refresh;
		addOption(option);

		option = new Option('Hide Hitbox Hints', 'Never draws the four lanes while playing (not even when you touch them).\nThey still work, you just play on the note strums.', 'hideHitboxHints',
			'bool', false);
		option.onChange = refresh;
		addOption(option);

		option = new Option('Extra Button', 'Shows a Bot Energy button in the top-left corner during songs.', 'mobileExtraButtons', 'bool', false);
		option.onChange = refresh;
		addOption(option);

		option = new Option('Vibration', 'Short vibration every time you press a button.', 'mobileVibration', 'bool', false);
		option.onChange = refresh;
		addOption(option);

		option = new Option('Screen:', 'Ratio: the normal 16:9 picture, black bars on wide phones.\nFull Screen: the normal picture without black bars (no zoom, nothing cut or distorted).\nStretched: distorts the picture to fill the display.', 'mobileScaleMode', 'string',
			'Ratio', ['Ratio', 'Full Screen', 'Stretched']);
		option.onChange = function()
		{
			MobileControls.applyScaleMode();
			MobileControls.reload();
			refresh();
		};
		addOption(option);

		super();
		rebuildPreview();
	}

	function refresh():Void
	{
		if (MobileControls.instance != null)
			MobileControls.instance.refresh();
		rebuildPreview();
	}

	function rebuildPreview():Void
	{
		final controls = MobileControls.instance;
		if (controls == null)
			return;

		if (preview != null)
		{
			remove(preview, true);
			preview.destroy();
		}

		// a small framed picture in the top-right corner (the old full-screen preview made the menu hard to read)
		preview = new HitboxPreview(1280 - 16 - 240, 24, 240, 135, ClientPrefs.hitboxAlpha, switch (ClientPrefs.hitboxStyle)
		{
			case 'Flat': 1;
			case 'Outline': 2;
			default: 0;
		}, ClientPrefs.hitboxPosition == 'Bottom', ClientPrefs.hideHitboxHints, ClientPrefs.mobileExtraButtons);
		preview.assignCamera(controls.camera);
		add(preview);
	}

	override function destroy():Void
	{
		preview = null;
		super.destroy();
	}
}
