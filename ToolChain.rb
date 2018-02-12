# Support for selecting different compilers on the same platform
# Right now just has linux system wide compiler which is always used for linux, and gcc
# and msvc for windows

require_relative 'VSVersion.rb'

class ToolChain

  def name
    onError "unnamed toolchain"
  end

  def setupEnv
  end

  def cmakeGenerator
    onError "not overridden"
  end

  def supportsPresetBuildType
    onError "not overridden"
  end

  def cmakeToolSet
    nil
  end

  # Runs the needed compiler in the current directory
  # Defaults to make, overwrite if make isn't suitable
  # Needs to return true when didn't fail
  def runCompiler
    runOpen3StuckPrevention("make", "-j", $compileThreads.to_s) == 0
  end
  
end

class LinuxNative < ToolChain

  def name
    "linux"
    onError "Detect GCC or clang"
  end


  # Default is fine
  def cmakeGenerator
    nil
  end

  def supportsPresetBuildType
    true
  end
  
end

# Doesn't work that well
class WindowsGCC < ToolChain
  
  def initialize
    # Find where gcc is
    @GCCPath = "C:/cygwin64/usr/local/bin"

    @CCPath = File.join(@GCCPath, "gcc.exe")
    @CXXPath = File.join(@GCCPath, "g++.exe")

    if !File.exists?(@GCCPath) || !File.exists?(@CCPath) || !File.exists?(@CXXPath)
      onError "Didn't find installed GCC (did you unzip the gcc zip) at: #{@GCCPath}"
    end
  end

  def name
    "windows_gcc"
    onError "Detect GCC version"
  end

  def setupEnv
    info "Bringing GCC to environment variable from: #{@CXXPath}"
    ENV["CC"] = @CCPath
    ENV["CXX"] = @CXXPath
  end

  def cmakeGenerator
    "Unix Makefiles"
  end

  def supportsPresetBuildType
    true
  end
  
end

# Doesn't work either that well
class WindowsClang < ToolChain

  def initialize
    @CCPath = which "clang"
    @CXXPath = which "clang++"

    if !File.exists? @CCPath
      onError "clang is not installed " +
              "(or in path). clang.exe not found"
    end

    if !File.exists? @CXXPath
      onError "clang is not installed " +
              "(or in path). clang++.exe not found"
    end
  end

  def name
    "windows_clang"
    onError "Detect clang version"
  end

  def setupEnv
    info "Bringing clang to environment variables from: #{@CXXPath}"
    ENV["CC"] = @CCPath
    ENV["CXX"] = @CXXPath
  end

  # used by ffmpeg setup
  def unsetEnv
    ENV["CC"] = nil
    ENV["CXX"] = nil
  end

  def cmakeGenerator
    "Unix Makefiles"
  end

  def supportsPresetBuildType
    true
  end
  
end

class WindowsMSVC < ToolChain

  attr_reader :VS, :VSToolSet
  
  def initialize(vsversion, toolset = nil)

    @VS = vsversion

    if !@VS.is_a? VisualStudioVersion
      onError "WindowsMSVC ToolChain given invalid visual studio version object"
    end

    # Get default toolset
    if !toolset
      @VSToolSet = @VS.defaultToolSet
    else
      @VSToolSet = toolset
    end

    onError "no WindowsMSVC toolset selected" if !@VSToolSet

    # Append host x64
    @VSToolSet += ",host=x64"
    info "Added host=x64 to msvc toolset: #{@VSToolSet}"
  end

  def name
    "windows_" + @VS.version
  end

  # Doesn't do anything for now, if toolset is changed code will need
  # to make sure that all setup etc first brings this to path
  def setupEnv

    # We require that we are ran in the developer shell. Some deps also
    # need the vcvarsall but for that they apply it on a case by case
    # basis, so we just need to check that we are correctly setup for
    # visual studio stuff
    
    # if which("MSBuild.exe") == nil

    #   warning "MSBuild not found"
    #   onError %{You need to run this setup in "Developer Command Prompt for VS 2017"}

    # end
  end

  def cmakeGenerator
    @VS.version
  end

  def supportsPresetBuildType
    false
  end

  def cmakeToolSet
    @VSToolSet
  end

  def isToolSetClang
    return @VSToolSet =~ /LLVM-/i
  end

  def runCompiler
    # if winBothConfigurations
    #   if !runVSCompiler(threads, configuration: "Debug")
    #     return false
    #   end
    #   if !runVSCompiler(threads, configuration: "RelWithDebInfo")
    #     return false
    #   end
    #   true
    # else
    runVSCompiler $compileThreads
    # end
  end
  
end
