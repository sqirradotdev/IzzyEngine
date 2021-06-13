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

typedef SongMetadata =
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

	public static function updateWeekList():Bool
	{
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

		return true;
	}

	public static function getSongs():Array<Array<Dynamic>>
	{
		var songs:Array<Array<Dynamic>> = [];

		for (week in weeks)
		{
			for (song in week.songs)
			{
				var dir:String = "songs/" + song + "/";
				var path:String = dir + "songMetadata.json";
				var songMetadata:SongMetadata = {
					songName: "",
					bpm: 100,
					characters: ["dad", "bf"],
					stage: "stage"
				};

				if (FileSystem.exists(path))
					songMetadata = Json.parse(File.getContent(path));
				else
				{
					trace("Song metadata file for \"" + song + "\" is missing. Creating one");
					songMetadata.songName = song;

					if (!FileSystem.exists(dir))
						FileSystem.createDirectory(dir);

					File.saveContent(path, Json.stringify(songMetadata, "\t"));
				}

				songs.push([song, week.storyMenuCharacters[0], songMetadata.bpm]);
			}
		}

		return songs;
	}
}
