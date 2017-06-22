# Common ruby functions
require 'os'
require 'colorize'
require 'fileutils'
require 'open-uri'

# To get all possible colour values print String.colors
#puts String.colors

# Error handling
def onError(errordescription)
  
  puts
  puts ("ERROR: " + errordescription).red
  puts "Stack trace for error: ", caller
  # Uncomment the next line to allow rescuing this
  #raise "onError called!"
  exit 1
end

# Coloured output
def info(message)
  puts message.to_s.colorize(:light_blue)
end
def success(message)
  puts message.to_s.colorize(:light_green)
end
def warning(message)
  puts message.to_s.colorize(:light_yellow)
end
def error(message)
  puts message.to_s.colorize(:red)
end

# Runs a command and calls onError if it fails
def systemChecked(*command)
  
  system *command
  onError "Command '#{command.join(' ')}' failed" if $?.exitstatus > 0
  
end

# Cross-platform way of finding an executable in the $PATH.
#
#   which('ruby') #=> /usr/bin/ruby
# from: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    }
  end
  return nil
end


def askRunSudo(cmd)

  info "About to run '#{cmd}' as sudo. Be prepared to type sudo password"
  
  systemChecked(cmd)
  
end

# Copies file to target folder while preserving symlinks
def copyPreserveSymlinks(sourceFile, targetFolder)

  if File.symlink? sourceFile

    linkData = File.readlink sourceFile

    FileUtils.ln_sf linkData, File.join(targetFolder, File.basename(sourceFile))
    
  else

    FileUtils.cp sourceFile, targetFolder
    
  end
end


# Downloads an URL to a file if it doesn't exist
def downloadURLIfTargetIsMissing(url, targetFile)
    
  return true if File.exists? targetFile
  
  info "Downloading url: '#{url}' to file: '#{targetFile}'"
  
  File.open(targetFile, "wb") do |output|
    # open method from open-uri
    open(url, "rb") do |webDataStream|
      output.write(webDataStream.read)
    end
  end
  
  onError "failed to write download to file" if !File.exists? targetFile
  
  success "Done downloading"
    
end

# Makes a windows path mingw friendly path
def makeWindowsPathIntoMinGWPath(path)
  modifiedPath = path.gsub(/\\/, '/')
  modifiedPath.gsub(/^(\w+):[\\\/]/) { "/#{$1.downcase}/" }
end

# Returns current folder as something that can be used to switch directories in mingwg shell
def getMINGWPWDPath()
  makeWindowsPathIntoMinGWPath Dir.pwd
end

# Returns the line endings a file uses
# Will probably return either "\n" or "\r\n"
def getFileLineEndings(file)
  File.open(file, 'rb') do |f|
    return f.readline[/\r?\n$/]
  end
end

# Print data of str in hexadecimal
def printBytes(str)

  puts "String '#{str}' as bytes:"

  str.each_byte { |c|
    puts c.to_s(16) + " : " + c.chr
  }

  puts "end string"
  
end


# Requires that command is found in path. Otherwise shows an error
def requireCMD(cmdName, extraHelp = nil)

  if which(cmdName) != nil
    # Command found
    return
  end
  
  onError "Required program / tool '#{cmdName}' is not installed or missing from path.\n" +
    "Please install it and make sure it is in path, then try again." + (
      if extraHelp then " " + extraHelp else "" end)  

end


# Path helper
# For all tools that need to be in path but shouldn't be installed because of convenience
# TODO: switch to using this everywhere (the old deps are broken because of this)
def runWithModifiedPath(newPathEntries, prependWinPath=false)
  
  if !newPathEntries.kind_of?(Array)
    newPathEntries = [newPathEntries]
  end
  
  oldPath = ENV["PATH"]

  onError "Failed to get env path" if oldPath == nil

  if OS.windows?
    
    if prependWinPath
      newpath = newPathEntries.join(";") + ";" + oldPath
    else
      newpath = oldPath + ";" + newPathEntries.join(";")
    end
  else

    newpath = newPathEntries.join(":") + ":" + oldPath
  end

  info "Setting path to: #{newpath}"
  ENV["PATH"] = newpath
  
  begin
    yield
  ensure
    info "Restored old path"
    ENV["PATH"] = oldPath
  end    
end


def getLinuxOS()

  if OS.mac?
    return "mac"
  end
  
  if OS.windows?
    raise "getLinuxOS called on Windows!"
  end

  osrelease = `lsb_release -is`.strip

  onError "Failed to run 'lsb_release'. Make sure you have it installed" if osrelease.empty?

  osrelease.downcase

end


def isInSubdirectory(directory, possiblesub)

  path = Pathname.new(possiblesub)

  if path.fnmatch?(File.join(directory, '**'))
    true
  else
    false
  end
  
end


def createLinkIfDoesntExist(source, linkfile)

  if File.exist? linkfile
    return
  end

  FileUtils.ln_sf source, linkfile
  
end

