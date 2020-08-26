
enum MediaSource {
  Resource,
  Asset,
  File,
  Network,
  Unknown
}

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