package izzy.scripting;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import haxe.Exception;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import izzy.core.AssetHelper;
import izzy.core.Conductor;
import openfl.display.GraphicsShader;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;

class ScriptHelper
{
    public var expose:StringMap<Dynamic>;
	
	var parser:Parser;
    var interp:Interp;

    var ast:Expr;
    
    public function new()
    {        
        parser = new Parser();
        interp = new Interp();

        parser.allowTypes = true;

		expose = 
		[
			"Sys" => Sys,
			"Std" => Std,
			"Math" => Math,
			"StringTools" => StringTools,
			"FlxMath" => FlxMath,
			"Conductor" => Conductor,
			
			"loadModule" => loadModule,
			"createSprite" => createSprite,
			"getGraphic" => getGraphic,
			"playSound" => playSound,
			"lazyPlaySound" => lazyPlaySound,
			"createTimer" => createTimer,
			"createShader" => createShader,
			"createShaderFilter" => createShaderFilter,

			"getSparrowAtlas" => AssetHelper.getSparrowAtlas
		];
    }

    public function get(field:String):Dynamic
        return interp.variables.get(field);

    public function set(field:String, value:Dynamic)
        interp.variables.set(field, value);

    public function exists(field:String):Bool
        return interp.variables.exists(field);

    public function loadScript(path:String, execute:Bool = true)
    {
        if (path != "")
        {
            if (FileSystem.exists(path))
            {
                try
                {
                    ast = parser.parseString(File.getContent(path), path);
					
					for (v in expose.keys())
						interp.variables.set(v, expose.get(v));
					
                    if (execute)
                        interp.execute(ast);
                }
                catch (e:Error)
                {
                    throw new Exception("Script parse error:\n" + e);
                }
            }
            else
            {
                throw new Exception("Cannot locate script file in " + path);
            }
        }
        else
        {
            throw new Exception("Path is empty!");
        }
    }

	function loadModule(path:String):Dynamic
	{
		if (path != "")
		{
			if (FileSystem.exists(path))
			{
				try
				{
					var moduleInterp = new Interp();
					var moduleAst = parser.parseString(File.getContent(path), path);

					for (v in expose.keys())
						moduleInterp.variables.set(v, expose.get(v));

					moduleInterp.execute(moduleAst);

					var module:Dynamic = {};

					for (v in moduleInterp.variables.keys())
					{
						switch (v)
						{
							case "null", "true", "false", "trace": {/* Does nothing */}
							default:
								Reflect.setField(module, v, moduleInterp.variables.get(v));
						}
					}

					return module;
				}
				catch (e:Error)
				{
					throw new Exception("Module parse error:\n" + e);
				}
			}
			else
			{
				throw new Exception("Cannot locate module file in " + path);
			}
		}
		else
		{
			throw new Exception("Path is empty!");
		}
	}

	function createSprite(x:Float, y:Float):FlxSprite
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

	function createShader(path:String):GraphicsShader
	{
		return new GraphicsShader("", File.getContent(path));
	}
	
	function createShaderFilter(shader:Shader):ShaderFilter
	{
		return new ShaderFilter(shader);
	}
}