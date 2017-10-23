# Common ruby functions
require 'os'
require 'colorize'
require 'fileutils'
require 'pathname'
require 'open-uri'
require "open3"
require 'digest'

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
  if OS.windows?
    puts message.to_s.colorize(:light_white)
  else
    puts message.to_s.colorize(:light_blue)
  end
end
def success(message)
  if OS.windows?
    puts message.to_s.colorize(:green)
  else
    puts message.to_s.colorize(:light_green)
  end
end
def warning(message)
  if OS.windows?
    puts message.to_s.colorize(:red)
  else
    puts message.to_s.colorize(:light_yellow)
  end
end
def error(message)
  puts message.to_s.colorize(:red)
end

# Runs Open3 for the commad, returns exit status
def runOpen3(*cmdAndArgs, errorPrefix: "", redError: false)

  # puts "Open3 debug:", cmdAndArgs

  if cmdAndArgs.length < 1
    onError "Empty runOpen3 command"
  end

  if !File.exists? cmdAndArgs[0] or !Pathname.new(cmdAndArgs[0]).absolute?
    # check that the command exists if it is not a full path to a file
    requireCMD cmdAndArgs[0]
  end

  Open3.popen3(*cmdAndArgs) {|stdin, stdout, stderr, wait_thr|

    # These need to be threads to work nicely on windows
    outThread = Thread.new{
      stdout.each {|line|
        puts line
      }
    }

    errThread = Thread.new{
      stderr.each {|line|
        if redError
          puts (errorPrefix + line).red
        else
          puts errorPrefix + line
        end
      }
    }    

    exit_status = wait_thr.value
    return exit_status
  }

  onError "Execution shouldn't reach here"
  
end

# Runs Open3 for the commad, returns exit status. Restarts command a few times if fails to run
def runOpen3StuckPrevention(*cmdAndArgs, errorPrefix: "", redError: false, retryCount: 5,
                            stuckTimeout: 120)

  if cmdAndArgs.length < 1
    onError "Empty runOpen3 command"
  end

  if !File.exists? cmdAndArgs[0] or !Pathname.new(cmdAndArgs[0]).absolute?
    # check that the command exists if it is not a full path to a file
    requireCMD cmdAndArgs[0]
  end

  Open3.popen3(*cmdAndArgs) {|stdin, stdout, stderr, wait_thr|

    lastOutputTime = Time.now

    outThread = Thread.new{
      stdout.each {|line|
        puts line
        lastOutputTime = Time.now
      }
    }

    errThread = Thread.new{
      stderr.each {|line|
        if redError
          puts (errorPrefix + line).red
      else
        puts errorPrefix + line
        end
        lastOutputTime = Time.now
      }
    }

    # Handle timeouts
    while wait_thr.join(10) == nil

      if Time.now - lastOutputTime >= stuckTimeout
        warning "RubySetupSystem stuck prevention: #{Time.now - lastOutputTime} elapsed " +
                "since last output from command"

        if retryCount > 0
          info "Restarting it "
          Process.kill("TERM", wait_thr.pid)

          sleep(5)
          return runOpen3StuckPrevention(*cmdAndArgs, errorPrefix: errorPrefix,
                                         redError: redError, retryCount: retryCount - 1,
                                         stuckTimeout: stuckTimeout)
        else
          warning "Restarts exhausted, going to wait until user interrupts us"
          lastOutputTime = Time.now
        end
      end
    end
    exit_status = wait_thr.value
    outThread.kill
    errThread.kill
    return exit_status
  }

  onError "Execution shouldn't reach here"
  
end

# Runs Open3 with suppressed output
def runOpen3Suppressed(*cmdAndArgs)

  if cmdAndArgs.length < 1
    onError "Empty runOpen3 command"
  end

  requireCMD cmdAndArgs[0]

  Open3.popen2e(*cmdAndArgs) {|stdin, out, wait_thr|

    out.each {|l|}
    
    exit_status = wait_thr.value
    return exit_status
  }

  onError "Execution shouldn't reach here"
  
end

# verifies that runOpen3 succeeded
def runOpen3Checked(*cmdAndArgs, errorPrefix: "", redError: false)

  result = runOpen3(*cmdAndArgs, errorPrefix: errorPrefix, redError: redError)

  if result != 0
    onError "Running command failed (if you try running this manually you need to " +
            "make sure that all the comma separated parts are quoted if they aren't " +
            "whole words): " + cmdAndArgs.join(", ")
  end
  
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


def askRunSudo(*cmd)

  info "About to run '#{cmd.join ' '}' as sudo. Be prepared to type sudo password"
  
  runOpen3Checked(*cmd)
  
end

# Copies file to target folder while preserving symlinks
def copyPreserveSymlinks(sourceFile, targetFolder)

  if File.symlink? sourceFile

    linkData = File.readlink sourceFile

    FileUtils.ln_sf linkData, File.join(targetFolder, File.basename(sourceFile))
    
  else

    # Recursive copy should work for normal files and directories
    FileUtils.cp_r sourceFile, targetFolder
    
  end
end


# Downloads an URL to a file if it doesn't exist
# \param hash The hash of the file. Generate by running this in irb:
# `require 'digest'; Digest::SHA2.new(256).hexdigest(File.read("filename"))`
def downloadURLIfTargetIsMissing(url, targetFile, hash)
  
  return true if File.exists? targetFile

  onError "no hash for file dl" if !hash
  
  info "Downloading url: '#{url}' to file: '#{targetFile}'"

  begin 
    File.open(targetFile, "wb") do |output|
      # open method from open-uri
      open(url, "rb") do |webDataStream|
        output.write(webDataStream.read)
      end
    end
  rescue
    error "Download failed"
    FileUtils.rm_f targetFile
    raise
  end
  
  onError "failed to write download to file" if !File.exists? targetFile

  # Check hash
  dlHash = Digest::SHA2.new(256).hexdigest(File.read(targetFile))

  if dlHash != hash
    FileUtils.rm_f targetFile
    onError "Downloaded file hash doesn't match expected hash, #{dlHash} != #{hash}"
  end
  
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

  if(cmdName.start_with? "./" or File.exists? cmdName)
    # Skip relative paths
    return
  end

  if which(cmdName) != nil
    # Command found
    return
  end

  # Windows specific checks
  if OS.windows?
    # There are a bunch of inbuilt stuff that aren't files so ignore them here
    case cmdName
    when "call"
      return
    end
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

