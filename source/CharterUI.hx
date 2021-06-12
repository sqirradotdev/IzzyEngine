package;

import flixel.FlxSprite;
import flixel.addons.ui.FlxButtonPlus;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/* UI classes for the charter */
class Button extends FlxButtonPlus
{
	public function new(x:Float, y:Float, ?callback:Void->Void, ?label:String, size:Int = 20, padding:Float = 10)
	{
		super(x, y, callback, label, 300, 200);

		textNormal.setFormat(null, size, 0xffffff, "center");
		textNormal.fieldWidth = 0;
		textNormal.fieldWidth += padding * 2;
		textNormal.updateHitbox();
		textNormal.y = padding - (textNormal.height / 8);

		textHighlight.setFormat(null, size, 0x000000, "center");
		textHighlight.fieldWidth = textNormal.fieldWidth;
		textHighlight.updateHitbox();
		textHighlight.y = textNormal.y;

		var addedHeight = textNormal.height + padding;

		buttonNormal.setSize(textNormal.width, addedHeight);
		buttonHighlight.setSize(textHighlight.width, addedHeight);

		setSize(textNormal.width, textNormal.height);

		offColor = [0xff000000, 0xff000000];
		onColor = [0xffffffff, 0xffffffff];

		updateInactiveButtonColors(offColor);
		updateActiveButtonColors(onColor);
	}
}
