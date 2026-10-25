import hxvlc.flixel.FlxVideoSprite;

var playVideo:Bool = true;
var video:FlxVideoSprite = null;
var censorMode:Bool = false;

function postCreate() {
    // 只有明确 true 才和谐，false / null 都播放视频
    var savedValue:Dynamic = (FlxG.save.data != null) ? FlxG.save.data.censorVideo : null;
    censorMode = (savedValue == true);

    if (censorMode) {
        trace("Censor Video 已开启：视频对象不创建，100% 跳过");
        return;
    }

    video = new FlxVideoSprite(0, 0);
    video.load(Assets.getPath(Paths.video('thegrieving')), [':input-repeat=65535']);
    video.bitmap.onFormatSetup.add(() -> {
        video.setGraphicSize(FlxG.width, FlxG.height);
        video.screenCenter();
    });
    video.bitmap.onEndReached.add(function() {
        video.destroy();
    });
    video.camera = camVideos;
    add(video);
}

function onSongEnd(event:CancellableEvent) {
    // 和谐模式：直接回主菜单
    if (censorMode) {
        trace("Censor Video 已开启，直接返回主菜单");
        FlxG.switchState(new ModState("MainMenu"));
        return;
    }

    // 未勾选：原模组行为
    if (playVideo && video != null) {
        event.cancel();
        window.fullscreen = true;
        playVideo = false;
        video.play();
    }
    trace(video, "mola si estoy reproducido xdddd");
}

function update(elapsed:Float) {
    if (censorMode && video != null) {
        try { video.stop(); } catch (e:Dynamic) {}
        try { video.destroy(); } catch (e:Dynamic) {}
        remove(video);
        video = null;
    }
}