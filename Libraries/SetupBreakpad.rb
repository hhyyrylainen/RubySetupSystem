require_relative 'DepotTools'

# Google breakpad. Will automatically setup depot_tools if missing
# Supported extra options:
#
class Breakpad < BaseDep
  def initialize(args)
    super('Google Breakpad', 'breakpad', args)

    @DepotFolder ||= File.join(CurrentDir, 'depot_tools')

    @DepotDependency = DepotTools.new(installPath: @DepotFolder)

    @Version = 'main' if @Version == 'master'

    # This isn't actually used directly but must match what gclient wants
    @RepoURL = 'https://chromium.googlesource.com/breakpad/breakpad.git'
  end

  def DoClone
    FileUtils.mkdir_p @Folder

    Dir.chdir(@Folder) do
      # Depot tools needed for the fetch
      @DepotDependency.activate do
        if runSystemSafe('fetch', 'breakpad') != 0
          FileUtils.rm_rf @Folder, secure: true
          onError 'Failed to fetch breakpad with depot tools'
        end
      end
    end

    true
  end

  def DoUpdate
    # Get new code
    Dir.chdir(File.join(@Folder, 'src')) do
      return false unless standardGitUpdate
    end

    # Update with depot tools
    @DepotDependency.activate do
      if runSystemSafe('gclient', 'sync') != 0
        onError 'Failed to sync breakpad with depot tools'
        return false
      end
    end

    true
  end

  def DoSetup
    Dir.chdir(File.join(@Folder, 'src')) do
      # Configure script
      @DepotDependency.activate  do
        # ./configure not available for windows. Still needs to
        # directly create project files with gyp
        if OS.windows?

          if runSystemSafe('src/tools/gyp/gyp.bat',
                           '--no-circular-check', '-Dwin_release_RuntimeLibrary=2',
                           '-Dwin_debug_RuntimeLibrary=2',
                           'src/client/windows/breakpad_client.gyp') != 0
            onError 'configure breakpad_client failed'
          end

          if runSystemSafe('src/tools/gyp/gyp.bat',
                           '--no-circular-check', '-Dwin_release_RuntimeLibrary=2',
                           '-Dwin_debug_RuntimeLibrary=2',
                           'src/tools/tools.gyp') != 0
            onError 'configure breakpad tools failed'
          end

          # Verify right runtime types
          # This needs nokogiri gem and those above configs seem to work fine
          # so this is skipped
          # verifyVSProjectRuntimeLibrary(
          #   File.join(@Folder, "src/src/client/windows/handler/exception_handler.vcxproj"),
          #   File.join(@Folder, "src/src/client/windows/handler/exception_handler.sln"),
          #   /release/i, "MultiThreadedDLL")

          # # # This check fails due to some extra targets
          # # verifyVSProjectRuntimeLibrary(
          # #   File.join(@Folder, "src/src/tools/windows/dump_syms/dump_syms.vcxproj"),
          # #   File.join(@Folder, "src/src/tools/windows/dump_syms/dump_syms.sln"),
          # #   /release/i, "MultiThreadedDLL")

        elsif runSystemSafe('./configure', "--prefix=#{@InstallPath}") != 0

          onError 'configure breakpad failed'
        end
      end
    end

    true
  end

  def DoCompile
    Dir.chdir(File.join(@Folder, 'src')) do
      @DepotDependency.activate  do
        if OS.windows?

          unless runVSCompiler $compileThreads,
                               project: File.join(@Folder,
                                                  'src/src/client/windows/common.vcxproj'),
                               configuration: 'Release'
            return false
          end

          unless runVSCompiler $compileThreads,
                               project: File.join(@Folder,
                                                  'src/src/client/windows/handler/exception_handler.vcxproj'),
                               configuration: 'Release'
            return false
          end

          unless runVSCompiler $compileThreads,
                               project: File.join(
                                 @Folder,
                                 'src/src/client/windows/crash_generation/crash_generation_client.vcxproj'
                               ),
                               configuration: 'Release'
            return false
          end

          unless runVSCompiler $compileThreads,
                               project: File.join(@Folder,
                                                  'src/src/tools/windows/dump_syms/dump_syms.vcxproj'),
                               configuration: 'Release'
            return false
          end

        else
          return false unless ToolChain.new.runCompiler
        end
      end
    end

    true
  end

  def DoInstall
    Dir.chdir(File.join(@Folder, 'src')) do
      if !OS.windows?
        @DepotDependency.activate do
          return runSystemSafe('make', 'install') == 0
        end
      else

        # Manual file copy
        FileUtils.mkdir_p File.join(@InstallPath, 'bin')
        FileUtils.mkdir_p File.join(@InstallPath, 'lib')
        FileUtils.mkdir_p File.join(@InstallPath, 'include', 'breakpad')

        # This path has changed.
        # Old was "src/src/client/windows/handler/Release/lib/common.lib"
        copyPreserveSymlinks File.join(
          @Folder,
          'src/src/client/windows/Release/lib/common.lib'
        ),
                             File.join(@InstallPath, 'lib')

        copyPreserveSymlinks(
          File.join(
            @Folder,
            'src/src/client/windows/crash_generation/Release/lib/crash_generation_client.lib'
          ),
          File.join(@InstallPath, 'lib')
        )

        copyPreserveSymlinks(
          File.join(
            @Folder,
            'src/src/client/windows/handler/Release/lib/exception_handler.lib'
          ),
          File.join(@InstallPath, 'lib')
        )

        copyPreserveSymlinks File.join(
          @Folder,
          'src/src/tools/windows/dump_syms/Release/dump_syms.exe'
        ),
                             File.join(@InstallPath, 'bin')

        installer = CustomInstaller.new(File.join(@InstallPath, 'include', 'breakpad'),
                                        File.join(@Folder, 'src/src'))

        installer.setIncludeFolder ''

        installer.addInclude(Dir.glob(File.join(@Folder, 'src/src', '**/*.h')))
        installer.run
      end
    end

    true
  end

  def getInstalledFiles
    if OS.windows?
      [
        # Tools
        'bin/dump_syms.exe',

        # Libs
        'lib/exception_handler.lib',
        'lib/crash_generation_client.lib',
        'lib/common.lib',

        # Includes
        'include/breakpad'
      ]
    elsif OS.linux?
      [
        # Tools
        'bin/dump_syms',
        'bin/dump_syms_mac',
        'bin/core2md',
        'bin/minidump_stackwalk',
        'bin/microdump_stackwalk',
        'bin/minidump-2-core',
        'bin/minidump_dump',

        # Libs
        'lib/libbreakpad.a',
        'lib/libbreakpad_client.a',

        # Includes
        'include/breakpad'
      ]
    end
  end
end
