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
import openfl.media.Sound;
import openfl.utils.Assets;
import sys.FileSystem;

class InitState extends FlxState
{
	var splash:FlxSprite;
	var spinner:FlxSprite;
	var progressBar:FlxBar;
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

		spinner = new FlxSprite().loadGraphic(AssetHelper.getAsset("spinner.png", IMAGE));
		spinner.scale.set(0.6, 0.6);
		spinner.updateHitbox();
		spinner.x = FlxG.width - spinner.width - 8;
		spinner.y = FlxG.height - spinner.height - 8;
		spinner.antialiasing = true;
		add(spinner);

		progressBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 1000, 10, this, "progressInPercent", 0, 100, true);
		progressBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE, true, FlxColor.WHITE);
		progressBar.screenCenter(X);
		progressBar.x = Math.ffloor(progressBar.x);
		progressBar.y = Math.ffloor(splash.y + splash.height + 45);
		add(progressBar);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		spinner.angle += elapsed * 150;

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
				cacheSongs();
			}
			else
			{
				text = new FlxText(0, 0, 0,
					"Uh oh! weeks.json is missing or corrupt.\nPlease check the 'data' folder.\nIf in doubt, re-extract the zip archive of this game.\n");
				text.setFormat("_sans", 24, FlxColor.WHITE, CENTER);
				text.updateHitbox();
				text.screenCenter(X);
				text.x = Math.ffloor(text.x);
				text.y = Math.ffloor(splash.y + splash.height + 45);
				text.antialiasing = true;
				text.alpha = 0.0;
				add(text);

				FlxTween.tween(progressBar, {alpha: 0.0}, 0.7);
				FlxTween.tween(spinner, {alpha: 0.0}, 0.7);
				FlxTween.tween(text, {alpha: 1.0}, 0.7);
			}

			checked = true;
		}
		else
			framePostDraw = true;
	}

	function cacheSongs():Void
	{
		threadPool = new ThreadPool(0, 4);
		threadPool.doWork.add(function(songPaths:Array<String>)
		{
			var inst:Sound = Sound.fromFile(songPaths[1]);
			Assets.cache.setSound(songPaths[1], inst);

			if (FileSystem.exists("./" + songPaths[2]))
			{
				var voices:Sound = Sound.fromFile(songPaths[2]);
				Assets.cache.setSound(songPaths[2], voices);
			}

			threadPool.sendComplete();
		});
		threadPool.onComplete.add(function(_:Dynamic)
		{
			loaded++;
			progressInPercent = (loaded / SongDatabase.songs.length) * 100;

			trace(loaded);

			if (loaded == SongDatabase.songs.length)
			{
				startGame();
			}
		});

		for (song in SongDatabase.songs)
		{
			var songPaths:Array<String> = SongDatabase.getSongPaths(song.songName);
			threadPool.queue(songPaths);
		}
	}

	function startGame()
	{
		FlxTween.tween(progressBar, {alpha: 0.0}, 0.7);
		FlxTween.tween(spinner, {alpha: 0.0}, 0.7);

		new FlxTimer().start(0.7, function(_:FlxTimer)
		{
			FlxG.switchState(new TitleState());
		});
	}
}
