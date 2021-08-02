package;

import flixel.FlxG;

/**
 * Class that holds common functions used throughout the game.
 */
class Util
{
	public static function openUrl(url:String)
	{
		#if linux
		Sys.command("/usr/bin/xdg-open " + url + " &");
		#else
		FlxG.openURL(url);
		#end
	}
}
