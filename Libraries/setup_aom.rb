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

    @Options.push "-DCMAKE_POSITION_INDEPENDENT_CODE=#{args[:pic] ? 'ON' : 'OFF'}"

    # TODO: allow changing
    @Options.push '-DAOM_TARGET_CPU=x86_64'

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
          @yasm_executable, 'd160b1d97266f3f28a71b4420a0ad2cd088a7977c2dd3b25af155652d8d8d91f'
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

  def getInstalledFiles
    if OS.windows?
      puts 'TODO: windows files'
      nil
      # [
      #   "lib/avcodec-57.def",
      #   "lib/avformat-57.def",
      #   "lib/avutil-55.def",
      #   "lib/swresample-2.def",
      #   "lib/swscale-4.def",

      #   "bin/avcodec.lib",
      #   "bin/avformat.lib",
      #   "bin/avutil.lib",
      #   "bin/swresample.lib",
      #   "bin/swscale.lib",

      #   "bin/avcodec-57.dll",
      #   "bin/avformat-57.dll",
      #   "bin/avutil-55.dll",
      #   "bin/swresample-2.dll",
      #   "bin/swscale-4.dll",

      #   "include/libavcodec",
      #   "include/libavformat",
      #   "include/libavutil",
      #   "include/libswresample",
      #   "include/libswscale",

      # ]
    else
      # onError "TODO: linux file list"
      nil
    end
  end
end
