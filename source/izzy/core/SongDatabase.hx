package izzy.core;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

@:enum abstract Difficulty(String) to String
{
	var EASY = "easy";
	var NORMAL = "normal";
	var HARD = "hard";
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

typedef SongPaths = 
{
	var inst:String;
	var voices:String;
	var chart:String;
	var modchart:String;
}

class SongDatabase
{
	public static var weeks:Array<Week>;
	public static var songs:Array<SongMetadata> = [];

	public static function updateWeekList():Bool
	{
		if (FileSystem.exists(AssetHelper.getDataPath("weeks.json", ROOT)))
		{
			weeks = Json.parse(File.getContent(AssetHelper.getDataPath("weeks.json", ROOT)));
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

	public static function getSongPaths(song:String, difficulty:Difficulty = NORMAL):SongPaths
	{
		var dir:String = "songs/" + song + "/";

		var songPaths:SongPaths = {
			inst: "",
			voices: "",
			chart: "",
			modchart: ""
		}

		songPaths.inst = dir + "Inst.ogg";
		if (!FileSystem.exists(songPaths.inst))
			songPaths.inst = "";
		
		songPaths.voices = dir + "Voices.ogg";
		if (!FileSystem.exists(songPaths.voices))
			songPaths.voices = "";

		songPaths.chart = dir + "songChart.json";
		if (!FileSystem.exists("./" + songPaths.chart))
		{
			songPaths.chart = dir + difficulty + ".json";
			if (!FileSystem.exists("./" + songPaths.chart))
				songPaths.chart = "";
		}

		songPaths.modchart = dir + "modchart.hscript";
		if (!FileSystem.exists(songPaths.modchart))
			songPaths.modchart = "";

		trace(songPaths);
		return songPaths;
	}
}
