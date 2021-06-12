package;

import haxe.Json;
import lime.utils.Assets;
import sys.io.File;
#if desktop
import sys.FileSystem;
#end

enum Difficulty
{
	EASY;
	NORMAL;
	HARD;
}

typedef Week =
{
	var weekName:String;
	var storyMenuCharacters:Array<String>;
	var weekTagline:String;
	var songs:Array<String>;
}

typedef Song =
{
	var songName:String;
	var bpm:Int;
	var characters:Array<String>;
	var stage:String;
	// var chart:Map<Int, TickData>;
}

class SongDatabase
{
	public static var weeks:Array<Week>;

	public static function updateSongList():Bool
	{
		trace("Updating song database...");

		#if desktop
		if (FileSystem.exists("data/weeks.json"))
		{
			weeks = Json.parse(File.getContent("data/weeks.json"));
			trace(weeks);
		}
		else
		{
			trace("weeks.json is missing!");
			return false;
		}
		#else
		weeks = Json.parse(Assets.getText("data/weeks.json"));
		#end

		return true;
	}

	public static function getSongs():Array<Array<String>>
	{
		var songs:Array<Array<String>> = [];

		for (week in weeks)
		{
			for (song in week.songs)
			{
				songs.push([song, week.storyMenuCharacters[0]]);
			}
		}

		return songs;
	}
}
