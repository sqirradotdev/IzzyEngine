package;

import ChartReader.ChartData;
import ChartReader.NoteData;
import GameplayUI.NoteObject;
import GameplayUI.NoteStyle;
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
import haxe.Json;
import haxe.macro.Type.AnonType;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;

enum Mode
{
	STORY;
	FREEPLAY;
}

@:enum abstract Judgement(String) to String
{
	var SICK = "sick";
	var GOOD = "good";
	var BAD = "bad";
	var SHIT = "shit";
	var MISS = "miss";
}

typedef GameplayConfig =
{
	var noteHoldTolerance:Float;
	var timeWindow:TimeWindow;
}

typedef TimeWindow =
{
	var sick:Float;
	var good:Float;
	var bad:Float;
	var shit:Float;
}

class PlayState extends MusicBeatState
{
	/* Information on what's currently playing right now */
	var currentSong:SongMetadata;
	var currentWeek:Int;
	var currentDifficulty:Difficulty = NORMAL;
	var currentMode:Mode = FREEPLAY;
	var songPaths:Array<String>;

	var gameplayConfig:GameplayConfig;

	var countingDown:Bool = false;

	var chartData:ChartData;
	var currentEnemyNoteHold:Array<NoteData> = [];
	var currentPlayerNoteHold:Array<NoteData> = [];

	var prevInput:Array<Bool>;

	var stageCamera:FlxCamera;
	var uiCamera:FlxCamera;

	var stage:Stage;
	var stageCameraFollow:FlxObject;

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

		NoteStyle.loadNoteStyle(currentSong.noteStyle, true);

		getGameplayConfig();
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

		stage = new Stage(currentSong.characters, currentSong.stage);
		add(stage);

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
			FlxG.keys.pressed.D,
			FlxG.keys.pressed.F,
			FlxG.keys.pressed.J,
			FlxG.keys.pressed.K
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
								var hitTime:Float = chartData.playerNotes[noteIndex].time - Conductor.time;
								/* Check if it's in a hit window (the lowest judgement) */
								if (hitTime < gameplayConfig.timeWindow.shit)
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

									hitBehaviour(hitTime);

									var msHitTime:Int = Math.floor(hitTime * 1000);
									trace("Hit: " + msHitTime + " ms");
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
			var strumIndex:Int = chartData.enemyNotes[enemyNoteIndex].strumIndex;
			var noteObject:NoteObject = enemyStrumLine.getNote(strumIndex, chartData.enemyNotes[0].time);

			if (chartData.enemyNotes[enemyNoteIndex].holdTime == 0.0)
			{
				enemyStrumLine.removeNote(strumIndex, chartData.enemyNotes[enemyNoteIndex].time);
				chartData.enemyNotes.remove(chartData.enemyNotes[enemyNoteIndex]);

				enemyStrumLine.playStrumAnim(strumIndex, "hit");

				new FlxTimer().start(0.1, function(_:FlxTimer)
				{
					enemyStrumLine.playStrumAnim(strumIndex, "idle");
				});
			}
			else
			{
				enemyStrumLine.playStrumAnim(strumIndex, "hit");

				if (noteObject != null)
				{
					noteObject.arrow.visible = false;
					noteObject.holdProgress = Conductor.interpTime - noteObject.time;
					if (noteObject.holdProgress > noteObject.holdTime)
					{
						enemyStrumLine.playStrumAnim(strumIndex, "idle");

						enemyStrumLine.removeNote(strumIndex, chartData.enemyNotes[enemyNoteIndex].time);
						chartData.enemyNotes.remove(chartData.enemyNotes[enemyNoteIndex]);
					}
				}
			}

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

		stage.onBeat(Conductor.beat);
	}

	function getGameplayConfig()
	{
		var path:String = "./data/gameplay.json";

		if (FileSystem.exists(path))
			gameplayConfig = Json.parse(File.getContent(path));
		else
		{
			trace("gameplay.json not found! Creating one.");

			gameplayConfig = {
				noteHoldTolerance: 0.1,
				timeWindow: {
					sick: 0.025,
					good: 0.05,
					bad: 0.75,
					shit: 0.1
				}
			}

			File.saveContent(path, Json.stringify(gameplayConfig, "\t"));
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
	}

	/** 
	 * Start the song countdown
	 */
	function startCountDown()
	{
		Conductor.time = -((60.0 / Conductor.bpm) * 5);

		new FlxTimer().start(0.25, function(_:FlxTimer)
		{
			countDownTimer = new FlxTimer();
			countingDown = true;
			countDownTimer.start((60.0 / Conductor.bpm) * 4, function(__:FlxTimer)
			{
				startSong();
			});
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

	function pushJudgement(judgement:Judgement)
	{
		switch (judgement)
		{
			case SICK:
				trace("SICK");
			case GOOD:
				trace("GOOD");
			case BAD:
				trace("BAD");
			case SHIT:
				trace("SHIT");
			case MISS:
				trace("MISS");
		}
	}

	/** 
	 * Do stuffs when succesfully hitting a note
	 */
	function hitBehaviour(hitTime:Float)
	{
		hitTime = Math.abs(hitTime);
		var judgement:Judgement = SHIT;

		/* Process judgements */
		if (hitTime >= 0.0 && hitTime < gameplayConfig.timeWindow.sick)
			judgement = SICK;
		else if (hitTime >= gameplayConfig.timeWindow.sick && hitTime < gameplayConfig.timeWindow.good)
			judgement = GOOD;
		else if (hitTime >= gameplayConfig.timeWindow.good && hitTime < gameplayConfig.timeWindow.bad)
			judgement = BAD;
		else if (hitTime >= gameplayConfig.timeWindow.bad && hitTime < gameplayConfig.timeWindow.shit)
			judgement = SHIT;

		pushJudgement(judgement);

		voicesSound.volume = 1.0;
	}

	/** 
	 * Do stuffs when missing a note
	 */
	function missBehaviour(decreaseHealth:Bool = true)
	{
		pushJudgement(MISS);

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
