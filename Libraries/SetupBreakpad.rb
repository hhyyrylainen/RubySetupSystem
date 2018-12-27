require_relative "DepotTools.rb"

# Google breakpad. Will automatically setup depot_tools if missing
# Supported extra options:
#
class Breakpad < BaseDep
  def initialize(args)
    super("Google Breakpad", "breakpad", args)

    if !@DepotFolder
      @DepotFolder = File.join(CurrentDir, "depot_tools")
    end

    @DepotDependency = DepotTools.new(installPath: @DepotFolder)

    # For packaging fakeness
    @RepoURL = "gclient fetch"
  end

  def DoClone

    FileUtils.mkdir_p @Folder

    Dir.chdir(@Folder){

      # Depot tools needed for the fetch
      @DepotDependency.activate{
        if runSystemSafe("fetch", "breakpad") != 0
          FileUtils.rm_rf @Folder, secure: true
          onError "Failed to fetch breakpad with depot tools"
        end
      }
    }

    true
  end

  def DoUpdate

    # Get new code
    Dir.chdir(File.join(@Folder, "src")) do
      if !self.standardGitUpdate
        return false
      end
    end

    # Update with depot tools
    @DepotDependency.activate{
      if runSystemSafe("gclient", "sync") != 0
        onError "Failed to sync breakpad with depot tools"
        return false
      end
    }

    true
  end

  def DoSetup

    Dir.chdir(File.join(@Folder, "src")) do

      # Configure script
      @DepotDependency.activate{

        # ./configure not available for windows. Still needs to
        # directly create project files with gyp
        if OS.windows?

          if runSystemSafe("src/tools/gyp/gyp.bat",
                           "--no-circular-check", "-Dwin_release_RuntimeLibrary=2",
                           "-Dwin_debug_RuntimeLibrary=2",                           
                           "src/client/windows/breakpad_client.gyp") != 0
            onError "configure breakpad_client failed"
          end

          if runSystemSafe("src/tools/gyp/gyp.bat",
                           "--no-circular-check", "-Dwin_release_RuntimeLibrary=2",
                           "-Dwin_debug_RuntimeLibrary=2",
                           "src/tools/tools.gyp") != 0
            onError "configure breakpad tools failed"
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

        else

          if runSystemSafe("./configure", "--prefix=#{@InstallPath}") != 0
            onError "configure breakpad failed"
          end
        end
      }
    end

    true
  end

  def DoCompile

    Dir.chdir(File.join(@Folder, "src")) do

      @DepotDependency.activate{

        if OS.windows?

          if !runVSCompiler $compileThreads,
             project: File.join(@Folder,
                                "src/src/client/windows/common.vcxproj"),
             configuration: "Release"
            return false
          end

          if !runVSCompiler $compileThreads,
             project: File.join(@Folder,
                                "src/src/client/windows/handler/exception_handler.vcxproj"),
             configuration: "Release"
            return false
          end

          if !runVSCompiler $compileThreads,
             project: File.join(
               @Folder,
               "src/src/client/windows/crash_generation/crash_generation_client.vcxproj"),
             configuration: "Release"
            return false
          end

          if !runVSCompiler $compileThreads,
             project: File.join(@Folder, "src/src/tools/windows/dump_syms/dump_syms.vcxproj"),
             configuration: "Release"
            return false
          end

        else
          if !ToolChain.new.runCompiler
            return false
          end
        end
      }
    end

    true
  end

  def DoInstall

    Dir.chdir(File.join(@Folder, "src")) do

      if !OS.windows?
        @DepotDependency.activate{

          return runSystemSafe("make", "install") == 0
        }
      else

        # Manual file copy
        FileUtils.mkdir_p File.join(@InstallPath, "bin")
        FileUtils.mkdir_p File.join(@InstallPath, "lib")
        FileUtils.mkdir_p File.join(@InstallPath, "include", "breakpad")

        copyPreserveSymlinks File.join(
                               @Folder,
                               "src/src/client/windows/handler/Release/lib/common.lib"),
                             File.join(@InstallPath, "lib")

        copyPreserveSymlinks(
          File.join(
            @Folder,
            "src/src/client/windows/crash_generation/Release/lib/crash_generation_client.lib"),
          File.join(@InstallPath, "lib"))

        copyPreserveSymlinks(
          File.join(
            @Folder,
            "src/src/client/windows/handler/Release/lib/exception_handler.lib"),
          File.join(@InstallPath, "lib"))

        copyPreserveSymlinks File.join(
                               @Folder,
                               "src/src/tools/windows/dump_syms/Release/dump_syms.exe"),
                             File.join(@InstallPath, "bin")

        installer = CustomInstaller.new(File.join(@InstallPath, "include", "breakpad"),
                                        File.join(@Folder, "src/src"))

        installer.setIncludeFolder ""

        installer.addInclude(Dir.glob(File.join(@Folder, "src/src", "**/*.h")))
        installer.run
      end
    end

                             true
  end

  def getInstalledFiles
    if OS.windows?
      [
        # Tools
        "bin/dump_syms.exe",

        # Libs
        "lib/exception_handler.lib",
        "lib/crash_generation_client.lib",
        "lib/common.lib",

        # Includes
        "include/breakpad",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end

