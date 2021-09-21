package izzy.state;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import izzy.core.AssetHelper;
import izzy.core.ChartParser.ChartData;
import izzy.core.Conductor;
import izzy.ui.CharterUI;

typedef SnapStruct = 
{
	var snap:Int;
	var color:FlxColor;
}

/**
 * Charter substate, meant to be used in PlayState.
 * Try not to use this on other states. (I mean, why would you)
 */
@:access(izzy.state.PlayState)
class CharterSubState extends FlxSubState
{		
	static final snaps:Array<SnapStruct> = 
	[
		{ snap: 4,   color: FlxColor.RED    },
		{ snap: 8,   color: FlxColor.BLUE   },
		{ snap: 12,  color: FlxColor.PURPLE },
		{ snap: 16,  color: FlxColor.YELLOW },
		{ snap: 20,  color: FlxColor.GRAY   },
		{ snap: 24,  color: FlxColor.PINK   },
		{ snap: 32,  color: FlxColor.ORANGE },
		{ snap: 48,  color: FlxColor.CYAN   },
		{ snap: 64,  color: FlxColor.GREEN  },
		{ snap: 96,  color: FlxColor.GRAY   },
		{ snap: 192, color: FlxColor.GRAY   }
	];
	
	var chartData:ChartData;
	
	var currentSnapIndex:Int = 0;
	var currentZoom:Float = 1.0;

	var psInstance:PlayState;

	var bg:FlxSprite;
	var ref:FlxSprite;
	var charterArea:CharterArea;
	var statusBar:StatusBar;
	
	public function new(camera:FlxCamera, instance:PlayState, chartData:ChartData)
	{
		super();
		this.camera = camera;
		this.psInstance = instance;
		this.chartData = Reflect.copy(chartData);

		FlxG.mouse.visible = true;
	}

	override public function create():Void
	{
		psInstance.stageCamera.visible = false;
		psInstance.uiCamera.visible = false;
		
		bg = new FlxSprite().loadGraphic(AssetHelper.getAsset("charter/bg.png", IMAGE));
		bg.antialiasing = true;
		add(bg);

		ref = new FlxSprite().loadGraphic(AssetHelper.getAsset("charter/ref.png", IMAGE));
		//ref.alpha = 0.5;
		ref.visible = false;
		add(ref);

		charterArea = new CharterArea();
		charterArea.makeArrows(chartData.enemyNotes);
		charterArea.makeArrows(chartData.playerNotes);
		charterArea.camera = camera;
		add(charterArea);

		statusBar = new StatusBar();
		add(statusBar);

		setSnap(currentSnapIndex);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		charterArea.currentTime = Conductor.time;
		charterArea.currentBeat = Conductor.getBeat(Conductor.time);
		charterArea.currentTick = Conductor.getTick(Conductor.time);

		/* --- TIMELINE NAVIGATION KEYS --- */
		
		if (FlxG.keys.justPressed.UP || (FlxG.mouse.wheel > 0 && !FlxG.keys.pressed.CONTROL))
		{
			togglePlay(false);
			snapToNearest(true);
		}
		if (FlxG.keys.justPressed.DOWN || (FlxG.mouse.wheel < 0 && !FlxG.keys.pressed.CONTROL))
		{
			togglePlay(false);
			snapToNearest(false);
		}

		if (FlxG.keys.justPressed.HOME)
		{
			togglePlay(false);
			setTime(0);
		}
		if (FlxG.keys.justPressed.END)
		{
			togglePlay(false);
			setTime(FlxG.sound.music.length / 1000);
		}
		
		/* --- end TIMELINE NAVIGATION KEYS --- */

		/* --- SNAP KEYS --- */

		if (FlxG.keys.justPressed.LEFT)
			setSnap(currentSnapIndex - 1);
		if (FlxG.keys.justPressed.RIGHT)
			setSnap(currentSnapIndex + 1);

		/* --- end SNAP KEYS --- */

		/* --- ZOOM KEYS --- */

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.mouse.wheel > 0)
				setZoom(false);
			else if (FlxG.mouse.wheel < 0)
				setZoom(true);
		}

		/* --- end ZOOM KEYS */
		
		if (FlxG.keys.justPressed.SPACE)
		{
			togglePlay();
		}
		if (FlxG.keys.justPressed.ESCAPE)
		{
			close();
		}
	}

	function togglePlay(resume:Bool = true)
	{
		if (FlxG.sound.music.playing)
		{
			FlxG.sound.music.pause();
			psInstance.voicesObject.pause();
		}
		else if (resume)
		{
			FlxG.sound.music.play(false, Conductor.time * 1000);
			psInstance.voicesObject.play(false, Conductor.time * 1000);
		}
	}

	function setTime(time:Float)
	{
		if (time < 0)
			time = 0;
		if (time >= FlxG.sound.music.length / 1000)
			time = FlxG.sound.music.length / 1000;

		
		Conductor.time = time;
		FlxG.sound.music.time = Conductor.time * 1000;
		psInstance.voicesObject.time = Conductor.time * 1000;
	}

	function setSnap(snapIndex:Int)
	{
		if (snapIndex >= snaps.length)
			snapIndex = 0;
		if (snapIndex < 0)
			snapIndex = snaps.length - 1;

		currentSnapIndex = snapIndex;
		
		charterArea.setQuantColor(snaps[snapIndex].color);
		charterArea.currentSnap = snaps[snapIndex].snap;
		FlxG.sound.play(AssetHelper.getAsset("snapChange.ogg", SOUND));
	}

	function setZoom(lower:Bool)
	{
		if (lower)
			currentZoom -= 0.20;
		else
			currentZoom += 0.20;

		if (currentZoom > 5.0)
			currentZoom = 5.0;
		else if (currentZoom < 0.20)
			currentZoom = 0.20;
		else
			FlxG.sound.play(AssetHelper.getAsset("charterZoom.ogg", SOUND));

		charterArea.currentZoom = currentZoom;
	}

	function snapToNearest(prev:Bool)
	{
		var tick:Float = Conductor.getTick(Conductor.time);
		var snapInTicks:Float = (Conductor.ticksPerBeat * 4) / snaps[currentSnapIndex].snap;
		var modTick:Float = Math.ffloor(tick % snapInTicks);

		if (modTick != 0)
		{
			if (!prev)
				tick += snapInTicks;

			var snappedTick:Float = Math.ffloor(tick - modTick);
			trace(snappedTick);
			setTime(Conductor.tickToTime(snappedTick));
		}
		else
		{
			if (prev)
				setTime(Conductor.tickToTime(Math.ffloor(tick - snapInTicks))); // tolerance
			else
				setTime(Conductor.tickToTime(Math.ffloor(tick + snapInTicks)) + 0.0001);
		}
	}
}
