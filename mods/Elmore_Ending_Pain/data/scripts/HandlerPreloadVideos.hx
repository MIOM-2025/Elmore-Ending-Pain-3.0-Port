import hxvlc.flixel.FlxVideoSprite;
import hxvlc.util.Handle;

// 校准容差（毫秒）：视频与游戏时间差在 0.3 秒以内不 seek
static var SYNC_TOLERANCE_MS:Float = 300;

static var trackedVideo:FlxVideoSprite = null;
static var startGameTimeMs:Float = -1;   // 视频开始时对应的 inst.time
static var videoDurationMs:Float = -1;
static var lastVideoTimeMs:Float = -1;   // 上次读到的视频时间

function new() Handle.initAsync([]);

public static function getVideo(path:String, loop:Bool = false):FlxVideoSprite
{
    var video = new FlxVideoSprite();
    if (loop) {
        video.load(Paths.video(path), ['--input-repeat=65535']);
    } else {
        video.load(Paths.video(path));
    }
    video.pause();
    return video;
}

// ============ 内部自动销毁 ============
static function autoDestroy(video:FlxVideoSprite):Void
{
    if (video == null) return;

    // 不 stop / 不隐藏 / 不 dispose；只清理同步状态，视频本身留给 Play Video 管理
    clearVideo(video);
}

static function getVideoTimeMs(video:FlxVideoSprite):Float
{
    if (video == null) return -1;
    try {
        var t:Dynamic = Reflect.getProperty(video, "time");
        if (t != null) return cast t;
    } catch (e:Dynamic) {}
    try {
        if (video.bitmap != null) {
            var t:Dynamic = Reflect.getProperty(video.bitmap, "time");
            if (t != null) return cast t;
        }
    } catch (e:Dynamic) {}
    return -1;
}

static function setVideoTimeMs(video:FlxVideoSprite, timeMs:Float):Void
{
    if (video == null) return;
    var ms:Int = Std.int(timeMs);
    try {
        Reflect.setProperty(video, "time", ms);
        return;
    } catch (e:Dynamic) {}
    try {
        if (video.bitmap != null) {
            Reflect.setProperty(video.bitmap, "time", ms);
        }
    } catch (e:Dynamic) {}
}

static function getVideoLengthMs(video:FlxVideoSprite):Float
{
    if (video == null) return -1;
    try {
        var l:Dynamic = Reflect.getProperty(video, "length");
        if (l != null && cast(l, Float) > 0) return cast l;
    } catch (e:Dynamic) {}
    try {
        if (video.bitmap != null) {
            var l:Dynamic = Reflect.getProperty(video.bitmap, "length");
            if (l != null && cast(l, Float) > 0) return cast l;
        }
    } catch (e:Dynamic) {}
    return -1;
}

// ============ 每帧同步 ============
// gameTimeMs 传 inst.time
public static function syncVideo(video:FlxVideoSprite, gameTimeMs:Float):Void
{
    if (video == null) return;

    // 第一次见到这个视频：记录起点
    if (trackedVideo != video || startGameTimeMs < 0) {
        trackedVideo = video;
        startGameTimeMs = gameTimeMs;
        videoDurationMs = -1;
        lastVideoTimeMs = -1;
        try { video.pause(); } catch (e:Dynamic) {}
    }

    // 每帧尝试读取视频总时长，直到读到有效值
    if (videoDurationMs <= 0) {
        videoDurationMs = getVideoLengthMs(video);
    }

    // 视频已经播了多久（毫秒）
    var elapsedMs:Float = gameTimeMs - startGameTimeMs;
    if (elapsedMs < 0) elapsedMs = 0;

    // 不再按游戏时间自动销毁视频：结尾交给 Play Video 的 onEndReached
    // 之前这里会在视频还没真正播完时调用 autoDestroy，导致提前卸载。

    // ===== 校准：只在视频时间发生变化时做一次 =====
    var actualVideoTimeMs:Float = getVideoTimeMs(video);
    if (actualVideoTimeMs < 0) return;

    // 视频时间没变，跳过
    if (lastVideoTimeMs >= 0 && actualVideoTimeMs == lastVideoTimeMs) return;
    lastVideoTimeMs = actualVideoTimeMs;

    // 偏差超过容差才 seek
    var diff:Float = actualVideoTimeMs - elapsedMs;
    if (Math.abs(diff) > SYNC_TOLERANCE_MS) {
        setVideoTimeMs(video, elapsedMs);
        lastVideoTimeMs = elapsedMs;
    }
}

public static function clearVideo(video:FlxVideoSprite = null):Void
{
    if (video == null || trackedVideo == video) {
        trackedVideo = null;
        startGameTimeMs = -1;
        videoDurationMs = -1;
        lastVideoTimeMs = -1;
    }
}