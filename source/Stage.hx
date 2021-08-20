package;

import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

class Stage extends FlxTypedGroup<FlxBasic>
{
	var scriptHelper:ScriptHelper;

	var characters:Array<String>;

	var gf:Character;
	var enemy:Character;
	var player:Character;

	public function new(characters:Array<String>, stage:String)
	{
		super();

		this.characters = characters;

		scriptHelper = new ScriptHelper();

		scriptHelper.setVar("addKeyCharacter", addKeyCharacter);
		scriptHelper.setVar("stage", this);

		scriptHelper.loadScript("./data/stages/" + stage + ".hscript");

		if (scriptHelper.getVar("_create") != null)
			scriptHelper.getVar("_create")();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (scriptHelper.getVar("_update") != null)
			scriptHelper.getVar("_update")(elapsed);
	}

	public function onBeat(beat:Int)
	{
		gf.playIdle(beat);
		enemy.playIdle(beat);
		player.playIdle(beat);

		if (scriptHelper.getVar("_onBeat") != null)
			scriptHelper.getVar("_onBeat")(beat);
	}

	public function onTick(tick:Int)
	{
		if (scriptHelper.getVar("_onTick") != null)
			scriptHelper.getVar("_onTick")(tick);
	}

	function addKeyCharacter(who:String, x:Int, y:Int, scrollX:Float = 1.0, scrollY:Float = 1.0):Bool
	{
		switch (who)
		{
			case "gf":
				gf = new Character(x, y, characters[2]);
				gf.scrollFactor.set(scrollX, scrollY);
				add(gf);
				gf.playIdle(0);
				scriptHelper.setVar("gf", gf);
			case "enemy":
				enemy = new Character(x, y, characters[0]);
				enemy.scrollFactor.set(scrollX, scrollY);
				add(enemy);
				enemy.playIdle(0);
				scriptHelper.setVar("enemy", enemy);
			case "player":
				player = new Character(x, y, characters[1]);
				player.scrollFactor.set(scrollX, scrollY);
				add(player);
				player.playIdle(0);
				scriptHelper.setVar("player", player);
			default:
				scriptHelper.scriptTrace("Error! Valid key characters are: gf, enemy, player");
				return false;
		}

		return true;
	}
}
