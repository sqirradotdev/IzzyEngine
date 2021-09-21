package izzy.core;

import haxe.Json;
import haxe.macro.Type.AnonType;
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;

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
	var noteStyle:String;
}

class SongDatabase
{
	public static var weeks:Array<Week>;
	public static var songs:Array<SongMetadata> = [];

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

		trace("Week list updated");

		return true;
	}

	public static function updateSongList()
	{
		for (week in weeks)
		{
			for (song in week.songs)
			{
				var songMetadata:SongMetadata = getSongMetadata(song);
				songs.push(songMetadata);
			}
		}

		trace("Song list updated");
	}

	public static function getSongMetadata(song:String):SongMetadata
	{
		var dir:String = "songs/" + song + "/";
		var path:String = dir + "songMetadata.json";
		var songMetadata:SongMetadata = {
			songName: "",
			bpm: 100,
			characters: ["dad", "bf", "gf"],
			stage: "stage",
			noteStyle: "default"
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

		return songMetadata;
	}

	public static function getSongPaths(song:String, difficulty:Difficulty = NORMAL):Array<String>
	{
		var dir:String = "songs/" + song + "/";
		var chartPath:String = "";
		var instPath:String = "";
		var voicesPath:String = "";

		switch (difficulty)
		{
			case EASY:
				chartPath = dir + "easy";
			case NORMAL:
				chartPath = dir + "normal";
			case HARD:
				chartPath = dir + "hard";
		}

		if (FileSystem.exists("./" + chartPath + ".json"))
			chartPath += ".json";
		else if (FileSystem.exists("./" + chartPath + ".chart"))
			chartPath += ".chart";
		else
			chartPath = "";

		if (FileSystem.exists("./" + dir + "Inst.ogg"))
			instPath = dir + "Inst.ogg";
		if (FileSystem.exists("./" + dir + "Voices.ogg"))
			voicesPath = dir + "Voices.ogg";

		return [chartPath, instPath, voicesPath];
	}
}
