# Windows helper functions
#### Windows stuff

require_relative "RubyCommon.rb"
require_relative "Helpers.rb"

# Converts unix path to windows path
def convertPathToWindows(path, doubleEscape = false)

  if doubleEscape
    path.gsub /\//, "\\\\"
  else
    path.gsub /\//, "\\"
  end
end

def runningAsAdmin?
  (`reg query HKU\\S-1-5-19 2>&1` =~ /ERROR/).nil?
end

# Makes sure that the wanted value is specified for all targets that match the regex
def verifyVSProjectRuntimeLibrary(projFile, solutionFile, matchRegex, wantedRuntimeLib,
                                  justReturnValue: false)
  require 'nokogiri'
  
  # Very parameters
  onError "Call verifyVSProjectRuntimeLibrary only on windows!" if not OS.windows?
  onError "Project file: #{projFile} doesn't exist" if not File.exist? projFile
  onError "Project file: #{solutionFile} doesn't exist" if not File.exist? solutionFile
  
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
      error "In file '" + File.absolute_path(projFile) +"' target '#{group['Condition']}' " +
            "Has RuntimeLibrary of type '#{libType.content}' which is " +
            "not '" + wantedRuntimeLib + "' Please open the visual studio solution in the " +
            "folder and modify the Runtime Library to be #{wantedRuntimeLib}. " +
            "If you don't know how search online: 'visual studio set " +
            "project runtime library'. \n" +
            "The option should be in properties (of project) > C/C++ > Code Generation > " +
            "Runtime Library\n" +
            "Also make sure to change both the 'Debug' and 'Release' targets to use the " +
            "wanted type. \n" +
            "Important: make sure that 'Debug' configuration uses a runtime library that " +
            "has 'debug' in its name and 'release' uses one that doesn't have " +
            "'debug' in its name."

      if justReturnValue
        return false
      end
      
      openVSSolutionIfAutoOpen solutionFile

      puts "Please fix the above configuration issue in visual studio and press something " +
           "to continue"

      waitForKeyPress

      while !verifyVSProjectRuntimeLibrary(projFile, solutionFile, matchRegex,
                                           wantedRuntimeLib, justReturnValue: true)

        puts ""
        error "The runtime library is still incorrect. Please fix the error to continue."
        waitForKeyPress

        # todo: cancel
        # onError "runtime library is still incorrect"
      end
    end
  end
  
  success "All targets had correct runtime library types"
  true
end

# Makes sure that the wanted value is specified for all targets that match the regex
def verifyVSProjectPlatformToolset(projFile, solutionFile, matchRegex, wantedVersion,
                                   justReturnValue: false)

  require 'nokogiri'
  
  # Very parameters
  onError "Call verifyVSProjectPlatformToolset only on windows!" if not OS.windows?
  onError "Project file: #{projFile} doesn't exist" if not File.exist? projFile
  onError "Project file: #{solutionFile} doesn't exist" if not File.exist? solutionFile


  # Load xml with nokogiri
  doc = File.open(projFile) { |f| Nokogiri::XML(f) }
  
  doc.css("Project PropertyGroup").each do |group|
    if not matchRegex =~ group['Condition'] 
      next
    end

    info "Checking that project target '#{group['Condition']}' " +
         "Has PlatformToolset of type #{wantedVersion}"

    platType = group.at_css("PlatformToolset")
    
    if not platType
      warning "Couldn't verify platform toolset. Didn't find PlatformToolset node"
      next
    end
    
    if platType.content != wantedVersion

      puts ""
      error "In file '" + File.absolute_path(projFile) +"' target '#{group['Condition']}' " +
            "Has PlatformToolset of '#{platType.content}' which is " +
            "not '" + wantedVersion + "' Please open the visual studio solution in the " +
            "folder and right-click the solution and select 'Retarget solution'."
      
      if justReturnValue
        return false
      end
      
      openVSSolutionIfAutoOpen solutionFile

      puts "Please fix the above configuration issue in visual studio and press something " +
           "to continue"

      waitForKeyPress

      while !verifyVSProjectPlatformToolset(projFile, solutionFile, matchRegex, wantedVersion,
                                            justReturnValue: true)

        puts ""
        error "The platform toolset is still incorrect. Please fix the error to continue."
        waitForKeyPress

        # todo: cancel
        # onError "platform toolset is still incorrect"
      end
    end
  end

  success "All targets had correct platform toolset types"
  true
end

def runWindowsAdmin(cmd)

  require 'win32ole'
  
  shell = WIN32OLE.new('Shell.Application')
  
  shell.ShellExecute("ruby.exe", 
                     "\"#{CurrentDir}/Helpers/WinInstall.rb\" " +
                     "\"#{cmd.gsub( '"', '\\"')}\"", 
                     "#{Dir.pwd}", 'runas')
  
  # TODO: find a proper way to wait here
  info "Please wait while the install script runs and then press any key to continue"
  runSystemSafe "pause"
end

def askToRunAdmin(cmd)
  puts "."
  puts "."
  info "You need to open a new cmd window as administrator and run the following command: "
  info cmd
  info "Sorry, windows is such a pain in the ass"
  runSystemSafe "pause"
end


# Run msbuild with specific target and configuration
# Runtimelibrary sets the used library: possible values
# https://docs.microsoft.com/fi-fi/cpp/build/reference/md-mt-ld-use-run-time-library
def runVSCompiler(threads, project: "ALL_BUILD.vcxproj", configuration: CMakeBuildType,
                  platform: "x64", solution: nil, runtimelibrary: nil)

  # "Any CPU" might need to be quoted if used for platform
  onError "runVSCompiler called with non msvc toolchain (#{TC})" if !TC.is_a?(WindowsMSVC)

  if !File.exists?(project)
    onError "runVsCompiler: target project file doesn't exist: #{project}"
  end

  project = File.absolute_path project

  targetSelect = []
  
  if solution
    # Run project in solution
    targetSelect = [solution, "/t:" + project]
  else
    targetSelect = [project]
  end

  # TC should have brought vs to path
  args = [*TC.VS.bringVSToPath, "&&", "MSBuild.exe", *targetSelect, "/maxcpucount:#{threads}",
          "/p:CL_MPCount=#{threads}",
          "/p:Configuration=#{configuration}", "/p:Platform=#{platform}"]

  if runtimelibrary 
    args.push "/p:RuntimeLibrary=#{runtimelibrary}"
  end

  info "Running MSBuild.exe with max cpu count = #{threads} on project #{targetSelect}"
  info "with configuration = #{configuration} and platform = #{platform}"
  
  runSystemSafe(*args) == 0      
end


def openVSSolutionIfAutoOpen(solutionFile)

  if not AutoOpenVS
    return
  end

  puts "Automatically opening Visual Studio solution (NOTE: verify right version of " +
       "vs opened): " + solutionFile
  runOpen3 "start", solutionFile

  waitForKeyPress
  
end

