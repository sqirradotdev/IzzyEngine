package;

import CharterUI.BorderBox;
import CharterUI.Button;
import GameplayUI.StrumLine;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUISubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class CharterSubState extends FlxUISubState
{
	var tabButtonTexts:Array<String> = ["Charter", "Modchart", "Song"];

	var tabButtons:FlxTypedGroup<Button>;
	var enemyStrumLine:StrumLine;
	var playerStrumLine:StrumLine;
	var button:Button;

	override public function create():Void
	{
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.4;
		add(bg);

		tabButtons = new FlxTypedGroup<Button>();
		add(tabButtons);

		// Please tell me a better way on doing this, if there's any.
		var box:BorderBox = new BorderBox(877, 106, 375, 587);
		add(box);

		// For some reason, using FlxTypedSpriteGroup has a visual glitch that
		// offsets the buttons visually, but not the hitbox.
		// That's why I'm using this crap hack. Sorry.
		var sumWidth:Float = 0;
		for (i in 0...tabButtonTexts.length)
		{
			var text:String = tabButtonTexts[i];

			var button:Button = new Button(sumWidth, 0, null, text);
			if (i == 0)
			{
				button.setButtonStyle(FlxColor.WHITE, FlxColor.BLACK, true);
			}
			tabButtons.add(button);
			sumWidth += button.width;
		}

		tabButtons.forEach(function(button:Button)
		{
			button.x += Math.floor((box.x + (box.width / 2)) - (sumWidth / 2));
			button.y += Math.floor(box.y - button.height);
		});

		enemyStrumLine = new StrumLine(40, box.y, 0.6);
		add(enemyStrumLine);

		playerStrumLine = new StrumLine(350, box.y, 0.6);
		add(playerStrumLine);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			close();
		}
	}
}
