package izzy.state;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import izzy.core.AssetHelper;
import izzy.core.ChartParser;
import izzy.core.Conductor;
import izzy.core.SongDatabase;
import izzy.gameplay.Stage;
import izzy.state.base.MusicBeatState;
import izzy.ui.GameplayUI;
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;

enum Mode
{
	STORY;
	FREEPLAY;
	CHARTER;
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

enum GameplayEvents
{
	ChangeCamera(whose:Int);
	PlayCharacterAnim(whose:Int, name:String, force:Bool, supressDuration:Int);
	SetCharacterSingSuffix(whose:Int, suffix:Null<String>);
	SetCharacterIdleSuffix(whose:Int, suffix:Null<String>);
}

class PlayState extends MusicBeatState
{
	// Information on what's currently playing right now
	var currentSong:SongMetadata;
	var currentWeek:Int;
	var currentDifficulty:Difficulty = NORMAL;
	var currentMode:Mode = FREEPLAY;
	var songPaths:Array<String>;
	var gameplayConfig:GameplayConfig;

	var inst:Sound;
	var voices:Sound;

	var paused:Bool = false;
	var countingDown:Bool = false;

	var chartData:ChartData;
	var currentEnemyNoteHold:Array<NoteData> = [];
	var currentPlayerNoteHold:Array<NoteData> = [];

	var prevInput:Array<Bool>;

	var stageCamera:FlxCamera;
	var uiCamera:FlxCamera;
	var charterCamera:FlxCamera;

	var stage:Stage;
	var stageCameraFollow:FlxObject;

	var enemyStrumLine:StrumLine;
	var playerStrumLine:StrumLine;

	var voicesObject:FlxSound;

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
				// TODO: Add story mode loadin	
				currentWeek = week;
			case FREEPLAY:
				currentSong = SongDatabase.getSongMetadata(song);
			case CHARTER:
				transOut = null;
		}
	}

	override public function create()
	{
		super.create();
		persistentUpdate = true;

		NoteStyle.loadNoteStyle(currentSong.noteStyle);

		getGameplayConfig();
		getChartData();
		getSongAudio();

		Conductor.time = -((60.0 / Conductor.bpm) * 5);

		// Cache sounds to prevent hiccups
		AssetHelper.getAsset("intro3.ogg", SOUND);
		AssetHelper.getAsset("intro2.ogg", SOUND);
		AssetHelper.getAsset("intro1.ogg", SOUND);
		AssetHelper.getAsset("introGo.ogg", SOUND);

		AssetHelper.getAsset("missnote1.ogg", SOUND);
		AssetHelper.getAsset("missnote2.ogg", SOUND);
		AssetHelper.getAsset("missnote3.ogg", SOUND);

		stageCamera = FlxG.camera;
		stageCamera.zoom = 1.05;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.add(uiCamera, false);

		charterCamera = new FlxCamera();
		charterCamera.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.add(charterCamera, false);

		stage = new Stage(currentSong.stage, currentSong.characters, this);
		add(stage);

		stageCameraFollow = new FlxObject(0, 0);
		add(stageCameraFollow);

		stageCamera.follow(stageCameraFollow, LOCKON);

		// Get the first ChangeCamera gameplay event
		for (eventStruct in chartData.gameplayEvents)
		{
			if (Type.enumIndex(eventStruct.type) == Type.enumIndex(ChangeCamera(0)))
			{
				processGameplayEvent(chartData.gameplayEvents[0].type);
				break;
			}
		}

		enemyStrumLine = new StrumLine(265, 50, 1.0, chartData.noteSpeed);
		enemyStrumLine.camera = uiCamera;
		enemyStrumLine.time = -50;
		add(enemyStrumLine);

		playerStrumLine = new StrumLine(950, 50, 1.0, chartData.noteSpeed);
		playerStrumLine.camera = uiCamera;
		playerStrumLine.time = -50;
		add(playerStrumLine);

		for (noteData in chartData.enemyNotes)
			enemyStrumLine.addNote(noteData.strumIndex, noteData.time, noteData.holdTime);

		for (noteData in chartData.playerNotes)
			playerStrumLine.addNote(noteData.strumIndex, noteData.time, noteData.holdTime);

		// woah
		// what if you just leave this in the code no context -shubs
		// :troll:

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

		stageCamera.followLerp = elapsed;

		var input:Array<Bool> = [
			FlxG.keys.pressed.D,
			FlxG.keys.pressed.F,
			FlxG.keys.pressed.J,
			FlxG.keys.pressed.K
		];

		if (!paused)
		{
			// Player input handling
			for (i in 0...input.length)
			{
				// If an input was pressed
				if (input[i])
				{
					// Check if prevInput is not null
					if (prevInput != null)
					{
						// Check if it's just pressed once
						if (input[i] != prevInput[i])
						{
							var noteIndex:Int = 0;

							/* Do a while loop until there's no note left */
							while (chartData.playerNotes[noteIndex] != null)
							{
								// If the note matches strumIndex with the current input
								if (chartData.playerNotes[noteIndex].strumIndex == i)
								{
									var hitTime:Float = chartData.playerNotes[noteIndex].time - Conductor.time;
									// Check if it's in a hit window (the lowest judgement)
									if (hitTime < gameplayConfig.timeWindow.shit)
									{
										// Remove note if there's no note
										if (chartData.playerNotes[noteIndex].holdTime == 0.0)
										{
											playerStrumLine.removeNote(i, chartData.playerNotes[noteIndex].time);
											stage.player.playSingAnim(i);
										}
										// Do additional steps for note hold
										else
										{
											playerStrumLine.getNote(i, chartData.playerNotes[noteIndex].time).arrow.visible = false;
											currentPlayerNoteHold.push(chartData.playerNotes[noteIndex]);
										}

										chartData.playerNotes.remove(chartData.playerNotes[noteIndex]);
										hitBehaviour(hitTime);

										// Play a glowing hit animation
										if (playerStrumLine.getCurrentStrumAnim(i).name != "hit")
											playerStrumLine.playStrumAnim(i, "hit", true);
									}
									// Break while loop because it found the note it wants
									break;
								}
								// If not, go to next note
								else
									noteIndex++;
							}

							if (playerStrumLine.getCurrentStrumAnim(i).name != "hit")
								playerStrumLine.playStrumAnim(i, "pressed", true);
						}
					}
				}
				if (playerStrumLine.getCurrentStrumAnim(i).name != "idle" && playerStrumLine.getCurrentStrumAnim(i).finished)
					playerStrumLine.playStrumAnim(i, "idle");
			}

			// Player note miss
			while (chartData.playerNotes[0] != null && chartData.playerNotes[0].time - Conductor.time < -gameplayConfig.timeWindow.shit)
			{
				trace("Miss note time " + chartData.playerNotes[0].time);

				playerStrumLine.invalidateNote(chartData.playerNotes[0].strumIndex, chartData.playerNotes[0].time);
				stage.player.playMissAnim(chartData.playerNotes[0].strumIndex);
				chartData.playerNotes.shift();
				missBehaviour();
			}

			// Note holds
			for (note in currentPlayerNoteHold)
			{		
				var holdProgress:Float = Conductor.time - note.time;
				var noteObject:NoteObject = playerStrumLine.getNote(note.strumIndex, note.time);

				stage.player.playSingAnim(noteObject.strumIndex, "", false);

				noteObject.holdProgress = Conductor.interpTime - note.time;

				if (!input[note.strumIndex])
				{
					playerStrumLine.invalidateNote(note.strumIndex, note.time);
					noteObject.arrow.visible = true;
					currentPlayerNoteHold.remove(note);
					stage.player.playMissAnim(note.strumIndex);
					missBehaviour(false);
				}
				if (holdProgress > note.holdTime)
				{
					currentPlayerNoteHold.remove(note);
					playerStrumLine.removeNote(note.strumIndex, note.time);

					playerStrumLine.playStrumAnim(note.strumIndex, "idle");
				}
				else
				{
					playerStrumLine.playStrumAnim(note.strumIndex, "hit");
				}
			}

			prevInput = input;

			// Enemy autoplay
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
					stage.getCharacterByIndex(0).playSingAnim(strumIndex);

					new FlxTimer().start(0.1, function(_:FlxTimer)
					{
						enemyStrumLine.playStrumAnim(strumIndex, "idle");
					});
				}
				else
				{
					enemyStrumLine.playStrumAnim(strumIndex, "hit");
					stage.getCharacterByIndex(0).playSingAnim(strumIndex, "", false);

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

				if (voicesObject != null)
					voicesObject.volume = 1.0;

				enemyNoteIndex++;
			}
		}
			
		// Update strum line time based on Conductor time
		if (FlxG.sound.music.playing || countingDown || currentMode == CHARTER)
		{
			enemyStrumLine.time = Conductor.interpTime;
			playerStrumLine.time = Conductor.interpTime;
		}

		// Disable keys when charter mode is on
		if (subState == null || currentMode != CHARTER)
		{
			if (FlxG.keys.pressed.SEVEN)
			{
				transIn = null;
				toCharterMode();
			}

			if (FlxG.keys.justPressed.ESCAPE)
			{
				quit();
			}
		}
	}

	override function onBeat(beat:Int):Void
	{
		if (countingDown)
		{
			switch (beat)
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

		// Resync the vocals
		if (voicesObject != null && voicesObject.playing && FlxG.sound.music.playing)
		{
			var delta:Float = voicesObject.time - FlxG.sound.music.time;
			if (Math.abs(delta) >= 5)
			{
				trace("Delta is " + delta + ", resyncing");
				voicesObject.time = FlxG.sound.music.time;
			}
		}

		stage.onBeat(beat);
	}

	override function onTick(tick:Int):Void
	{
		if (chartData != null && chartData.gameplayEvents != null)
		{		
			while (chartData.gameplayEvents.length > 0 && chartData.gameplayEvents[0].tick <= tick)
			{
				processGameplayEvent(chartData.gameplayEvents[0].type);
				chartData.gameplayEvents.shift();
			}
		}

		stage.onTick(tick);
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

		chartData = izzy.core.ChartParser.readChart(songPaths[0]);
		
		chartData.enemyNotes.sort((a, b) -> Std.int(a.time * 100) - Std.int(b.time * 100));
		chartData.playerNotes.sort((a, b) -> Std.int(a.time * 100) - Std.int(b.time * 100));

		Conductor.bpm = currentSong.bpm;
	}

	/** 
	 * Prepare the song's audio files
	 */
	function getSongAudio()
	{
		inst = Sound.fromFile("./" + songPaths[1]);
		if (songPaths[2] != "")
			voices = Sound.fromFile("./" + songPaths[2]);
	}

	/** 
	 * Start song countdown
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
		});
	}

	/** 
	 * Actually start the song
	 */
	function startSong()
	{
		if (countDownTimer != null)
		{
			countDownTimer.cancel();
			countDownTimer.destroy();
			countDownTimer = null;
		}
		
		FlxG.sound.playMusic(inst, 1, false);
		FlxG.sound.music.onComplete = endSong;

		if (voices != null)
			voicesObject = FlxG.sound.play(voices);

		countingDown = false;
	}

	/** 
	 * Set of instructions to run when the song is over
	 */
	function endSong()
	{
		FreeplayState.firstTime = false;
		if (voicesObject != null)
			voicesObject.volume = 0;
		quit();
	}

	/** 
	 * Process gameplay event, used in onTick to process upcoming events on a tick.
	 */
	function processGameplayEvent(event:GameplayEvents)
	{	
		switch (event)
		{
			case ChangeCamera(whose):
				var point:FlxPoint = stage.getCharacterByIndex(whose).getCameraMidpoint();
				stageCameraFollow.setPosition(point.x, point.y);
			case PlayCharacterAnim(whose, name, force, supressDuration):
				stage.getCharacterByIndex(whose).playAnim(name, force, supressDuration);
			case SetCharacterIdleSuffix(whose, suffix):
				stage.getCharacterByIndex(whose).idleSuffix = suffix;
			case SetCharacterSingSuffix(whose, suffix):
				stage.getCharacterByIndex(whose).singSuffix = suffix;
			default:
				{}
		}
	}

	/** 
	 * Push out judgements to screen and also record it
	 */
	function pushJudgement(judgement:Judgement)
	{
		// TODO: finish pushJudgement
		
		/* switch (judgement)
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
		} */
	}

	/** 
	 * Set of instructions to run when succesfully hitting a note
	 */
	function hitBehaviour(hitTime:Float)
	{
		hitTime = Math.abs(hitTime);
		var judgement:Judgement = SHIT;

		// Process judgements
		if (hitTime >= 0.0 && hitTime < gameplayConfig.timeWindow.sick)
			judgement = SICK;
		else if (hitTime >= gameplayConfig.timeWindow.sick && hitTime < gameplayConfig.timeWindow.good)
			judgement = GOOD;
		else if (hitTime >= gameplayConfig.timeWindow.good && hitTime < gameplayConfig.timeWindow.bad)
			judgement = BAD;
		else if (hitTime >= gameplayConfig.timeWindow.bad && hitTime < gameplayConfig.timeWindow.shit)
			judgement = SHIT;

		pushJudgement(judgement);

		if (voicesObject != null)
			voicesObject.volume = 1.0;
	}

	/** 
	 * Set of instructions to run when missing a note
	 */
	function missBehaviour(decreaseHealth:Bool = true)
	{
		pushJudgement(MISS);

		if (voicesObject != null)
			voicesObject.volume = 0.0;

		// Random miss sound from 1 to 3
		var random:Int = Std.random(3) + 1;
		FlxG.sound.play(AssetHelper.getAsset("missnote" + random + ".ogg", SOUND), 0.2);
	}

	/** 
	 * Immediately goes to charter
	 */
	function toCharterMode()
	{
		trace("Charter mode enabled.");
		
		currentMode = CHARTER;
		paused = true;

		// Cancel countdown and load the music immediately
		if (countingDown)
			startSong();
		
		FlxG.sound.music.pause();
		FlxG.sound.music.time = 0;
		FlxG.sound.music.onComplete = null;
		FlxG.sound.music.autoDestroy = false;

		if (voicesObject != null)
		{
			voicesObject.pause();
			voicesObject.time = 0;
			voicesObject.autoDestroy = false;
		}

		Conductor.time = 0;
		Conductor.interpTime = 0;

		chartData = null;
		getChartData();

		processGameplayEvent(ChangeCamera(1));
		openSubState(new CharterSubState(charterCamera, this, chartData));
	}

	/** 
	 * Quit PlayState
	 */
	function quit()
	{
		FlxG.sound.music.onComplete = null;

		switch (currentMode)
		{
			case FREEPLAY, CHARTER:
				FlxG.switchState(new FreeplayState());
			case STORY:
				FlxG.switchState(new MainMenuState());
		}
	}
}
