#if desktop
package;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;

class MissingWeekState extends FlxTransitionableState
{
	override public function create():Void
	{
		super.create();

		var text:FlxText = new FlxText(0, 0, 0, "weeks.json is missing! Please check the songs folder.\nPress any key to exit the game.", 32);
		text.screenCenter();
		add(text);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ANY)
		{
			Sys.exit(0);
		}
	}
}
#end
