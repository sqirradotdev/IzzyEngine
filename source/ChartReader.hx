package;

import haxe.Json;
import haxe.macro.Type.AnonType;
import sys.io.File;

@:enum abstract VanillaChartType(String) to String
{
	var VANILLA = "vanilla";
	var VANILLA_V2 = "vanilla_v2";
}

typedef ChartData = Array<NoteData>;

typedef NoteData =
{
	var time:Float;
	var holdTime:Float;
	var whoseStrum:Int;
	var whichStrumPart:Int;
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

		// TODO: Make IzzyEngine chart standard
		return null;
	}

	/* 
	 * Vanilla chart reading for the original Funkin game
	 */
	public static function readVanilla(contents:String):ChartData
	{
		var returnArray:Array<NoteData> = [];

		var parsedJson = Json.parse(contents);
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
				var whichStrumPart:Int = sectionNote[1];
				var noteTime:Float = sectionNote[0] / 1000;
				var holdTime:Float = sectionNote[2] / 1000;

				if (whichStrumPart > 3)
				{
					whichStrumPart -= 4;
					whoseStrum = !whoseStrum;
				}

				var whoseStrumIndex:Int = whoseStrum ? 1 : 0;

				returnArray.push({
					time: noteTime,
					holdTime: holdTime,
					whoseStrum: whoseStrumIndex,
					whichStrumPart: whichStrumPart
				});
			}
		}

		return returnArray;
	}
}
