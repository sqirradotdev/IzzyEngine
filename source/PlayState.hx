package;

import SongDatabase.Difficulty;
import SongDatabase.SongMetadata;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import openfl.utils.Assets;

enum Mode
{
	STORY;
	FREEPLAY;
}

class PlayState extends MusicBeatState
{
	var currentSong:SongMetadata;
	var currentWeek:Int;
	var currentDifficulty:Difficulty = NORMAL;
	var currentMode:Mode = FREEPLAY;

	var songPaths:Array<String>;

	var countingDown:Bool = false;

	var stageCamera:FlxCamera;
	var uiCamera:FlxCamera;

	var stageCameraFollow:FlxObject;

	var bg:FlxSprite;
	var stageFront:FlxSprite;
	var stageCurtains:FlxSprite;

	var enemy:FlxSprite;
	var gf:FlxSprite;
	var player:FlxSprite;

	var voicesSound:FlxSound;

	var countDownTimer:FlxTimer;

	public function new(?song:String, ?week:Int, ?difficulty:Difficulty, ?mode:Mode)
	{
		super();

		if (difficulty != null)
			currentDifficulty = difficulty;

		if (mode != null)
			currentMode = mode;

		switch (currentMode)
		{
			case STORY:
				currentWeek = week;
			// TODO: Add story mode loading
			case FREEPLAY:
				if (song != null)
				{
					currentSong = SongDatabase.getSongMetadata(song);
				}
		}
	}

	override public function create()
	{
		super.create();
		persistentUpdate = true;

		// Cache intro sounds to prevent hiccups.
		AssetHelper.getAsset("intro3.ogg", SOUND);
		AssetHelper.getAsset("intro2.ogg", SOUND);
		AssetHelper.getAsset("intro1.ogg", SOUND);
		AssetHelper.getAsset("introGo.ogg", SOUND);

		stageCamera = new FlxCamera();
		add(stageCamera);

		uiCamera = new FlxCamera();
		add(uiCamera);

		FlxG.cameras.add(stageCamera);
		FlxG.cameras.add(uiCamera);
		FlxG.cameras.setDefaultDrawTarget(stageCamera, true);

		bg = new FlxSprite(-600, -200).loadGraphic(AssetHelper.getAsset("stageback.png", IMAGE, "week1"));
		bg.antialiasing = true;
		bg.scrollFactor.set(0.9, 0.9);
		bg.active = false;
		add(bg);

		stageFront = new FlxSprite(-650, 600).loadGraphic(AssetHelper.getAsset("stagefront.png", IMAGE, "week1"));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = true;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		add(stageFront);

		stageCurtains = new FlxSprite(-500, -300).loadGraphic(AssetHelper.getAsset("stagecurtains.png", IMAGE, "week1"));
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.antialiasing = true;
		stageCurtains.scrollFactor.set(1.3, 1.3);
		stageCurtains.active = false;
		add(stageCurtains);

		gf = new Character(400, 130, "gf");
		gf.scrollFactor.set(0.95, 0.95);
		add(gf);
		gf.animation.play("danceLeft");

		enemy = new Character(100, 100, "dad");
		add(enemy);
		enemy.animation.play("idle");

		player = new Character(770, 450, "bf");
		add(player);
		player.animation.play("idle");

		songPaths = SongDatabase.getSongPaths(currentSong.songName, currentDifficulty);

		// Temporary bpm assignment
		Conductor.bpm = currentSong.bpm;

		startCountDown();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (countDownTimer != null)
		{
			if (countingDown)
				Conductor.time = -countDownTimer.timeLeft;
		}

		if (subState == null)
		{
			if (FlxG.keys.pressed.SEVEN)
			{
				openSubState(new CharterSubState());
			}
			if (FlxG.keys.justPressed.ESCAPE)
			{
				quit();
			}
		}
	}

	override function onBeat():Void
	{
		if (countingDown)
		{
			switch (Conductor.beat)
			{
				case -4:
					FlxG.sound.play(AssetHelper.getAsset("intro3.ogg", SOUND));
				case -3:
					FlxG.sound.play(AssetHelper.getAsset("intro2.ogg", SOUND));
				case -2:
					FlxG.sound.play(AssetHelper.getAsset("intro1.ogg", SOUND));
				case -1:
					FlxG.sound.play(AssetHelper.getAsset("introGo.ogg", SOUND));
			}
		}

		if ((Conductor.beat % 4) == 0)
		{
			if (voicesSound != null)
			{
				var delta:Float = FlxG.sound.music.time - voicesSound.time;
				trace("Music Vocal Delta: " + delta);
				if (Math.abs(delta) > 10)
				{
					trace("resync vocal");
					voicesSound.time = FlxG.sound.music.time;
				}
			}
		}
	}

	function startCountDown()
	{
		new FlxTimer().start(0.3, function(_:FlxTimer)
		{
			countDownTimer = new FlxTimer();
			countingDown = true;
			countDownTimer.start((60.0 / Conductor.bpm) * 4, function(__:FlxTimer)
			{
				FlxG.sound.playMusic(Assets.cache.getSound(songPaths[1]));
				voicesSound = FlxG.sound.play(Assets.cache.getSound(songPaths[2]));
				countingDown = false;
			});
		});
	}

	function quit()
	{
		switch (currentMode)
		{
			case FREEPLAY:
				FlxG.switchState(new FreeplayState());
			case STORY:
				FlxG.switchState(new MainMenuState());
		}
	}
}
