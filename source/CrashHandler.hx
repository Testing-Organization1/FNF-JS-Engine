package;

// an fully working crash handler on ALL platforms

import flixel.FlxState;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;

/**
 * Crash Handler.
 * @author YoshiCrafter29, MAJigsaw77 and HomuHomu833
*/

class CrashHandler {
	public static var errorMessage:String = "";

	public static function init():Void {
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void {
		try {
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();

			errorMessage = "";

			var m:String = e.error;
			if (Std.isOfType(e.error, Error)) {
				var err = cast(e.error, Error);
				m = '${err.message}';
			} else if (Std.isOfType(e.error, ErrorEvent)) {
				var err = cast(e.error, ErrorEvent);
				m = '${err.text}';
			}
			final stack = CallStack.exceptionStack();
			final stackLabelArr:Array<String> = [];
			var stackLabel:String = "";
			// legacy code below for the messages
			var path:String;
			var dateNow:String = Date.now().toString();
			dateNow = dateNow.replace(" ", "_");
			dateNow = dateNow.replace(":", "'");

			path = "crash/JSEngine_" + dateNow + ".log";

			for(stackItem in stack) {
				switch(stackItem) {
					case CFunction: stackLabelArr.push("Non-Haxe (C) Function");
					case Module(c): stackLabelArr.push('Module ${c}');
					case FilePos(parent, file, line, col):
						switch(parent) {
							case Method(cla, func): stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
							case _: stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
						}
					case LocalFunction(v): stackLabelArr.push('Local Function ${v}');
					case Method(cl, m): stackLabelArr.push('${cl} - ${m}');
				}
			}
			stackLabel = stackLabelArr.join('\r\n');

			errorMessage += 'Uncaught Error: $m\n\n$stackLabel';
			trace(errorMessage);

			try {
				if (!FileSystem.exists("crash/")) FileSystem.createDirectory("crash/");
				File.saveContent(path, '$errorMessage\n\nCrash Happened on JS Engine v${MainMenuState.psychEngineJSVersionNumber}!');
			} catch(e) trace('Couldn\'t save error message. (${e.message})');

			Sys.println(errorMessage);
			Sys.println("Crash dump saved in " + Path.normalize(path));
		} catch(e:Dynamic) trace(e);

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = false;

		if (ClientPrefs.peOGCrash) {
			errorMessage += "\n\nPlease report this error to the GitHub page: https://github.com/JordanSantiagoYT/FNF-JS-Engine"
			+ "\nThe engine has saved a crash log inside the crash folder, If you're making a GitHub issue you might want to send that!";

			CoolUtil.showPopUp(errorMessage, "Error! JS Engine v" + MainMenuState.psychEngineJSVersion + " (" + Main.__superCoolErrorMessagesArray[FlxG.random.int(0, Main.__superCoolErrorMessagesArray.length)] + ")");

			lime.system.System.exit(1);
		} else FlxG.switchState(Crash.new);
	}

    private static function onError(message:Dynamic):Void throw Std.string(message);
}

class Crash extends MusicBeatState {
	override public function create() {
		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF232323;
		add(bg);

		var ohNo:FlxText = new FlxText(0, 0, 1280, 'JS Engine v${MainMenuState.psychEngineJSVersionNumber} has crashed!');
		ohNo.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.WHITE, FlxTextAlign.CENTER);
		ohNo.alpha = 0;
		ohNo.screenCenter();
		ohNo.y = 14;
		add(ohNo);

		var ohNo2:FlxText = new FlxText(0, 0, 1280, Main.__superCoolErrorMessagesArray[FlxG.random.int(0, Main.__superCoolErrorMessagesArray.length)]);
		ohNo2.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, FlxTextAlign.CENTER);
		ohNo2.alpha = 0;
		ohNo2.screenCenter();
		ohNo2.y = 64;
		add(ohNo2);

		var ohNo3:FlxText = new FlxText(0, 0, 1280, "Crash Handler by YoshiCrafter29, MAJigsaw77 and HomuHomu833\nCrash UI State by Nael2xd");
		ohNo3.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE);
		ohNo3.alpha = 0;
		ohNo3.screenCenter();
		ohNo3.y = 580;
		ohNo3.x = 30;
		add(ohNo3);

		var ohNo4:FlxText = new FlxText(0, 0, 1280, "If you are reporting this bug, Press [F2] to screenshot that error or\nGo to crash/ folder and copy the contents from the recent file.");
		ohNo4.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, FlxTextAlign.CENTER);
		ohNo4.alpha = 0;
		ohNo4.screenCenter();
		ohNo4.y = 620;
		add(ohNo4);

		var stripClub:Array<String> = CrashHandler.errorMessage.split("\n");
		var i:Int = -1;
		var crash:Array<FlxText> = [];

		for (line in stripClub) {
			i++;
			crash.push(new FlxText(180, 0, 1280, line));
			crash[i].setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, FlxTextAlign.LEFT);
			crash[i].alpha = 0;
			crash[i].screenCenter();
			crash[i].x = 70;
			crash[i].y = 110 + (20 * i);
			add(crash[i]);
		}

		var tip:FlxText = new FlxText(180, 0, 1280, "Press any key to restart. (Press ENTER to Report This Bug)");
		tip.setFormat(Paths.font('vcr.ttf'), 36, FlxColor.WHITE, FlxTextAlign.CENTER);
		tip.alpha = 0;
		tip.screenCenter();
		tip.y = 670;
		add(tip);

		FlxTween.tween(ohNo, {alpha: 1}, 0.5);
		FlxTween.tween(ohNo2, {alpha: 1}, 0.5);
		FlxTween.tween(ohNo3, {alpha: 0.25}, 0.5);
		FlxTween.tween(ohNo4, {alpha: 1}, 0.5);
		FlxTween.tween(tip, {alpha: 1}, 0.5);
		for (spr in crash) FlxTween.tween(spr, {alpha: 1}, 0.5);

		var error:FlxSound = FlxG.sound.load(Paths.sound('error'));
		error.play();

		super.create();
	}

	// Do note that if you use "resetGame" js engine will be in a crash loop because music is missing.
	// Even with my coding skills and trying to make it work it just doesn't, i'm probably stupid.
	// Also yes i tried FlxG.sound.playMusic and yet it doesn't do what it's suppose to do.
	// -nael2xd
	var countDown:Int = 10;
	var clicked:Bool = false;
	override public function update(elapsed:Float) if (FlxG.keys.justPressed.ANY && !clicked) {
		FlxTransitionableState.skipNextTransIn = false;

		if (FlxG.keys.justPressed.ENTER) {
			clicked = true;
			for (sprite in members) if (sprite is FlxSprite || sprite is FlxText) FlxTween.tween(sprite, {alpha: 0.5}, 0.5);

			var coolBg:FlxSprite = new FlxSprite().makeGraphic(840, 260, 0xFF404040);
			coolBg.screenCenter();
			add(coolBg);

			var coolInfo:FlxSprite = new FlxSprite().makeGraphic(830, 250, 0xFF636363);
			coolInfo.screenCenter();
			add(coolInfo);

			var heyText:FlxText = new FlxText(0, 0, 820, "Before you report the crash, Please check if one of those crash exists. If it does exist yet you make the issue, it will be marked as duplicate!");
			heyText.setFormat(Paths.font('vcr.ttf'), 34, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			heyText.screenCenter();
			heyText.y -= 50;
			add(heyText);

			var countText:FlxText = new FlxText(0, 0, 640, "" + countDown);
			countText.setFormat(Paths.font('vcr.ttf'), 90, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			countText.screenCenter();
			countText.y += 73;
			add(countText);

			new FlxTimer().start(1, e -> {
				countDown--;
				countText.text = countDown + "";

				if (countDown == 0) {
					CoolUtil.browserLoad("https://github.com/JordanSantiagoYT/FNF-JS-Engine/issues/new?template=bugs.yml");
					FlxG.switchState(MainMenuState.new);
				}
			}, 10);
		} else if (!FlxG.keys.justPressed.F2) FlxG.switchState(MainMenuState.new);
	}
}
