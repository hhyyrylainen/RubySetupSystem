# Supported extra options:
# noExamples: skip attempting to build examples
# shared: if true dynamic libs are built
# noQt: if true disables Qt interop module
class Wt < StandardCMakeDep
  def initialize(args)
    super('Wt', 'wt', args)

    self.HandleStandardCMakeOptions

    @Options.push '-DBUILD_EXAMPLES=OFF' if args[:noExamples]

    @Options.push '-DBUILD_TESTS=OFF'

    @Options.push "-DSHARED_LIBS=#{args[:shared]}"

    @Options.push '-DWT_WRASTERIMAGE_IMPLEMENTATION=GraphicsMagick'

    @Options.push '-DENABLE_QT4=OFF' if args[:noQt]
    @Options.push '-DENABLE_QT5=OFF' if args[:noQt]

    @Options.push '-DENABLE_UNWIND=ON'

    # Prefer libraries in the install target
    if args[:installPath]
      @Options.push "-DCMAKE_LIBRARY_PATH=#{File.join args[:installPath], 'lib64'}"
      @Options.push "-DCMAKE_INCLUDE_PATH=#{File.join args[:installPath], 'include'}"
    end

    @RepoURL ||= 'https://github.com/emweb/wt.git'
  end

  def depsList
    os = getLinuxOS

    if os == 'fedora' || os == 'centos' || os == 'rhel'
      return [
        'boost-devel', 'GraphicsMagick-devel', 'fcgi-devel', 'glew-devel', 'libharu-devel',
        'zlib-devel', 'doxygen', 'sqlite-devel', 'libpq-devel', 'pango-devel',
        'libunwind-devel', 'openssl-devel', 'libpng-devel'
      ]
    end

    if os == 'ubuntu'
      return [
        'libboost-dev', 'libgraphicsmagick++1-dev', 'libfcgi-dev', 'libglew-dev', 'libharu',
        'zlib1g-dev', 'doxygen', 'libsqlite3-dev', 'libpq-dev', 'libpango1.0-dev',
        'libunwind-dev', 'libssl-dev', 'libpng-dev'
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
      nil
    else
      # onError "TODO: linux file list"
      nil
    end
  end
end
