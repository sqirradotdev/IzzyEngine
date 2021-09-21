package izzy.core;

import flixel.FlxG;

/**
 * Class that holds common functions used throughout the game.
 */
class Util
{
	/**
	 * Opens a URL, platform dependent.
	 * @param url The URL to open.
	 */
	public static function openUrl(url:String)
	{
		#if linux
		Sys.command("/usr/bin/xdg-open " + url + " &");
		#else
		FlxG.openURL(url);
		#end
	}
	
	/**
	 * Returns ordinal numbers (1st, 2nd, 3rd, etc)
	 * @param number The number to ordinalize.
	 * @return String
	 */
	public static function ordinalizeNumber(number:Int):String
	{		
		// TODO: please finish
		return "";
	}
		
}
