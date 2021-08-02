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
		if ((beat % 2) == 0)
			gf.playAnim("danceLeft", true);
		else
			gf.playAnim("danceRight", true);

		enemy.playAnim("idle", true);
		player.playAnim("idle", true);

		if (scriptHelper.getVar("_onBeat") != null)
			scriptHelper.getVar("_onBeat")(beat);
	}

	function addKeyCharacter(who:String, x:Int, y:Int, scrollX:Float = 1.0, scrollY:Float = 1.0):Bool
	{
		switch (who)
		{
			case "gf":
				gf = new Character(x, y, characters[2]);
				gf.scrollFactor.set(scrollX, scrollY);
				add(gf);
				gf.animation.play("danceLeft");
				scriptHelper.setVar("gf", gf);
			case "enemy":
				enemy = new Character(x, y, characters[0]);
				enemy.scrollFactor.set(scrollX, scrollY);
				add(enemy);
				enemy.animation.play("idle");
				scriptHelper.setVar("enemy", enemy);
			case "player":
				player = new Character(x, y, characters[1]);
				player.scrollFactor.set(scrollX, scrollY);
				add(player);
				player.animation.play("idle");
				scriptHelper.setVar("player", player);
			default:
				scriptHelper.scriptTrace("Error! Valid key characters are: gf, enemy, player");
				return false;
		}

		return true;
	}
}
