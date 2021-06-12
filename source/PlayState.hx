package;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.text.FlxText;

enum Mode
{
	STORY;
	FREEPLAY;
}

class PlayState extends MusicBeatState
{
	var mode:Mode = FREEPLAY;

	var stageCamera:FlxCamera;
	var uiCamera:FlxCamera;

	var stageCameraFollow:FlxObject;

	var bg:FlxSprite;
	var stageFront:FlxSprite;
	var stageCurtains:FlxSprite;

	var enemy:FlxSprite;
	var gf:FlxSprite;
	var player:FlxSprite;

	public function new()
	{
		super();
		FreeplayState.firstTime = false;
		persistentUpdate = true;
	}

	override public function create()
	{
		super.create();

		stageCamera = new FlxCamera();
		add(stageCamera);

		uiCamera = new FlxCamera();
		add(uiCamera);

		FlxG.cameras.add(stageCamera);
		FlxG.cameras.add(uiCamera);
		FlxG.cameras.setDefaultDrawTarget(stageCamera, true);

		bg = new FlxSprite(-600, -200).loadGraphic(AssetHelper.getAsset("stageback.png", IMAGE, "week1"));
		bg.antialiasing = true;
		bg.scrollFactor.set(0.9, 0.9);
		bg.active = false;
		add(bg);

		stageFront = new FlxSprite(-650, 600).loadGraphic(AssetHelper.getAsset("stagefront.png", IMAGE, "week1"));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = true;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		add(stageFront);

		stageCurtains = new FlxSprite(-500, -300).loadGraphic(AssetHelper.getAsset("stagecurtains.png", IMAGE, "week1"));
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.antialiasing = true;
		stageCurtains.scrollFactor.set(1.3, 1.3);
		stageCurtains.active = false;
		add(stageCurtains);

		gf = new Character(400, 130, "gf");
		gf.scrollFactor.set(0.95, 0.95);
		add(gf);
		gf.animation.play("danceLeft");

		enemy = new Character(100, 100, "dad");
		add(enemy);
		enemy.animation.play("idle");

		player = new Character(770, 450, "bf");
		add(player);
		player.animation.play("idle");
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (subState == null)
		{
			if (FlxG.keys.pressed.SEVEN)
			{
				openSubState(new CharterSubState());
			}
			if (FlxG.keys.justPressed.ESCAPE)
			{
				quit();
			}
		}
	}

	override public function destroy()
	{
		forEach(function(object:FlxBasic)
		{
			object.destroy();
		});

		super.destroy();
	}

	function quit()
	{
		switch (mode)
		{
			case FREEPLAY:
				FlxG.switchState(new FreeplayState());
			case STORY:
				FlxG.switchState(new MainMenuState());
		}
	}
}
