# Supported extra options:
#
class Opus < StandardCMakeDep
  def initialize(args)
    super('Opus', 'opus', args)

    self.HandleStandardCMakeOptions

    @RepoURL ||= 'https://github.com/xiph/opus.git'
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
        'lib/opus.lib',
        'include/opus'
      ]
    elsif OS.linux?
      [
        'lib64/libopus.a',
        'include/opus'
      ]
    end
  end
end
