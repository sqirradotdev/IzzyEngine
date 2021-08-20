package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import haxe.Exception;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;

class ScriptHelper
{
	static var parser:Parser = new Parser();

	public var interp:Interp;
	public var ast:Expr;

	public function new()
	{
		interp = new Interp();

		interp.variables.set("trace", scriptTrace);
		interp.variables.set("Std", Std);
		interp.variables.set("Math", Math);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("Conductor", Conductor);
		interp.variables.set("makeSprite", makeSprite);
		interp.variables.set("getGraphic", getGraphic);
		interp.variables.set("getSparrowAtlas", AssetHelper.getSparrowAtlas);
		interp.variables.set("playSound", playSound);
		interp.variables.set("lazyPlaySound", lazyPlaySound);
	}

	public inline function getVar(name:String):Dynamic
		return interp.variables.get(name);

	public inline function setVar(name:String, val:Dynamic)
		interp.variables.set(name, val);

	public function loadScript(path:String)
	{
		if (FileSystem.exists(path))
		{
			try
			{
				ast = parser.parseString(File.getContent(path));
			}
			catch (e:Error)
			{
				throw new Exception("Syntax error:" + e);
			}
		}
		else
		{
			throw new Exception("Cannot find " + path);
		}

		interp.execute(ast);
	}

	public function scriptTrace(msg:String)
	{
		Sys.println("[script] " + msg);
	}

	function makeSprite(x:Float, y:Float):FlxSprite
	{
		var sprite = new FlxSprite(x, y);
		return sprite;
	}

	function getGraphic(path:String, group:String = "default"):FlxGraphic
	{
		return AssetHelper.getAsset(path, IMAGE, group);
	}

	function playSound(path:String, group:String = "default"):FlxSound
	{
		return FlxG.sound.play(AssetHelper.getAsset(path, SOUND, group));
	}

	function lazyPlaySound(path:String, group:String = "default")
	{
		Thread.create(function()
		{
			FlxG.sound.play(AssetHelper.getAsset(path, SOUND, group));
		});
	}

	function createTimer():FlxTimer
	{
		return new FlxTimer();
	}
}
