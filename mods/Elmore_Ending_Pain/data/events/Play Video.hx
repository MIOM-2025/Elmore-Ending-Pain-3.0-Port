import hxvlc.flixel.FlxVideoSprite;

var currentVideo:FlxVideoSprite = null;
var cacheVideos:Map<String, FlxVideoSprite> = [];

function postCreate():Void
{
    for (event in PlayState.SONG.events)
    {
        if (event.name != "Play Video")
            continue;

        var videoName:String = event.params[0];
        var functionName:String = event.params[1];
        var valueFunction:String = event.params[2];

        if (cacheVideos.exists(videoName))
            continue;

        var cacheVideo:FlxVideoSprite = getVideo(videoName);

        if (cacheVideo == null)
        {
            continue;
        }

        cacheVideo.camera = camVideos;
        cacheVideo.visible = false;

        if (cacheVideo.bitmap != null)
        {
            cacheVideo.bitmap.onFormatSetup.add(() ->
            {
                cacheVideo.setGraphicSize(FlxG.width, FlxG.height);
                cacheVideo.updateHitbox();
                cacheVideo.screenCenter();
                cacheVideo.bitmap.time = 0;
            });

            cacheVideo.bitmap.onEndReached.add(() ->
            {
                // 只隐藏，不要 stop/dispose；否则同一视频再次触发时会变成已卸载状态
                cacheVideo.visible = false;

                if (functionName != null && functionName != "" && valueFunction != null)
                    executeEvent({name: "HScript Call", time: 0, params: [functionName, valueFunction]});
                if (currentVideo == cacheVideo) currentVideo = null;
            });
        }

        if (cacheVideo.parent == null)
            add(cacheVideo);

        cacheVideos.set(videoName, cacheVideo);
    }
}

function onEvent(e)
{
    if (e.event.name != "Play Video")
        return;

    var vidName:String = e.event.params[0];
    var vid:FlxVideoSprite = cacheVideos.get(vidName);

    if (vid == null)
    {
        return;
    }

    if (currentVideo != null && currentVideo != vid)
    {
        currentVideo.stop();
        currentVideo.visible = false;
    }

    currentVideo = vid;
    currentVideo.visible = true;

    // 每次触发都从头播放，避免上次结束后停在末尾
    try {
        if (currentVideo.bitmap != null) currentVideo.bitmap.time = 0;
    } catch (e:Dynamic) {}

    currentVideo.play();
 
}

function onSubstateOpen(event)
{
    if (currentVideo != null && paused)
        currentVideo.pause();
}

function onSubstateClose(event)
{
    if (currentVideo != null && paused)
        currentVideo.resume();
}

function focusGained()
{
    if (currentVideo != null && !paused)
        currentVideo.resume();
}

function destroy()
{
    currentVideo = null;
    cacheVideos.clear();
}