import 'dart:math';

import 'package:awesome_notifications_example/utils/common_functions.dart';
import 'package:awesome_notifications_example/notifications/notifications_util.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:palette_generator/palette_generator.dart';
import 'package:awesome_notifications_example/models/media_model.dart';
import 'package:awesome_notifications_example/utils/media_player_central.dart';

class MediaDetailsPage extends StatefulWidget {
  const MediaDetailsPage({super.key});

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  ImageProvider? diskImage;

  bool isDraggin = false;
  bool closeCaptionActivated = false;
  bool hasCloseCaption = false;

  bool? isLighten;
  Color? mainColor;
  Color? contrastColor;

  String? band;
  String? music;
  Duration? mediaLength;
  Duration? durationPlayed;

  @override
  void initState() {
    if (!MediaPlayerCentral.hasAnyMedia) {
      MediaPlayerCentral.addAll([
        MediaModel(
          diskImagePath: 'asset://assets/images/rock-disc.jpg',
          colorCaptureSize: const Size(788, 800),
          bandName: 'Bright Sharp',
          trackName: 'Champagne Supernova',
          trackSize: const Duration(minutes: 4, seconds: 21),
        ),
        MediaModel(
          diskImagePath: 'asset://assets/images/classic-disc.jpg',
          colorCaptureSize: const Size(500, 500),
          bandName: 'Best of Mozart',
          trackName: 'Allegro',
          trackSize: const Duration(minutes: 7, seconds: 41),
        ),
        MediaModel(
          diskImagePath: 'asset://assets/images/remix-disc.jpg',
          colorCaptureSize: const Size(500, 500),
          bandName: 'Dj Allucard',
          trackName: '21st Century',
          trackSize: const Duration(minutes: 4, seconds: 59),
        ),
        MediaModel(
          diskImagePath: 'asset://assets/images/dj-disc.jpg',
          colorCaptureSize: const Size(500, 500),
          bandName: 'Dj Brainiak',
          trackName: 'Speed of light',
          trackSize: const Duration(minutes: 4, seconds: 59),
        ),
        MediaModel(
          diskImagePath: 'asset://assets/images/80s-disc.jpg',
          colorCaptureSize: const Size(500, 500),
          bandName: 'Back to the 80\'s',
          trackName: 'Disco revenge',
          trackSize: const Duration(minutes: 4, seconds: 59),
        ),
        MediaModel(
          diskImagePath: 'asset://assets/images/old-disc.jpg',
          colorCaptureSize: const Size(500, 500),
          bandName: 'PeacefulMind',
          trackName: 'Never look at back',
          trackSize: const Duration(minutes: 4, seconds: 59),
        ),
      ]);
    }

    lockScreenPortrait();
    super.initState();

    // this is not part of notification system, but just a media player simulator instead
    MediaPlayerCentral.mediaStream.listen((media) {
      switch (MediaPlayerCentral.mediaLifeCycle) {
        case MediaLifeCycle.Stopped:
          NotificationUtils.cancelNotification(100);
          break;

        case MediaLifeCycle.Paused:
          NotificationUtils.updateNotificationMediaPlayer(100, media);
          break;

        case MediaLifeCycle.Playing:
          NotificationUtils.updateNotificationMediaPlayer(100, media);
          break;
      }
    });

    MediaPlayerCentral.mediaStream.listen((media) {
      _updatePlayer(media: media);
    });

    MediaPlayerCentral.progressStream.listen((moment) {
      if (mounted) {
        setState(() {
          if (!isDraggin) {
            durationPlayed = moment;
          }
        });
      }
    });

    _updatePlayer(media: MediaPlayerCentral.currentMedia);
  }

  @override
  dispose() {
    unlockScreenPortrait();

    MediaPlayerCentral.mediaSink.close();
    MediaPlayerCentral.progressSink.close();
    super.dispose();
  }

  bool computeLuminance(Color color) {
    return color.computeLuminance() > 0.5;
  }

  Color getContrastColor(Color color) {
    double y = (299 * color.red + 587 * color.green + 114 * color.blue) / 1000;
    return y >= 128 ? Colors.black : Colors.white;
  }

  Color getComplementaryColor(Color color) {
    int minColor = min(min(color.red, color.green), color.blue);
    int maxColor = max(max(color.red, color.green), color.blue);
    return Color.fromARGB(
      255,
      maxColor - minColor - color.red,
      maxColor - minColor - color.green,
      maxColor - minColor - color.blue,
    );
    /*
    double y = (299 * color.red + 587 * color.green + 114 * color.blue) / 1000;
    return y >= 128 ? Colors.black : Colors.white;
    */
  }

  Future<void> _updatePlayer({MediaModel? media}) async {
    if (media != null) {
      diskImage = media.diskImage;
      band = media.bandName;
      music = media.trackName;
      mediaLength = media.trackSize;
      hasCloseCaption = media.closeCaption.isNotEmpty;
    } else {
      diskImage = null;
      band = null;
      music = null;
      mediaLength = null;
      durationPlayed = Duration.zero;
    }

    _updatePaletteGenerator(media: media);

    if (mounted) setState(() {});
  }

  Future<void> _updatePaletteGenerator({MediaModel? media}) async {
    late PaletteGenerator paletteGenerator;
    if (media != null) {
      paletteGenerator = await PaletteGenerator.fromImageProvider(
        media.diskImage,
        maximumColorCount: 5,
        size: media.colorCaptureSize,
      );
    }

    if (media != null && paletteGenerator.paletteColors.isNotEmpty) {
      mainColor = paletteGenerator.dominantColor!.color;
      contrastColor = getContrastColor(mainColor!)
          .withOpacity(0.85); //paletteGenerator.paletteColors.last.color;//
    } else {
      mainColor = null;
      contrastColor = null;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPlayer(context);
  }

  Widget _buildMediaPlayer(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    ThemeData themeData = Theme.of(context);

    isLighten =
        // ignore: deprecated_member_use
        isLighten ?? themeData.brightness == Brightness.light;
    mainColor = mainColor ?? themeData.colorScheme.background;
    contrastColor = contrastColor ?? (isLighten! ? Colors.black : Colors.white);

    double maxSize = max(mediaQueryData.size.width, mediaQueryData.size.height);

    double imageHeight = (maxSize - mediaQueryData.padding.top) * 0.45;
    double imageWidth = mediaQueryData.size.width * 0.8;

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: mainColor,
        // ignore: deprecated_member_use
        secondaryHeaderColor: contrastColor,
        scaffoldBackgroundColor: mainColor,
        disabledColor: contrastColor?.withOpacity(0.25),
        textTheme: Theme.of(context)
            .textTheme
            .copyWith(
              displayMedium: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              displaySmall: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              titleLarge: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            )
            .apply(
              bodyColor: contrastColor,
              decorationColor: contrastColor,
              displayColor: contrastColor,
            ),
        colorScheme: contrastColor != null
            ? ColorScheme.light(primary: contrastColor!)
            : null,
        buttonTheme: ButtonThemeData(
          textTheme: ButtonTextTheme.accent,
          disabledColor: contrastColor?.withOpacity(0.25),
          buttonColor: contrastColor,
        ),
        iconTheme: IconThemeData(color: contrastColor),
        sliderTheme: SliderThemeData(
          trackHeight: 4.0,
          activeTrackColor: contrastColor,
          inactiveTrackColor: contrastColor?.withOpacity(0.25),
          disabledInactiveTrackColor: contrastColor?.withOpacity(0.25),
          disabledThumbColor: contrastColor?.withOpacity(0.25),
          thumbColor: contrastColor,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
        ),
        canvasColor: mainColor,
      ),
      child: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Stack(
              children: <Widget>[
                ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    Container(
                      constraints: BoxConstraints(
                        minHeight: mediaQueryData.size.height,
                        minWidth: mediaQueryData.size.width,
                      ),
                      child: Stack(
                        children: <Widget>[
                          _buildBackgroundMedia(mediaQueryData),
                          _buildMediaPlayerContent(
                            mediaQueryData,
                            themeData,
                            imageHeight,
                            imageWidth,
                            maxSize,
                            context,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: mediaQueryData.padding.top + 10,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    width: 50,
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _buildMediaPlayerContent(
    MediaQueryData mediaQueryData,
    ThemeData themeData,
    double imageHeight,
    double imageWidth,
    double maxSize,
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: mediaQueryData.padding.top + 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Opacity(
                opacity: closeCaptionActivated ? 0.08 : 1.0,
                child: mediaArt(
                  imageHeight,
                  imageWidth,
                  mediaQueryData,
                  maxSize,
                ),
              ),
              closeCaptionActivated
                  ? mediaCloseCaption(
                      themeData,
                      imageHeight,
                      imageWidth,
                      mediaQueryData,
                      maxSize,
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          mediaInfo(maxSize, mediaQueryData, context),
          mediaTrackBar(maxSize, mediaQueryData),
          mediaPlayerControllers(maxSize),
        ],
      ),
    );
  }

  Widget mediaCloseCaption(
    ThemeData themeData,
    double imageHeight,
    double imageWidth,
    MediaQueryData mediaQueryData,
    double maxSize,
  ) {
    TextStyle? textStyle =
        themeData.textTheme.titleLarge?.copyWith(color: contrastColor);
    String subtitle = MediaPlayerCentral.getCloseCaption(durationPlayed!);

    return SizedBox(
      width: mediaQueryData.size.width * 0.8,
      height: imageHeight,
      child: Center(child: Text(subtitle, style: textStyle)),
    );
  }

  Widget mediaPlayerControllers(double maxSize) {
    return Center(
      child: Container(
        height: maxSize * 0.15,
        width: maxSize * 0.8,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.list),
              iconSize: maxSize * 0.05,
              onPressed: null,
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: maxSize * 0.05,
              onPressed: (durationPlayed == null ||
                          durationPlayed! <
                              MediaPlayerCentral.replayTolerance) &&
                      !MediaPlayerCentral.hasPreviousMedia
                  ? null
                  : () {
                      MediaPlayerCentral.previousMedia();
                      durationPlayed = MediaPlayerCentral.currentDuration;
                    },
            ),
            Container(
              padding: const EdgeInsets.all(5),
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: contrastColor?.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: MediaPlayerCentral.isPlaying
                  ? IconButton(
                      icon: const Icon(Icons.pause_circle_filled),
                      padding: EdgeInsets.zero,
                      iconSize: maxSize * 0.08,
                      onPressed: !MediaPlayerCentral.hasAnyMedia
                          ? null
                          : () => MediaPlayerCentral.playPause(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.play_circle_filled),
                      padding: EdgeInsets.zero,
                      iconSize: maxSize * 0.08,
                      onPressed: !MediaPlayerCentral.hasAnyMedia
                          ? null
                          : () => MediaPlayerCentral.playPause(),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: maxSize * 0.05,
              onPressed: !MediaPlayerCentral.hasNextMedia
                  ? null
                  : () {
                      MediaPlayerCentral.nextMedia();
                      durationPlayed = MediaPlayerCentral.currentDuration;
                    },
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.shuffle_medium),
              iconSize: maxSize * 0.05,
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget mediaTrackBar(double maxSize, MediaQueryData mediaQueryData) {
    double maxValue = mediaLength?.inSeconds.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.zero,
      height: maxSize * 0.15,
      width: mediaQueryData.size.width,
      padding: EdgeInsets.only(
        left: mediaQueryData.size.width * 0.05,
        right: mediaQueryData.size.width * 0.05,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.zero,
            height: maxSize * 0.05,
            width: maxSize,
            child: Slider(
              min: 0.0,
              max: maxValue,
              value: min(
                maxValue,
                durationPlayed?.inSeconds.toDouble() ?? 0.0,
              ),
              onChangeStart: (value) {
                isDraggin = true;
              },
              onChanged: (value) {
                setState(() {
                  durationPlayed = Duration(seconds: value.toInt());
                });
              },
              onChangeEnd: (value) {
                isDraggin = false;
                setState(() {
                  MediaPlayerCentral.goTo(durationPlayed!);
                });
              },
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: EdgeInsets.zero,
            width: maxSize,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(printDuration(durationPlayed)),
                Text(printDuration(durationPlayed)),
                hasCloseCaption
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.closed_caption,
                          size: 48,
                          color: closeCaptionActivated
                              ? contrastColor
                              : contrastColor?.withOpacity(0.5),
                        ),
                        onPressed: () =>
                            closeCaptionActivated = !closeCaptionActivated,
                      )
                    : const SizedBox(height: 47),
                Text(
                  printDuration(mediaLength),
                  style: TextStyle(color: contrastColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget mediaInfo(
    double maxSize,
    MediaQueryData mediaQueryData,
    BuildContext context,
  ) {
    return SizedBox(
      height: maxSize * 0.2 - mediaQueryData.padding.top,
      width: mediaQueryData.size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            band ?? 'No track',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: maxSize * 0.01),
          Text(
            music ?? '',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget mediaArt(
    double imageHeight,
    double imageWidth,
    MediaQueryData mediaQueryData,
    double maxSize,
  ) {
    return Center(
      child: SizedBox(
        height: imageHeight,
        width: imageWidth,
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [
                0.0,
                0.75,
                0.98,
              ],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: diskImage == null
              ? Container(
                  width: mediaQueryData.size.width,
                  height: (maxSize - mediaQueryData.padding.top) * 0.45,
                  color: contrastColor?.withOpacity(0.65),
                )
              : Image(
                  //ProgressiveImage
                  //placeholder: AssetImage('assets/images/placeholder.gif'),
                  //thumbnail: AssetImage('assets/images/placeholder.gif'),
                  image: diskImage!,
                  width: mediaQueryData.size.width,
                  height: (maxSize - mediaQueryData.padding.top) * 0.45,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  Widget _buildBackgroundMedia(MediaQueryData mediaQueryData) {
    return Container(
      height: mediaQueryData.size.height,
      width: mediaQueryData.size.width,
      decoration: diskImage == null
          ? null
          : BoxDecoration(
              image: DecorationImage(image: diskImage!, fit: BoxFit.cover),
            ),
      child: Container(
        decoration: BoxDecoration(color: mainColor?.withOpacity(0.93)),
      ),
    );
  }
}
