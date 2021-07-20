package;

import ChartReader.ChartData;
import ChartReader.NoteData;
import GameplayUI.NoteObject;
import GameplayUI.StrumLine;
import SongDatabase.Difficulty;
import SongDatabase.SongMetadata;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.macro.Type.AnonType;
import openfl.utils.Assets;

enum Mode
{
	STORY;
	FREEPLAY;
}

class PlayState extends MusicBeatState
{
	/* Information on what's currently playing right now */
	var currentSong:SongMetadata;
	var currentWeek:Int;
	var currentDifficulty:Difficulty = NORMAL;
	var currentMode:Mode = FREEPLAY;
	var songPaths:Array<String>;

	var countingDown:Bool = false;

	var chartData:ChartData;
	var currentEnemyNoteHold:Array<NoteData> = [];
	var currentPlayerNoteHold:Array<NoteData> = [];

	var prevInput:Array<Bool>;

	var stageCamera:FlxCamera;
	var uiCamera:FlxCamera;

	var stageCameraFollow:FlxObject;

	var bg:FlxSprite;
	var stageFront:FlxSprite;
	var stageCurtains:FlxSprite;

	var enemy:FlxSprite;
	var gf:FlxSprite;
	var player:FlxSprite;

	var enemyStrumLine:StrumLine;
	var playerStrumLine:StrumLine;

	var voicesSound:FlxSound;

	var countDownTimer:FlxTimer;

	public function new(song:String, ?week:Int, ?difficulty:Difficulty, ?mode:Mode)
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
				currentSong = SongDatabase.getSongMetadata(song);
		}
	}

	override public function create()
	{
		super.create();
		persistentUpdate = true;

		getChartData();

		/* Cache sounds to prevent hiccups */
		AssetHelper.getAsset("intro3.ogg", SOUND);
		AssetHelper.getAsset("intro2.ogg", SOUND);
		AssetHelper.getAsset("intro1.ogg", SOUND);
		AssetHelper.getAsset("introGo.ogg", SOUND);

		AssetHelper.getAsset("missnote1.ogg", SOUND);
		AssetHelper.getAsset("missnote2.ogg", SOUND);
		AssetHelper.getAsset("missnote3.ogg", SOUND);

		stageCamera = FlxG.camera;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.add(uiCamera, false);

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

		enemyStrumLine = new StrumLine(70, 50, 1.0, chartData.noteSpeed);
		enemyStrumLine.camera = uiCamera;
		add(enemyStrumLine);

		playerStrumLine = new StrumLine(750, 50, 1.0, chartData.noteSpeed);
		playerStrumLine.camera = uiCamera;
		add(playerStrumLine);

		for (noteData in chartData.enemyNotes)
			enemyStrumLine.addNote(noteData.strumIndex, noteData.time, noteData.holdTime);

		for (noteData in chartData.playerNotes)
			playerStrumLine.addNote(noteData.strumIndex, noteData.time, noteData.holdTime);

		startCountDown();

		// FlxTween.tween(enemyStrumLine, {noteSpeed: 1.5}, 0.2, {type: PINGPONG, ease: FlxEase.sineInOut});
		// FlxTween.tween(playerStrumLine, {noteSpeed: 1.5}, 0.2, {type: PINGPONG, ease: FlxEase.sineInOut});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (countDownTimer != null)
		{
			if (countingDown)
				Conductor.time = -countDownTimer.timeLeft;
		}

		var input:Array<Bool> = [
			FlxG.keys.pressed.D || FlxG.keys.pressed.LEFT,
			FlxG.keys.pressed.F || FlxG.keys.pressed.DOWN,
			FlxG.keys.pressed.J || FlxG.keys.pressed.UP,
			FlxG.keys.pressed.K || FlxG.keys.pressed.RIGHT
		];

		/* Player input handling */
		for (i in 0...input.length)
		{
			/* If an input was pressed */
			if (input[i])
			{
				/* Check if prevInput is not null */
				if (prevInput != null)
				{
					/* Check if it's just pressed once */
					if (input[i] != prevInput[i])
					{
						var noteIndex:Int = 0;

						/* Make sure that the note exists */
						while (chartData.playerNotes[noteIndex] != null)
						{
							/* If a note in an array matches strumIndex with the current input */
							if (chartData.playerNotes[noteIndex].strumIndex == i)
							{
								var timeRel:Float = chartData.playerNotes[noteIndex].time - Conductor.time;
								/* Only check if it's in a hit window (in this case, 75 ms) */
								if (timeRel < 0.075)
								{
									/* If it's not a note hold */
									if (chartData.playerNotes[noteIndex].holdTime == 0.0)
									{
										playerStrumLine.removeNote(i, chartData.playerNotes[noteIndex].time);
									}
									/* It's a note hold */
									else
									{
										playerStrumLine.getNote(i, chartData.playerNotes[noteIndex].time).arrow.visible = false;
										currentPlayerNoteHold.push(chartData.playerNotes[noteIndex]);
									}

									if (playerStrumLine.getCurrentStrumAnim(i).name != "hit")
										playerStrumLine.playStrumAnim(i, "hit");

									chartData.playerNotes.remove(chartData.playerNotes[noteIndex]);

									hitBehaviour();

									var msTimeRel:Int = Math.floor(timeRel * 1000);
									trace("Hit: " + msTimeRel + " ms");
								}
								/* Break while loop because it found the note it wants */
								break;
							}
							else
								/* If not, go to next array */
								noteIndex++;
						}
					}
					/* If not, play a basic pressed animation */
					else
					{
						if (playerStrumLine.getCurrentStrumAnim(i).name != "pressed"
							&& playerStrumLine.getCurrentStrumAnim(i).name != "hit")
							playerStrumLine.playStrumAnim(i, "pressed");
					}
				}
			}
			/* If not, play an idle animation */
			else
			{
				if (playerStrumLine.getCurrentStrumAnim(i).name != "idle")
					playerStrumLine.playStrumAnim(i, "idle");
			}
		}

		/* Player note miss */
		while (chartData.playerNotes[0] != null && chartData.playerNotes[0].time - Conductor.time < -0.1)
		{
			trace("Miss note time " + chartData.playerNotes[0].time);

			playerStrumLine.invalidateNote(chartData.playerNotes[0].strumIndex, chartData.playerNotes[0].time);
			chartData.playerNotes.shift();
			missBehaviour();
		}

		/* Note holds */
		for (note in currentPlayerNoteHold)
		{
			var holdProgress:Float = Conductor.time - note.time;
			var noteObject:NoteObject = playerStrumLine.getNote(note.strumIndex, note.time);

			noteObject.holdProgress = Conductor.interpTime - note.time;

			if (!input[note.strumIndex])
			{
				playerStrumLine.invalidateNote(note.strumIndex, note.time);
				currentPlayerNoteHold.remove(note);
				missBehaviour(false);
			}
			if (holdProgress > note.holdTime)
			{
				currentPlayerNoteHold.remove(note);
				playerStrumLine.removeNote(note.strumIndex, note.time);
			}
		}

		prevInput = input;

		/* Enemy autoplay */
		var enemyNoteIndex:Int = 0;
		while (chartData.enemyNotes[enemyNoteIndex] != null && chartData.enemyNotes[enemyNoteIndex].time - Conductor.time < 0)
		{
			var strumIndex:Int = chartData.enemyNotes[0].strumIndex;
			var noteObject:NoteObject = enemyStrumLine.getNote(strumIndex, chartData.enemyNotes[0].time);

			if (chartData.enemyNotes[0].holdTime == 0.0)
			{
				enemyStrumLine.removeNote(strumIndex, chartData.enemyNotes[0].time);
				chartData.enemyNotes.remove(chartData.enemyNotes[enemyNoteIndex]);
			}
			else
			{
				// trace(enemyStrumLine.getCurrentStrumAnim(strumIndex).name);

				noteObject.arrow.visible = false;
				noteObject.holdProgress = Conductor.interpTime - noteObject.time;
				if (noteObject.holdProgress > noteObject.holdTime)
				{
					enemyStrumLine.removeNote(strumIndex, chartData.enemyNotes[0].time);
					chartData.enemyNotes.remove(chartData.enemyNotes[enemyNoteIndex]);
				}
			}

			if (enemyStrumLine.getCurrentStrumAnim(strumIndex).name != "hit")
				enemyStrumLine.playStrumAnim(strumIndex, "hit");

			new FlxTimer().start(0.1, function(_:FlxTimer)
			{
				if (enemyStrumLine.getCurrentStrumAnim(strumIndex).name != "idle")
					enemyStrumLine.playStrumAnim(strumIndex, "idle");
			});

			voicesSound.volume = 1.0;

			enemyNoteIndex++;
		}

		/* Update strum line time based on Conductor time */
		enemyStrumLine.time = Conductor.interpTime;
		playerStrumLine.time = Conductor.interpTime;

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

		/* Resync the vocals */
		if (voicesSound != null)
		{
			var delta:Float = voicesSound.time - FlxG.sound.music.time;
			if (Math.abs(delta) >= 5)
			{
				trace("Delta is " + delta + ", resyncing");
				voicesSound.time = FlxG.sound.music.time;
			}
		}
	}

	/** 
	 * Prepare the song's chart
	 */
	function getChartData()
	{
		songPaths = SongDatabase.getSongPaths(currentSong.songName, currentDifficulty);
		trace(songPaths);

		chartData = ChartReader.readChart(songPaths[0]);

		trace("Enemy notes:\n" + chartData.enemyNotes);
		trace("Player notes:\n" + chartData.playerNotes);

		Conductor.bpm = currentSong.bpm;
		Conductor.time = -(60.0 / Conductor.bpm) * 4;
	}

	/** 
	 * Start the song countdown
	 */
	function startCountDown()
	{
		new FlxTimer().start(0.25, function(_:FlxTimer)
		{
			countDownTimer = new FlxTimer();
			countingDown = true;
			countDownTimer.start((60.0 / Conductor.bpm) * 4, function(__:FlxTimer)
			{
				startSong();
			});

			onBeat();
		});
	}

	/** 
	 * Actually start the song
	 */
	function startSong()
	{
		FlxG.sound.playMusic(Assets.cache.getSound(songPaths[1]));
		voicesSound = FlxG.sound.play(Assets.cache.getSound(songPaths[2]));
		countingDown = false;
	}

	function hitBehaviour()
	{
		voicesSound.volume = 1.0;
	}

	/** 
	 * Do stuffs when missing a note
	 */
	function missBehaviour(decreaseHealth:Bool = true)
	{
		voicesSound.volume = 0.0;

		/* Random miss sound from 1 to 3 */
		var random:Int = Std.random(3) + 1;
		FlxG.sound.play(AssetHelper.getAsset("missnote" + random + ".ogg", SOUND), 0.2);
	}

	/** 
	 * Quit PlayState
	 */
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
