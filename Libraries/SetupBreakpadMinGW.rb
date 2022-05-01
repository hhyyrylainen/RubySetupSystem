# Google breakpad. But the version supporting MinGW
#
class BreakpadMinGW < BaseDep
  def initialize(args)
    super('Google Breakpad (mingw)', 'breakpad_mingw', args)

    # @Version = 'main' if @Version == 'master'

    @RepoURL ||= 'https://github.com/DaemonEngine/breakpad.git'
  end

  def depsList
    os = getLinuxOS

    return %w[python2 autoconf automake] if %w[fedora centos rhel].include?(os)

    return %w[python2 autoconf automake] if os == 'ubuntu'

    onError "#{@name} unknown packages for os: #{os}"
  end

  def installPrerequisites
    installDepsList depsList
  end

  def DoClone
    runSystemSafe('git', 'clone', @RepoURL, @Folder) == 0
  end

  def DoUpdate
    return false unless standardGitUpdate

    runSystemSafe('git', 'submodule', 'update', '--init') == 0
  end

  def DoSetup
    runOpen3Checked 'python2', 'fetch-externals'
    runOpen3Checked 'autoreconf', '-fvi'

    FileUtils.mkdir_p 'build'

    Dir.chdir('build') do
      runSystemSafe '../configure', "--prefix=#{@InstallPath}"
    end

    $CHILD_STATUS.exitstatus == 0
  end

  def DoCompile
    Dir.chdir('build') do
      return ToolChain.new.runCompiler
    end
  end

  def DoInstall
    Dir.chdir('build') do
      # This seems to fail anyway so we do our manual copy of the critical things
      # runSystemSafe 'make', 'install'
      FileUtils.mkdir_p File.join(@InstallPath, 'bin')

      # TODO: Windows
      copyPreserveSymlinks 'src/processor/minidump_stackwalk', File.join(@InstallPath, 'bin')
      copyPreserveSymlinks 'src/tools/windows/dump_syms_dwarf/dump_syms',
                           File.join(@InstallPath, 'bin')
    end

    true
  end

  def getInstalledFiles
    if OS.windows?
      [
        'bin/dump_syms.exe'
      ]
    elsif OS.linux?
      [
        'bin/dump_syms',
        'bin/minidump_stackwalk'
      ]
    end
  end
end
