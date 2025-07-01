package;

import haxe.Json;
import openfl.utils.Assets;

using StringTools;

// metadatas for icons
// allows for animated icons and such
typedef IconMeta = {
	?noAntialiasing:Bool,
	?fps:Int,
	// ?frameOrder:Array<String> // ["normal", "losing", "winning"]
	// ?isAnimated:Bool,
	?hasWinIcon:Bool,
	?useLegacySystem:Bool
}
class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var canBounce:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var iconMeta:IconMeta;

	var initialWidth:Float = 0;
	var initialHeight:Float = 0;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);

		if(canBounce) {
			var mult:Float = FlxMath.lerp(1, scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	public var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if(this.char != char) {
			if (char.length < 1)
				char = 'face';

			iconMeta = getFile(char);
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);

			if (file == null)
				file == Paths.image('icons/icon-face');
			else if (!Paths.fileExists('images/icons/icon-face.png', IMAGE)){
				// throw "Don't delete the placeholder icon";
				trace("Warning: could not find the placeholder icon, expect crashes!");
			}
			var iSize:Float = Math.round(file.width / file.height);
			// TODO: clean up this fucking mess
			if (iconMeta?.useLegacySystem || (file.width / file.height > 3))
			{
				if (file.width / file.height > 3)
					iSize = Math.floor(file.width / 2);
				loadGraphic(file, true, Math.floor(file.width / iSize), Math.floor(file.height));
				initialWidth = width;
				initialHeight = height;
				iconOffsets[0] = (width - 150) / iSize;
				iconOffsets[1] = (height - 150) / iSize;

				updateHitbox();

				animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			}
			else if (file.width == 300) {
				loadGraphic(file, true, Math.floor(file.width / 2), Math.floor(file.height));
				iconOffsets[0] = (width - 150) / iSize;
				iconOffsets[1] = (height - 150) / iSize;
				initialWidth = width;
				initialHeight = height;
				updateHitbox();
				animation.add(char, [0, 1], 0, false, isPlayer);
			} else if (file.width == 450) {
				loadGraphic(file, true, Math.floor(file.width / 3), Math.floor(file.height));
				iconOffsets[0] = (width - 150) / iSize;
				iconOffsets[1] = (height - 150) / iSize;
				initialWidth = width;
				initialHeight = height;
				updateHitbox();
				animation.add(char, [0, 1, 2], 0, false, isPlayer);
			} else if (Paths.fileExists('images/$name.xml', TEXT)) {
				frames = Paths.getSparrowAtlas(name);
				final iconPrefixes = checkAvailablePrefixes(Paths.getPath('images/$name.xml', TEXT));
				final hasWinning = iconPrefixes.get('winning');
				final hasLosing = iconPrefixes.get('losing');
				final fps:Float = iconMeta.fps ??= 24;
				final loop = fps > 0;

				// Always add "normal"
				animation.addByPrefix('normal', 'normal', fps, loop, isPlayer);

				// Add "losing", fallback to "normal"
				animation.addByPrefix('losing', hasLosing ? 'losing' : 'normal', fps, loop, isPlayer);

				// Add "winning", fallback to "normal"
				animation.addByPrefix('winning', hasWinning ? 'winning' : 'normal', fps, loop, isPlayer);
				playAnim('normal');
			} else { // This is just an attempt for other icon support, will detect is less than 300 or more than 300. If 300 or less, only 2 icons, if more, 3 icons.
				var num:Int = Std.int(Math.round(file.width / file.height));
				if (file.width % file.height != 0 || num >= 4) {
						// weird icon, maybe has padding?
						num = 3; // fallback
				}
				if (file.width < 300) {
					num = 2;
				} else if (file.width >= 300) {
					num = 3;
				}

				loadGraphic(file, true, Math.floor(file.width / num), Math.floor(file.height));
				iconOffsets[0] = (width - 150) / iSize;
				iconOffsets[1] = (height - 150) / iSize;
				initialWidth = width;
				initialHeight = height;
				updateHitbox();

				function getWinIcon():Array<Int>
				{
					return (iconMeta?.hasWinIcon || num == 3) ? [0, 1, 2] : [0, 1];
				}

				final winShit:Array<Int> = (num == 2) ? [0, 1] : getWinIcon();
				animation.add(char, winShit, 0, false, isPlayer);
			}

			// animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			antialiasing = (ClientPrefs.globalAntialiasing || iconMeta?.noAntialiasing);
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	// for animated icons
	function checkAvailablePrefixes(xmlPath:String):Map<String, Bool> {
		final result = new Map<String, Bool>();
		result.set("normal", false);
		result.set("losing", false);
		result.set("winning", false);

		final xml:Xml = Xml.parse(Assets.getText(xmlPath));
		final root:Xml = xml.firstElement();
		for (node in root.elements()) {
				final name = node.get("name");
				for (prefix in result.keys()) {
						if (name.startsWith(prefix)) result.set(prefix, true);
				}
		}

		return result;
	}

	public function bounce() {
		if(canBounce) {
			var mult:Float = 1.2;
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	public function playAnim(anim:String) {
		if (animation.exists(anim))
			animation.play(anim);
	}

	public static function getFile(name:String):IconMeta {
		var characterPath:String = 'images/icons/$name.json';
		var path:String = Paths.getPath(characterPath);
		if (!Paths.exists(path, TEXT))
		{
			path = Paths.getPreloadPath('images/icons/bf.json'); //If a character couldn't be found, change them to BF just to prevent a crash
		}

		var rawJson = Paths.getContent(path);
		if (rawJson == null) {
			return null;
		}

		var json:IconMeta = cast Json.parse(rawJson);
		if (json.noAntialiasing == null) json.noAntialiasing = false;
		if (json.fps == null) json.fps = 24;
		if (json.hasWinIcon == null) json.hasWinIcon = false;
		if (json.useLegacySystem == null) json.useLegacySystem = false;
		// if (json.frameOrder == null) json.frameOrder = ['normal', 'losing', 'winning'];
		return json;
	}

	override function updateHitbox()
	{
		if (ClientPrefs.iconBounceType != 'Golden Apple' && ClientPrefs.iconBounceType != 'Dave and Bambi' || !Std.isOfType(FlxG.state, PlayState))
		{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
		} else {
			super.updateHitbox();
			if (initialWidth != (150 * animation.numFrames) || initialHeight != 150) //Fixes weird icon offsets when they're HUMONGUS (sussy)
			{
				offset.x = iconOffsets[0];
				offset.y = iconOffsets[1];
			}
		}
	}

	public function getCharacter():String {
		return char;
	}
}
