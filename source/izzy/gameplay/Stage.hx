package izzy.gameplay;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import izzy.scripting.ScriptHelper;
import izzy.state.PlayState;

@:access(izzy.state.PlayState)
class Stage extends FlxTypedGroup<FlxBasic>
{
	public var gf:Character;
	public var enemy:Character;
	public var player:Character;

	var scriptHelper:ScriptHelper;
	var characters:Array<String>;

	var playState:PlayState;

	public function new(stage:String, characters:Array<String>, state:PlayState)
	{
		super();

		this.characters = characters;
		this.playState = state;

		scriptHelper = new ScriptHelper();

		scriptHelper.expose.set("addEnemy", addEnemy);
		scriptHelper.expose.set("addPlayer", addPlayer);
		scriptHelper.expose.set("addGf", addGf);
		scriptHelper.expose.set("stage", this);
		scriptHelper.expose.set("stageCamera", playState.stageCamera);
		scriptHelper.expose.set("uiCamera", playState.uiCamera);

		scriptHelper.loadScript("./data/stages/" + stage + ".hscript");

		if (scriptHelper.get("onCreate") != null)
			scriptHelper.get("onCreate")();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (scriptHelper.get("onUpdate") != null)
			scriptHelper.get("onUpdate")(elapsed);
	}

	public function onBeat(beat:Int)
	{
		if (gf != null)
			gf.playIdle(beat);
		if (enemy != null)
			enemy.playIdle(beat);
		
		player.playIdle(beat);

		if (scriptHelper.get("onBeat") != null)
			scriptHelper.get("onBeat")(beat);
	}

	public function onTick(tick:Int)
	{
		if (scriptHelper.get("onTick") != null)
			scriptHelper.get("onTick")(tick);
	}

	function addKeyCharacter(whoId:Int, x:Int, y:Int, scrollX:Float = 1.0, scrollY:Float = 1.0):Bool
	{
		var who:String = "";
		
		switch (whoId)
		{
			case 0:
				who = "enemy";
			case 1:
				who = "player";
			case 2:
				who = "gf";
			default:
				trace("Character index out of range");
				return false;
		}

		var character:Character = new Character(x, y, characters[whoId]);
		character.scrollFactor.set(scrollX, scrollY);
		add(character);
		character.playIdle(0);
		scriptHelper.set(who, character);
		Reflect.setField(this, who, character);

		return true;
	}
	
	function addEnemy(x:Int, y:Int, scrollX:Float = 1.0, scrollY:Float = 1.0):Bool
		return addKeyCharacter(0, x, y, scrollX, scrollY);

	function addPlayer(x:Int, y:Int, scrollX:Float = 1.0, scrollY:Float = 1.0):Bool
		return addKeyCharacter(1, x, y, scrollX, scrollY);
	
	function addGf(x:Int, y:Int, scrollX:Float = 1.0, scrollY:Float = 1.0):Bool
		return addKeyCharacter(2, x, y, scrollX, scrollY);

	public function getCharacterByIndex(whose:Int):Character
	{
		switch (whose)
		{
			case 0:
				return enemy != null ? enemy : gf;
			case 1:
				return player;
			case 2:
				return gf;
			default:
				return null;
		}

		return null;
	}
}
