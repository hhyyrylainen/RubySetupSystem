# coding: utf-8
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
        if runSystemSafe("./configure", "--prefix=#{@InstallPath}") != 0
          onError "configure breakpad failed"
        end
      }

      # Hopefully this windows specific hack isn't needed anymore
      # if OS.windows?
      #   runSystemSafe "src/tools/gyp/gyp.bat", "src/client/windows/breakpad_client.gyp"
      #   #, "–no-circular-check"
      # else
      # end

    end

    true
  end

  def DoCompile

    Dir.chdir(File.join(@Folder, "src")) do

      # Configure script
      @DepotDependency.activate{

        if !ToolChain.new.runCompiler
          return false
        end
      }

      # if OS.windows?
      #   info "Please open the solution at and compile breakpad client in Release and x64. " +
      #        "Remember to disable treat warnings as errors first: "+
      #        "#{CurrentDir}/breakpad/src/src/client/windows/breakpad_client.sln"

      #   system "start #{CurrentDir}/breakpad/src/src/client/windows/breakpad_client.sln" if AutoOpenVS
      #   system "pause"
      # else
      #   system "make -j #{$compileThreads}"

      #   if $?.exitstatus > 0
      #     pathedit.Restore
      #     onError "breakpad build failed"
      #   end
      # end

    end

    true
  end

  def DoInstall

    Dir.chdir(File.join(@Folder, "src")) do

      # Configure script
      @DepotDependency.activate{

        return runSystemSafe("make", "install") == 0
      }
    end

    # # Create target folders
    # FileUtils.mkdir_p File.join(CurrentDir, "Breakpad", "lib")
    # FileUtils.mkdir_p File.join(CurrentDir, "Breakpad", "bin")

    # breakpadincludelink = File.join(CurrentDir, "Breakpad", "include")

    # if OS.windows?

    #   askToRunAdmin "mklink /D \"#{breakpadincludelink}\" \"#{File.join(@Folder, "src/src")}\""

    #   FileUtils.copy_entry File.join(@Folder, "src/src/client/windows/Release/lib"),
    #                        File.join(CurrentDir, "Breakpad", "lib")



    # # Might be worth it to have windows symbols dumbed on windows, if the linux dumber can't deal with pdbs
    # #FileUtils.cp File.join(@Folder, "src/src/tools/linux/dump_syms", "dump_syms"),
    # #             File.join(CurrentDir, "Breakpad", "bin")

    # else

    #   # Need to delete old file before creating a new symlink
    #   File.delete(breakpadincludelink) if File.exist?(breakpadincludelink)
    #   FileUtils.ln_s File.join(@Folder, "src/src"), breakpadincludelink

    #   FileUtils.cp File.join(@Folder, "src/src/client/linux", "libbreakpad_client.a"),
    #                File.join(CurrentDir, "Breakpad", "lib")

    #   FileUtils.cp File.join(@Folder, "src/src/tools/linux/dump_syms", "dump_syms"),
    #                File.join(CurrentDir, "Breakpad", "bin")

    #   FileUtils.cp File.join(@Folder, "src/src/processor", "minidump_stackwalk"),
    #                File.join(CurrentDir, "Breakpad", "bin")
    # end
  end

  def getInstalledFiles
    if OS.windows?
      [
        # Tools
        "bin/breakpad",

        # Libs
        "lib/breakpadstuff.lib",

        # Includes
        "include/breakpad",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end

