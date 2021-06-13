package;

import flixel.FlxSprite;
import flixel.addons.ui.FlxButtonPlus;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

/* UI classes for the charter */
class Button extends FlxButtonPlus
{
	public function new(x:Float, y:Float, ?callback:Void->Void, ?label:String, size:Int = 16, padding:Float = 10)
	{
		super(x, y, callback, label, 300, 200);

		setButtonStyle(FlxColor.WHITE, FlxColor.BLACK, false, size, padding);
	}

	public function setButtonStyle(normalColor:FlxColor, highlightColor:FlxColor, alwaysHighlight:Bool = false, size:Int = 16, padding:Float = 10)
	{
		if (alwaysHighlight)
			textNormal.setFormat(null, size, highlightColor, "center");
		else
			textNormal.setFormat(null, size, normalColor, "center");
		textNormal.fieldWidth = 0;
		textNormal.fieldWidth += padding * 2;
		textNormal.updateHitbox();
		textNormal.y = y + padding - (textNormal.height / 4);

		textHighlight.setFormat(null, size, normalColor, "center");
		textHighlight.setFormat(null, size, highlightColor, "center");
		textHighlight.fieldWidth = textNormal.fieldWidth;
		textHighlight.updateHitbox();
		textHighlight.y = textNormal.y;

		var addedHeight = textNormal.height + padding;

		buttonNormal.setSize(textNormal.width, addedHeight);
		buttonHighlight.setSize(textHighlight.width, addedHeight);

		if (alwaysHighlight)
			offColor = [normalColor, normalColor];
		else
			offColor = [highlightColor, highlightColor];
		onColor = [normalColor, normalColor];

		updateInactiveButtonColors(offColor);
		updateActiveButtonColors(onColor);

		setSize(textNormal.width, textNormal.height);
	}
}

class BorderBox extends FlxSprite
{
	public function new(x:Float, y:Float, w:Int, h:Int)
	{
		super(x, y);

		makeGraphic(w, h, FlxColor.WHITE);
		graphic.bitmap.fillRect(new Rectangle(1, 1, w - 2, h - 2), FlxColor.BLACK);

		updateHitbox();
	}
}
