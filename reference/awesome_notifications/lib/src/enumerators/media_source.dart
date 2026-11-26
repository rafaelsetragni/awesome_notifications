/// A reference to where load the media (Image or Sound) to build a notification.
/// There's 4 media types available:
///
/// [MediaSource.Asset]: images access through Flutter asset method.
/// Example: asset://path/to/image-asset.png
/// [MediaSource.Network]: images access through internet connection.
/// Example: http(s)://url.com/to/image-asset.png
/// [MediaSource.File]: images access through files stored on device.
/// Example: file://path/to/image-asset.png
/// [MediaSource.Resource]: images access through drawable native resources. On Android, those files are stored inside (project)/android/app/src/main/res folder.
/// Example: resource://url.com/to/image-asset.png
enum MediaSource { Resource, Asset, File, Network, Unknown }

/// Media source prefix, to identify which treatment should be done to each file path
class MediaSourcePrefix {
  static const Resource = 'resource://';
  static const Asset = 'asset://';
  static const File = 'file://';
  static const Network = 'https://';
  static const Unknown = '';

  static get values => [Resource, Asset, File, Network, Unknown];

  final int value;

  const MediaSourcePrefix(this.value);
}
