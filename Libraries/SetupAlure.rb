# Supported extra options:
# noExamples: skip attempting to build examples
# static: set if static version is built
# shared: set if dynamic version is built
class Alure < StandardCMakeDep
  def initialize(args)
    super('Alure', 'alure', args)

    self.HandleStandardCMakeOptions

    @Options.push '-DALURE_BUILD_EXAMPLES=OFF' if args[:noExamples]

    self.HandleStaticAndSharedSelectors args, prefix: 'ALURE_BUILD_'

    # Prefer static libraries
    if args[:static] && !args[:shared]
      if OS.linux?
        @Options.push '-DCMAKE_FIND_LIBRARY_SUFFIXES=.a'
      elsif OS.windows?
        @Options.push '-DCMAKE_FIND_LIBRARY_SUFFIXES=.lib'
      end
    end

    # Prefer libraries in the install target
    if args[:installPath]
      @Options.push "-DCMAKE_LIBRARY_PATH=#{File.join args[:installPath], 'lib64'}"
      @Options.push "-DCMAKE_INCLUDE_PATH=#{File.join args[:installPath], 'include'}"
    end

    @RepoURL ||= 'https://github.com/kcat/alure.git'
  end

  def depsList
    os = getLinuxOS

    if os == 'fedora' || os == 'centos' || os == 'rhel'
      return [
        'openal-soft-devel'
      ]
    end

    if os == 'ubuntu'
      return [
        'libopenal-dev'
      ]
    end

    onError "#{@name} unknown packages for os: #{os}"
  end

  def installPrerequisites
    installDepsList depsList
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
        'lib/alure2.lib',
        'bin/alure2.dll',
        'include/AL/alure2.h',
        'include/AL/alure2-alext.h',
        'include/AL/alure2-aliases.h',
        'include/AL/alure2-typeviews.h',
        'include/AL/efx.h',
        'include/AL/efx-presets.h'
      ]
    elsif OS.linux?
      [
        'lib64/libalure2.so',

        'include/AL/alure2.h',
        'include/AL/alure2-alext.h',
        'include/AL/alure2-aliases.h',
        'include/AL/alure2-typeviews.h',
        'include/AL/efx.h',
        'include/AL/efx-presets.h'
      ]
    end
  end
end
