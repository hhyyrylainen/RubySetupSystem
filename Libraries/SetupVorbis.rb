# Supported extra options:
#
class Vorbis < StandardCMakeDep
  def initialize(args)
    super('Vorbis', 'vorbis', args)

    self.HandleStandardCMakeOptions

    @RepoURL ||= 'https://github.com/xiph/vorbis.git'
  end

  def DoClone
    runSystemSafe('git', 'clone', @RepoURL) == 0
  end

  def DoUpdate
    standardGitUpdate
  end

  def getInstalledFiles
    if OS.windows?
      [
        'lib/vorbis.lib',
        'lib/vorbisenc.lib',
        'lib/vorbisfile.lib',
        'include/vorbis'
      ]
    elsif OS.linux?
      [
        'lib64/libvorbis.a',
        'lib64/libvorbisenc.a',
        'lib64/libvorbisfile.a',

        'include/vorbis'
      ]
    end
  end
end
