const Map<String, dynamic> jellyfinPlayerDeviceProfile = {
  'Name': 'Aetherfin MediaKit',
  'MaxStreamingBitrate': 140000000,
  'MaxStaticBitrate': 140000000,
  'MusicStreamingTranscodingBitrate': 192000,
  'TimelineOffsetSeconds': 5,
  'DirectPlayProfiles': [
    {
      'Type': 'Video',
    },
    {
      'Type': 'Audio',
    },
  ],
  'TranscodingProfiles': [
    {
      'Container': 'ts',
      'Type': 'Video',
      'Protocol': 'hls',
      'AudioCodec': 'aac,mp3,ac3,eac3,opus,flac,vorbis',
      'VideoCodec': 'h264,hevc,av1,vp8,vp9,mpeg4,mpeg2video',
      'Context': 'Streaming',
      'MaxAudioChannels': '8',
      'MinSegments': '1',
      'BreakOnNonKeyFrames': true,
    },
  ],
  'SubtitleProfiles': [
    {
      'Format': 'srt',
      'Method': 'External',
    },
    {
      'Format': 'vtt',
      'Method': 'External',
    },
    {
      'Format': 'ass',
      'Method': 'External',
    },
    {
      'Format': 'ssa',
      'Method': 'External',
    },
    {
      'Format': 'subrip',
      'Method': 'External',
    },
    {
      'Format': 'pgs',
      'Method': 'Embed',
    },
  ],
};
