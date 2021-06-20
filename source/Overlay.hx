package;

import haxe.Timer;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/* 
	Based on this tutorial:
	https://keyreal-code.github.io/haxecoder-tutorials/17_displaying_fps_and_memory_usage_using_openfl.html
 */
class Overlay extends TextField
{
	var times:Array<Float> = [];
	var memPeak:Float = 0;

	public function new(xPos:Float, yPos:Float)
	{
		super();

		x = xPos;
		y = yPos;
		width = 200;
		height = 70;

		selectable = false;

		defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF);
		text = "";

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	function onEnterFrame(_)
	{
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
		{
			times.shift();
		}

		var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;
		if (mem > memPeak)
			memPeak = mem;

		// Update the text
		if (visible)
		{
			text = "FPS: " + times.length + "\nMemory: " + mem + " MB\nPeak Memory: " + memPeak + " MB";
		}
	}
}
