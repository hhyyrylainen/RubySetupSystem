# Random functions to be used by the install things
# CMake configure
require_relative "RubyCommon.rb"


# Runs cmake with options and returns true on success
def runCMakeConfigure(additionalArgs)
  
  if OS.windows?

    return runOpen3("cmake", "..", "-G", VSVersion, *additionalArgs,
                    errorPrefix: "cmake configure: ") == 0
  else
    
    return runOpen3("cmake", "..", "-DCMAKE_BUILD_TYPE=#{CMakeBuildType}", *additionalArgs,
                    errorPrefix: "cmake configure: ") == 0
  end
end

# Running make or msbuild
def runCompiler(threads)
  
  if OS.windows?

    # Let's hope that WindowsHelpers.rb has been included
    runVSCompiler threads
    
  else
    
    runOpen3("make", "-j", threads.to_s) == 0
    
  end
end

# Installs a list of dependencies
def installDepsList(deps)

  os = getLinuxOS

  if os == "fedora" || os == "centos" || os == "rhel"

    if HasDNF
      askRunSudo "sudo", "dnf", "install", *deps
    else
      askRunSudo "sudo", "yum", "install", *deps
    end

    return
  end

  if os == "ubuntu"

    askRunSudo "sudo", "apt-get", "install", *deps

    return
  end

  if os == "arch"

    askRunSudo "sudo", "pacman", "-S", *deps
    
    return
  end

  if os == "opensuse"

    askRunSudo "sudo", "zypper", "in", *deps
    
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

    if runOpen3Suppressed("git", "show-ref", "--verify",
                          "refs/heads/#{versionStr}") == 0
      return BRANCH
    end

    if runOpen3Suppressed("git", "rev-parse", "--verify",
                          "#{versionStr}^{commit}") == 0
      return HASH
    end
    
    if runOpen3Suppressed("git", "show-ref", "--verify",
                          "refs/tags/#{versionStr}") == 0
      return TAG
    end

    if runOpen3Suppressed("git", "show-ref", "--verify",
                          "refs/remote/#{versionStr}") == 0
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
    if runOpen3("git", "pull", "origin", version) != 0
      onError "git pull update failed"
    end
  end
end

# If fileToCheckWith has windows line endings "\r\n" this will
# configure git to replace them and then re-checkouts all the files
# Warning: this must be ran in the folder that has the git repo that contains
# the file
def gitFixCRLFEndings(fileToCheckWith)

  runOpen3Checked "git", "config", "core.autocrlf", "off"

  puts "Deleting files and re-checking them out"
  `git ls-files`.strip.lines.each{|f|

    f = f.chomp.strip
    
    if f
      FileUtils.rm f
    end
  }
  
  runOpen3Checked "git", "checkout", "."

  onError("Line endings fix failed. See the troubleshooting in the build guide.") if
    getFileLineEndings(fileToCheckWith) != "\n"
  
  success "Fixed. If you get 'missing separator' errors see the troubleshooting " +
          "section in the help files"
end


def runGlobberAndCopy(glob, targetFolder)
  onError "globbing for library failed #{glob.LibName}" if not glob.run
  
  FileUtils.cp_r glob.getResult, targetFolder
end



