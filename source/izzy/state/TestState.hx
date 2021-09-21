package izzy.state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import izzy.ui.GameplayUI.StrumLine;

class TestState extends FlxState
{
	override public function create():Void
	{
		super.create();

		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height));
		var sl:StrumLine = new StrumLine(0, 0, 0.5);
		add(sl);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
