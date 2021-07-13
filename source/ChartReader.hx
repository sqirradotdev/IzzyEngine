package;

import haxe.Json;
import haxe.macro.Type.AnonType;
import sys.io.File;

@:enum abstract VanillaChartType(String) to String
{
	var VANILLA = "vanilla";
	var VANILLA_V2 = "vanilla_v2";
}

typedef ChartData =
{
	var bpm:Int;
	var noteSpeed:Float;
	var enemyNotes:Array<NoteData>;
	var playerNotes:Array<NoteData>;
}

typedef NoteData =
{
	var time:Float;
	var holdTime:Float;
	var whoseStrum:Int;
	var strumIndex:Int;
}

class ChartReader
{
	/*
	 * Helper function that returns chart data based on what type it is
	 */
	public static function readChart(path:String):ChartData
	{
		if (StringTools.endsWith(path, "json"))
		{
			trace("Reading vanilla chart");
			return readVanilla(File.getContent("./" + path));
		}

		// TODO: Make Izzy Engine chart standard
		return null;
	}

	/* 
	 * Vanilla chart reading for the original Funkin game
	 */
	public static function readVanilla(contents:String):ChartData
	{
		var chartData:ChartData = {
			bpm: 0,
			noteSpeed: 1.0,
			enemyNotes: [],
			playerNotes: []
		};

		var parsedJson = Json.parse(contents);

		chartData.noteSpeed = Reflect.field(Reflect.field(parsedJson, "song"), "speed");

		var sectionInformation:Array<AnonType> = Reflect.field(Reflect.field(parsedJson, "song"), "notes");
		for (notes in sectionInformation)
		{
			var mustHitSection:Bool = Reflect.field(notes, "mustHitSection");
			var sectionNotes:Array<Array<Dynamic>> = Reflect.field(notes, "sectionNotes");
			trace(sectionNotes);
			for (sectionNote in sectionNotes)
			{
				// True means player, false means enemy (following mustHitSection)
				var whoseStrum:Bool = mustHitSection;
				var strumIndex:Int = sectionNote[1];
				var noteTime:Float = sectionNote[0] / 1000;
				var holdTime:Float = sectionNote[2] / 1000;

				if (strumIndex > 3)
				{
					strumIndex -= 4;
					whoseStrum = !whoseStrum;
				}

				if (strumIndex < 4)
				{
					var whoseStrumIndex:Int = whoseStrum ? 1 : 0;
					var noteData:NoteData = {
						time: noteTime,
						holdTime: holdTime,
						whoseStrum: whoseStrumIndex,
						strumIndex: strumIndex
					};

					if (whoseStrumIndex == 0)
						chartData.enemyNotes.push(noteData);
					else
						chartData.playerNotes.push(noteData);
				}
			}
		}

		return chartData;
	}
}
