# Handles differences between using different visual studio versions

class VisualStudioVersion

  # Run visual studio environment configure .bat file
  def bringVSToPath
    folder = self.pathToMSBuildCmd
    batFile = File.join(folder, "VsMSBuildCmd.bat")

    if !File.exists?(folder) || !File.exists?(batFile)
      onError "#{self.name} is not installed or path to 'VsMSBuildCmd.bat' is incorrect. " +
              "This file doesn't exist: " + batFile
    end

    ["call", batFile]
  end

  # Run vsvarsall.bat 
  def runVSVarsAll(type = "amd64")

    folder = self.versionedVCVarsAll
    file = File.join folder, "vcvarsall.bat"
    if not File.exist? file
      onError "'#{file}' is missing check if you have correctly installed vs" 
    end
    ["call", %{#{file}}, type]
  end

  # Gets paths to the visual studio link.exe and cl.exe for use in prepending to paths to
  # make sure mingw or cygwin link.exe isn't used
  # param amd64 if not empty selects 64 bit compiler
  def getVSLinkerFolder(amd64 = "amd64")
    
    folder = self.versionedLinkerPath(amd64)
    
    onError "vs linker bin folder doesn't exist" if !File.exists? folder

    if !File.exists?(File.join folder, "link.exe")
      onError "vs linker bin folder doesn't contain link.exe"
    end
    
    folder
  end

  # def getVSBaseFolder()
  #   onError "visual studio environment variable '#{VSToolsEnv}' is missing" if !ENV[VSToolsEnv]
    
  #   folder = File.expand_path(File.join ENV[VSToolsEnv], "../../")
    
  #   onError "vs folder doesn't exist ('#{folder}')" if !File.exists? folder
    
  #   folder
  # end
  


  # Visual studio version on windows, required for forced 64 bit builds with cmake
  def version
    onError "not overridden"
  end

end

class VisualStudio2015 < VisualStudioVersion
  
  def name
    "Visual Studio 2015"
  end
  
  def version
    # Need to also force 64 bits here
    # This is also used by dependency packager
    "Visual Studio 14 2015 Win64"
  end

  def pathToMSBuildCmd
    ENV["VS140COMNTOOLS"]
  end

  def probableShortName
    "msvc2015"
  end

  def versionedLinkerPath(amd64)
    File.expand_path(File.join self.pathToMSBuildCmd, "../../", "VC",
                               if amd64 then "bin/#{amd64}" else "bin" end
                    )
  end

  def versionedVCVarsAll
    File.expand_path(File.join self.pathToMSBuildCmd, "../../", "VC")
  end

  def defaultToolSet
    "v140"
  end
end

# This has weird stuff depending on if it is Community or something else affecting the paths...
class VisualStudio2017 < VisualStudioVersion

  attr_accessor :OverridePath

  def initialize
    @OverridePath = nil
  end

  def name
    "Visual Studio 2017 (Community)"
  end

  def version
    # Need to also force 64 bits here
    # This is also used by dependency packager
    "Visual Studio 15 2017 Win64"
  end

  def pathToMSBuildCmd
    if @OverridePath
      @OverridePath
    else
      "C:/Program Files (x86)/Microsoft Visual Studio/2017/Community/Common7/Tools"
    end
  end

  def probableShortName
    "msvc2017"
  end

  def versionedLinkerPath(amd64)
    # Always assumes that host is 64 bits
    
    if amd64 == "amd64"
      amd64 = "x64"
    else
      amd64 = "x86"
    end

    files = Dir.glob(File.join self.pathToMSBuildCmd, "../../",
                               "VC/Tools/MSVC/**/bin/Hostx64/#{amd64}")

    if files.empty?
      onError "Couldn't find where linker.exe for current visual studio version is"
    end

    folder = files[0]
  end

  def versionedVCVarsAll
    File.expand_path(File.join self.pathToMSBuildCmd, "../../", "VC/Auxiliary/Build/")
  end

  def defaultToolSet
    "v141"
  end
end
