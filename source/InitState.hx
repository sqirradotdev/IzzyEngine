package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.system.ThreadPool;

class InitState extends FlxState
{
	var splash:FlxSprite;
	var text:FlxText;

	var threadPool:ThreadPool;

	var framePostDraw:Bool = false;
	var checked:Bool = false;
	var loaded:Int = 0;
	var progressInPercent:Float = 0;

	override public function create():Void
	{
		super.create();

		splash = new FlxSprite().loadGraphic(AssetHelper.getAsset("splash.png", IMAGE));
		splash.screenCenter();
		splash.y -= 30;
		splash.antialiasing = true;
		add(splash);

		text = new FlxText(0, 0, 0, "Loading...");
		text.setFormat("_sans", 24, FlxColor.WHITE, CENTER);
		text.updateHitbox();
		text.screenCenter(X);
		text.x = Math.ffloor(text.x);
		text.y = Math.ffloor(splash.y + splash.height + 45);
		text.antialiasing = true;
		add(text);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (framePostDraw && !checked)
		{
			if (SongDatabase.updateWeekList())
			{
				var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
				diamond.persist = true;
				diamond.destroyOnNoUse = false;

				FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1),
					{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
				FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
					{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

				SongDatabase.updateSongList();
				startGame();
			}
			else
			{
				text.text = "Uh oh! weeks.json is missing or corrupt.\nPlease check the 'data' folder.\nIf in doubt, re-extract the zip archive of this game.\n";
			}
			checked = true;
		}
		else
			framePostDraw = true;
	}

	function startGame()
	{
		new FlxTimer().start(0.7, function(_:FlxTimer)
		{
			FlxG.switchState(new TitleState());
		});
	}
}
