package izzy.core;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.AssetType;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;

class AssetHelper
{
	public static function getPath(path:String, type:AssetType, group:String = "default"):String
	{
		switch (type)
		{
			case IMAGE:
				return "assets/" + group + "/images/" + path;
			case SOUND:
				return "assets/" + group + "/sounds/" + path;
			case MUSIC:
				return "assets/" + group + "/music/" + path;
			default:
				return "";
		}
	}

	public static function getAsset(path:String, type:AssetType, group:String = "default"):Dynamic
	{
		var actualPath:String = getPath(path, type, group);

		if (FileSystem.exists(actualPath)) // Check if it exists in the FileSystem (desktop only)
		{
			if (FlxG.bitmap.checkCache(actualPath) || Assets.cache.hasSound(actualPath)) // Check if it exists in the AssetCache library
			{
				/* #if debug
					trace(type + " asset from cache: " + actualPath);
					#end */

				switch (type)
				{
					case IMAGE:
						return FlxG.bitmap.get(actualPath);
					case SOUND, MUSIC:
						return Assets.cache.getSound(actualPath);
					default:
						return null;
				}
			}
			else if (Assets.exists(actualPath)) // Check if it exists in the embedded assets library
			{
				/* #if debug
					trace(type + " asset from ID: " + actualPath);
					#end */

				switch (type)
				{
					case IMAGE:
						return FlxGraphic.fromAssetKey(actualPath);
					case SOUND:
						return Assets.getSound(actualPath);
					case MUSIC:
						return Assets.getMusic(actualPath);
					default:
						return null;
				}
			}
			else // If not, load it manually from file.
			{
				/* #if debug
					trace(type + " asset from file: " + actualPath);
					#end */

				actualPath = "./" + actualPath; // Relative path
				switch (type)
				{
					case IMAGE:
						return FlxGraphic.fromBitmapData(BitmapData.fromFile(actualPath));
					case SOUND, MUSIC:
						if (!Assets.cache.hasSound(actualPath))
						{
							var sound:Sound = Sound.fromFile(actualPath);
							Assets.cache.setSound(actualPath, sound);
						}
						return Assets.cache.getSound(actualPath);
					default:
						return null;
				}
			}
		}

		return null;
	}

	public static function getSparrowAtlas(path:String, group:String = "default"):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(getAsset(path + ".png", IMAGE, group), File.getContent(getPath(path + ".xml", IMAGE, group)));
	}
}
