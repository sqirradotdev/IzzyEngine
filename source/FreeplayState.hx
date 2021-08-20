package;

import SongDatabase.Difficulty;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.media.Sound;
import sys.thread.Thread;

class FreeplayState extends MusicBeatState
{
	public static var firstTime:Bool = false;
	static var songSelection:Int = 0;

	var songSelected:Bool = false;
	var backed:Bool = false;

	var lerpedSongSelection:Float = 0;

	var songThread:Thread;

	var bg:FlxSprite;
	var songItems:FlxSpriteGroup;

	public function new()
	{
		super();
		persistentUpdate = true;
	}

	override public function create():Void
	{
		super.create();

		RichPresence.setIdling(FREEPLAY_MENU);

		bg = new FlxSprite().loadGraphic(AssetHelper.getAsset("mainMenu/menuBGBlue.png", IMAGE));
		bg.antialiasing = true;
		add(bg);

		songItems = new FlxSpriteGroup();
		add(songItems);

		for (song in SongDatabase.songs)
		{
			var withSpace:String = StringTools.replace(song.songName, "-", " ");
			var alphabet:Alphabet = new Alphabet(songItems.length * 25, songItems.length * 160, withSpace);
			songItems.add(alphabet);
		}

		changeSongSelection(songSelection);
		if (firstTime)
		{
			// This was on purpose, to give a sense of transition
			// (shamelessly stolen from osu!)
			FlxG.sound.music.volume = 0.2;
			FlxG.sound.music.fadeIn(1.0, 0.2, 1.0);
		}
		else
		{
			changeSongPlaying();
			firstTime = true;
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		bg.scale.x = FlxMath.lerp(bg.scale.x, 1.0, elapsed * 6);
		bg.scale.y = FlxMath.lerp(bg.scale.y, 1.0, elapsed * 6);

		lerpedSongSelection = FlxMath.lerp(lerpedSongSelection, songSelection, elapsed * 6);

		songItems.x = 110 - (lerpedSongSelection * 25);
		songItems.y = (FlxG.height / 2) - 30 - (lerpedSongSelection * 160);

		if (!backed && !songSelected)
		{
			if (FlxG.keys.justPressed.UP)
			{
				changeSongSelection(songSelection - 1);
				changeSongPlaying();
				FlxG.sound.play(AssetHelper.getAsset("scrollMenu.ogg", SOUND));
			}
			if (FlxG.keys.justPressed.DOWN)
			{
				changeSongSelection(songSelection + 1);
				changeSongPlaying();
				FlxG.sound.play(AssetHelper.getAsset("scrollMenu.ogg", SOUND));
			}
			if (FlxG.keys.justPressed.ENTER)
			{
				songSelected = true;

				FlxG.sound.play(AssetHelper.getAsset("confirmMenu.ogg", SOUND));

				for (x in 0...songItems.length)
				{
					if (x == songSelection)
						FlxFlicker.flicker(songItems.members[x], 1, 0.06, false, false, function(flick:FlxFlicker)
						{
							selectSong();
						});
					else
					{
						FlxTween.tween(songItems.members[x], {x: songItems.members[x].x - 400}, 0.4, {ease: FlxEase.backIn});
						FlxTween.tween(songItems.members[x], {alpha: 0.0}, 0.4, {ease: FlxEase.quadIn});
					}
				}
			}
			if (FlxG.keys.justPressed.ESCAPE)
			{
				backed = true;

				FlxG.sound.play(AssetHelper.getAsset("cancelMenu.ogg", SOUND));
				FlxG.switchState(new MainMenuState());
			}
		}
	}

	override function onBeat(beat):Void
	{
		bg.scale.x = 1.015;
		bg.scale.y = 1.015;
	}

	function changeSongSelection(selection:Int = 0)
	{
		songSelection = selection;

		if (songSelection >= SongDatabase.songs.length) // Loop back to first option
			songSelection = 0;
		if (songSelection < 0) // Loop forward to last option
			songSelection = SongDatabase.songs.length - 1;

		for (x in 0...songItems.length)
		{
			if (x == songSelection)
				songItems.members[x].alpha = 1.0;
			else
				songItems.members[x].alpha = 0.6;
		}
	}

	function changeSongPlaying()
	{
		Conductor.bpm = SongDatabase.songs[songSelection].bpm;

		if (songThread == null)
		{
			songThread = Thread.create(function()
			{
				while (!backed && !songSelected)
				{
					var index:Null<Int> = Thread.readMessage(false);
					if (index != null)
					{
						if (index == songSelection)
						{
							var songPaths:Array<String> = SongDatabase.getSongPaths(SongDatabase.songs[songSelection].songName);

							var lastSelection:Int = songSelection;
							var inst:Sound = Sound.fromFile("./" + songPaths[1]);

							if (lastSelection == songSelection && !songSelected)
							{
								FlxG.sound.playMusic(inst);

								if (FlxG.sound.music.fadeTween != null)
									FlxG.sound.music.fadeTween.cancel();

								FlxG.sound.music.volume = 0.0;
								FlxG.sound.music.fadeIn(1.0, 0.0, 1.0);
							}
						}
					}
				}
			});
		}

		songThread.sendMessage(songSelection);
	}

	function selectSong()
	{
		FlxG.sound.music.stop();
		FlxG.switchState(new PlayState(SongDatabase.songs[songSelection].songName, null, HARD, FREEPLAY));
	}
}
