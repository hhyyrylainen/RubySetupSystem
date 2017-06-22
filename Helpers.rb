# Random functions to be used by the install things
# CMake configure
require_relative "RubyCommon.rb"

def runCMakeConfigure(additionalArgs)
  
  requireCMD "cmake"
  
  if OS.windows?

    system "cmake .. -G \"#{VSVersion}\" #{additionalArgs}"
    
  else
    
    system "cmake .. -DCMAKE_BUILD_TYPE=#{CMakeBuildType} #{additionalArgs}"
    
  end
end

# Running make or msbuild
def runCompiler(threads)
  
  if OS.windows?
    #system "start \"ms\" \"MSBuild.exe\" "
    # Would use this if used project.sln file: /target:ALL_BUILD 
    system "#{bringVSToPath} && MSBuild.exe ALL_BUILD.vcxproj /maxcpucount:#{threads} /p:Configuration=RelWithDebInfo"
    
  else
    
    system "make -j #{threads}"
    
  end
end


# Running platform standard cmake install
def runInstall()
  
  if OS.windows?
    
    info "Running install script as Administrator"

    # Requires admin privileges
    runWindowsAdmin("#{bringVSToPath} && MSBuild.exe INSTALL.vcxproj /p:Configuration=RelWithDebInfo")
    
  else
    
    system "sudo make install"

  end
end

# Installs a list of dependencies
def installDepsList(deps)

  os = getLinuxOS

  if os == "fedora" || os == "centos" || os == "rhel"

    if HasDNF
      askRunSudo "sudo dnf install #{deps.join(' ')}"
    else
      askRunSudo "sudo yum install #{deps.join(' ')}"
    end

    return
  end

  if os == "ubuntu"

    askRunSudo "sudo apt-get install #{deps.join(' ')}"

    return
  end

  onError "unkown linux os '#{os}' for package manager installing " +
          "dependencies: #{deps.join(' ')}"
  
end


#
# Git things
#
class GitVersionType

  UNSPECIFIED=1
  BRANCH=2
  HASH=3
  # A specific commit
  TAG=4
  # A remote repo?
  REMOTE=5

  # Must be in the folder where git can find the current repo
  def GitVersionType.detect(versionStr)

    if !versionStr || versionStr.length == 0
      # Default branch
      return BRANCH
    end

    output = %x{git show-ref --verify refs/heads/#{versionStr}}
    
    if $?.exitstatus == 0
      return BRANCH
    end

    output = %x{git rev-parse --verify "#{versionStr}^{commit}"}
    
    if $?.exitstatus == 0
      return HASH
    end
    
    output = %x{git show-ref --verify refs/tags/#{versionStr}}
    
    if $?.exitstatus == 0
      return TAG
    end

    output = %x{git show-ref --verify refs/remote/#{versionStr}}
    
    if $?.exitstatus == 0
      return REMOTE
    end

    UNSPECIFIED
  end

  def GitVersionType.typeToStr(type)
    k = GitVersionType.constants.find {|k| GitVersionType.const_get(k) == type}
    return nil unless k
    "GitVersionType::#{k}"
  end

  
end

# Detect whether a given git is a branch or a hash and then do a pull
# if on a branch
def gitPullIfOnBranch(version)

  versionType = GitVersionType.detect(version)

  puts "Doing git pull updates. '#{version}' is #{GitVersionType.typeToStr versionType}"

  case versionType
  when GitVersionType::UNSPECIFIED, GitVersionType::BRANCH
    system "git pull origin #{version}"
  end
end

# If fileToCheckWith has windows line endings "\r\n" this will
# configure git to replace them and then re-checkouts all the files
# Warning: this must be ran in the folder that has the git repo that contains
# the file
def gitFixCRLFEndings(fileToCheckWith)

  system "git config core.autocrlf off"

  puts "Deleting files and re-checking them out"
  `git ls-files`.strip.lines.each{|f|

    f = f.chomp.strip
    
    if f
      FileUtils.rm f
    end
  }
  system "git checkout ."

  onError("Line endings fix failed. See the troubleshooting in the build guide.") if
    getFileLineEndings(fileToCheckWith) != "\n"
  
  success "Fixed. If you get 'missing separator' errors see the troubleshooting " +
          "section in the help files"
end


def runGlobberAndCopy(glob, targetFolder)
  onError "globbing for library failed #{glob.LibName}" if not glob.run
  
  FileUtils.cp_r glob.getResult, targetFolder
end


def createDependencyTargetFolder()

  FileUtils.mkdir_p ProjectDebDirLibs
  
  FileUtils.mkdir_p ProjectDebDirBinaries
  
  FileUtils.mkdir_p ProjectDebDirInclude
  
end


