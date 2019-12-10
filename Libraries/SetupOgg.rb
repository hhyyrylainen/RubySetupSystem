# Supported extra options:
#
class Ogg < StandardCMakeDep
  def initialize(args)
    super('Ogg', 'ogg', args)

    self.HandleStandardCMakeOptions

    @RepoURL ||= 'https://github.com/xiph/ogg.git'
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
        'lib/ogg.lib',
        'include/ogg'
      ]
    elsif OS.linux?
      [
        'lib64/libogg.a',
        'include/ogg'
      ]
    end
  end
end
