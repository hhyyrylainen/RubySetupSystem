# Supported extra options:
# disableExamples
# disableTests
# disableDocs
# disableTools
# pic Enables position independent code
class AOM < StandardCMakeDep
  def initialize(args)
    super('aom', 'aom', args)

    self.HandleStandardCMakeOptions

    @Options.push '-DENABLE_EXAMPLES=OFF' if args[:disableExamples]

    @Options.push '-DENABLE_TESTS=OFF' if args[:disableTests]

    @Options.push '-DENABLE_TOOLS=OFF' if args[:disableTools]

    @Options.push '-DENABLE_DOCS=OFF' if args[:disableDocs]

    # TODO: allow changing
    @Options.push '-DAOM_TARGET_CPU=x86_64'
    @Options.push '-DCONFIG_AV1_ENCODER=0'
    @Options.push '-DCONFIG_MULTITHREAD=1'

    # ENABLE_TESTDATA:BOOL=ON

    if OS.windows?
      @yasm_folder = File.expand_path(File.join(@Folder, '../', 'aom-win-tools'))
      @yasm_executable = File.join(@yasm_folder, 'yasm.exe')
      @Options.push "-DAS_EXECUTABLE=#{@yasm_executable}"
    end

    @RepoURL ||= 'https://aomedia.googlesource.com/aom'
  end

  def depsList
    os = getLinuxOS

    return %w[cmake yasm perl] if fedora_compatible_oses.include? os

    return %w[cmake yasm perl] if ubuntu_compatible_oses.include? os

    onError "#{@name} unknown packages for os: #{os}"
  end

  def installPrerequisites
    installDepsList depsList
  end

  def DoClone
    runSystemSafe('git', 'clone', @RepoURL, 'aom') == 0
  end

  def DoUpdate
    standardGitUpdate
  end

  def DoSetup
    if OS.windows?
      # YASM assembler is required, so download that

      unless File.exist? @yasm_executable
        # We need to download it
        FileUtils.mkdir_p @yasm_folder

        downloadURLIfTargetIsMissing(
          'https://boostslair.com/rubysetupsystem/extra/yasm-1.3.0-win64.exe',
          @yasm_executable, 'f3376d71cc7273ea38514109e3ce93c2d1a69689dc8425194819bfa841880b0f',
          2
        )

        onError 'yasm tool dl failed' unless File.exist? @yasm_executable
      end
    end

    # Skip setup if not needed to avoid a full recompile each time
    cache = ActionCache.new @Folder, 'aom_cmake'

    params = { commit: get_current_git_commit(@Folder), options: @Options }

    if cache.performed?(**params)
      info "Skipping reconfiguring aom using cmake as cache says it's been configured already"
      return true
    end

    cache.mark_performed(**params)
    cache.save_cache

    super
  end

  def DoInstall
    if OS.linux?
      super
    else
      # Manual install needed as AOM doesn't provide an install target on non-linux platforms
      base = File.join(@Folder, "build/#{CMakeBuildType}/")
      target = File.join @InstallPath, 'lib/'

      FileUtils.mkdir_p target

      # libraries
      FileUtils.cp File.join(base, 'aom.lib'), target

      # include files
      installer = CustomInstaller.new(@InstallPath, @Folder)

      Dir[File.join(@Folder, 'aom', '*.h')].each do |file|
        installer.addInclude file
      end

      installer.run
    end
  end

  def getInstalledFiles
    if OS.windows?
      [
        'lib/aom.lib',

        'include/aom'
      ]
    elsif OS.linux?
      [
        'lib/libaom.a',

        'include/aom'
      ]
    end
  end
end
