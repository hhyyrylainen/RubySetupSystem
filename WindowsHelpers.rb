# Windows helper functions
#### Windows stuff

require_relative "RubyCommon.rb"
require_relative "Helpers.rb"

# Run visual studio environment configure .bat file
def bringVSToPath()
  if not File.exist? "#{ENV[VSToolsEnv]}VsMSBuildCmd.bat"
    warning "Visual Studio 2015 (community edition) may not be installed!"
    onError "VsMSBuildCMD.bat is missing check is VSToolsEnv variable correct in Setup.rb" 
  end
  ["call", "#{ENV[VSToolsEnv]}VsMSBuildCmd.bat"]
end

# Run vsvarsall.bat 
def runVSVarsAll(type = "amd64")

  folder = File.expand_path(File.join ENV[VSToolsEnv], "../../", "VC")

  if not File.exist? "#{folder}/vcvarsall.bat"
    onError "'#{folder}/vcvarsall.bat' is missing check is VSToolsEnv variable correct in Setup.rb" 
  end
  ["call", %{#{folder}/vcvarsall.bat}, type]
end

# Gets paths to the visual studio link.exe and cl.exe for use in prepending to paths to
# make sure mingw or cygwin link.exe isn't used
# param amd64 if not empty selects 64 bit compiler
def getVSLinkerFolder(amd64 = "amd64")

  onError "visual studio environment variable '#{VSToolsEnv}' is missing" if !ENV[VSToolsEnv]
  
  folder = File.expand_path(File.join ENV[VSToolsEnv], "../../", "VC", if amd64 then "bin/#{amd64}" else "bin" end)
  
  onError "vs linker bin folder doesn't exist" if !File.exists? folder
  
  folder
end

def getVSBaseFolder()
  onError "visual studio environment variable '#{VSToolsEnv}' is missing" if !ENV[VSToolsEnv]
  
  folder = File.expand_path(File.join ENV[VSToolsEnv], "../../")
  
  onError "vs folder doesn't exist" if !File.exists? folder
  
  folder
end

# Makes sure that the wanted value is specified for all targets that match the regex
def verifyVSProjectRuntimeLibrary(projFile, matchRegex, wantedRuntimeLib)
  # Very parameters
  onError "Call verifyVSProjectRuntimeLibrary only on windows!" if not OS.windows?
  onError "Project file: #{projFile} doesn't exist" if not File.exist? projFile
  
  # Load xml with nokogiri
  doc = File.open(projFile) { |f| Nokogiri::XML(f) }
  
  doc.css("Project ItemDefinitionGroup").each do |group|
    if not matchRegex.match group['Condition'] 
      next
    end
    
    info "Checking that project target '#{group['Condition']}' " +
         "Has RuntimeLibrary of type #{wantedRuntimeLib}"
    
    libType = group.at_css("ClCompile RuntimeLibrary")
    
    if not libType
      warning "Couldn't verify library type. Didn't find RuntimeLibrary node"
      next
    end
    
    if libType.content != wantedRuntimeLib
      puts ""
      warning "Error in this project file: " + File.absolute_path(projFile)
      onError "In file '#{projFile}' target '#{group['Condition']}' " +
              "Has RuntimeLibrary of type #{libType.content} which is " +
              "not " + wantedRuntimeLib + " Please open the visual studio solution in the " +
              "folder and modify the Runtime Library to be #{wantedRuntimeLib}." +
              "If you don't know how search online: 'visual studio set " +
              "project runtime library'"
    end
  end
  
  success "All targets had correct runtime library types"
end

def runWindowsAdmin(cmd)
  shell = WIN32OLE.new('Shell.Application')
  
  shell.ShellExecute("ruby.exe", 
                     "\"#{CurrentDir}/Helpers/WinInstall.rb\" " +
                     "\"#{cmd.gsub( '"', '\\"')}\"", 
                     "#{Dir.pwd}", 'runas')
  
  # TODO: find a proper way to wait here
  info "Please wait while the install script runs and then press any key to continue"
  runOpen3 "pause"
end

def askToRunAdmin(cmd)
  puts "."
  puts "."
  info "You need to open a new cmd window as administrator and run the following command: "
  info cmd
  info "Sorry, windows is such a pain in the ass"
  runOpen3 "pause"
end


# Run msbuild with specific target and configuration
def runVSCompiler(threads, project: "ALL_BUILD.vcxproj", configuration: CMakeBuildType,
                  platform: "x64")

  # "Any CPU" might need to be quoted if used for platform

  onError "runVSCompiler called on non-windows os" if !OS.windows?
  
  runOpen3(*bringVSToPath, "&&", "MSBuild.exe", project, "/maxcpucount:#{threads}",
           "/p:Configuration=#{configuration}", "/p:Platform=#{platform}") == 0
end


def openVSSolutionIfAutoOpen(solutionFile)

  if not AutoOpenVS
    return
  end

  runOpen3 "start", solutionFile

  runOpen3 "pause"
  
end

