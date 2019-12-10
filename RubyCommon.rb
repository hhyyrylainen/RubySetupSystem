# Common ruby functions
require 'English'
require 'os'
require 'colorize'
require 'fileutils'
require 'pathname'
require 'open-uri'
require 'open3'
require 'digest'
require 'io/console'

require_relative 'action_cache'

# To get all possible colour values print String.colors
# puts String.colors

# Error handling
def onError(errordescription)
  puts ''
  puts(('ERROR: ' + errordescription).red)
  puts 'Stack trace for error: ', caller
  # Uncomment the next line to allow rescuing this
  # raise "onError called!"
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

# Waits for a keypress
def waitForKeyPress
  print 'Press any key to continue'
  got = STDIN.getch
  # Extra space to overwrite in case next output is short
  print "                         \r"

  # Cancel on CTRL-C
  if got == "\x03"
    puts 'Got interrupt key, quitting'
    exit 1
  end
end

# Runs command with system (escaped like open3 but can't be stopped if running a long time)
def runSystemSafe(*cmd_and_args)
  onError 'Empty runSystemSafe command' if cmd_and_args.empty?

  if !File.exist?(cmd_and_args[0]) || !Pathname.new(cmd_and_args[0]).absolute?
    # check that the command exists if it is not a full path to a file
    requireCMD cmd_and_args[0]
  end

  system(*cmd_and_args)
  $CHILD_STATUS.exitstatus
end

# Runs Open3 for the commad, returns exit status
def runOpen3(*cmd_and_args, errorPrefix: '', redError: false)
  # puts "Open3 debug:", cmd_and_args

  onError 'Empty runOpen3 command' if cmd_and_args.empty?

  if !File.exist?(cmd_and_args[0]) || !Pathname.new(cmd_and_args[0]).absolute?
    # check that the command exists if it is not a full path to a file
    requireCMD cmd_and_args[0]
  end

  Open3.popen3(*cmd_and_args) do |_stdin, stdout, stderr, wait_thr|
    # These need to be threads to work nicely on windows
    out_thread = Thread.new do
      stdout.each do |line|
        puts line
      end
    end

    err_thread = Thread.new do
      stderr.each do |line|
        if redError
          puts((errorPrefix + line).red)
        else
          puts errorPrefix + line
        end
      end
    end

    exit_status = wait_thr.value
    out_thread.join
    err_thread.join
    return exit_status
  end

  onError "Execution shouldn't reach here"
end

# Runs Open3 for the commad, returns exit status and output string
def runOpen3CaptureOutput(*cmd_and_args)
  output = ''

  onError 'Empty runOpen3 command' if cmd_and_args.empty?

  if !File.exist?(cmd_and_args[0]) || !Pathname.new(cmd_and_args[0]).absolute?
    # check that the command exists if it is not a full path to a file
    requireCMD cmd_and_args[0]
  end

  Open3.popen3(*cmd_and_args) do |_stdin, stdout, stderr, wait_thr|
    # These need to be threads to work nicely on windows
    out_thread = Thread.new do
      stdout.each do |line|
        output.concat(line)
      end
    end

    err_thread = Thread.new do
      stderr.each do |line|
        output.concat(line)
      end
    end

    exit_status = wait_thr.value
    out_thread.join
    err_thread.join
    return exit_status, output
  end

  onError "Execution shouldn't reach here"
end

# Runs Open3 for the commad, returns exit status. Restarts command a few times if fails to run
def runOpen3StuckPrevention(*cmd_and_args, errorPrefix: '', redError: false, retryCount: 5,
                            stuckTimeout: 120)

  onError 'Empty runOpen3 command' if cmd_and_args.empty?

  if !File.exist?(cmd_and_args[0]) || !Pathname.new(cmd_and_args[0]).absolute?
    # check that the command exists if it is not a full path to a file
    requireCMD cmd_and_args[0]
  end

  Open3.popen3(*cmd_and_args) do |_stdin, stdout, stderr, wait_thr|
    last_output_time = Time.now

    out_thread = Thread.new do
      stdout.each do |line|
        puts line
        last_output_time = Time.now
      end
    end

    err_thread = Thread.new do
      stderr.each do |line|
        if redError
          puts((errorPrefix + line).red)
        else
          puts errorPrefix + line
        end
        last_output_time = Time.now
      end
    end

    # Handle timeouts
    while wait_thr.join(10).nil?

      next unless Time.now - last_output_time >= stuckTimeout

      warning "RubySetupSystem stuck prevention: #{Time.now - last_output_time} elapsed " \
              'since last output from command'

      if retryCount > 0
        info 'Restarting it '
        Process.kill('TERM', wait_thr.pid)

        sleep(5)
        return runOpen3StuckPrevention(*cmd_and_args, errorPrefix: errorPrefix,
                                                      redError: redError,
                                                      retryCount: retryCount - 1,
                                                      stuckTimeout: stuckTimeout)
      else
        warning 'Restarts exhausted, going to wait until user interrupts us'
        last_output_time = Time.now
      end
    end
    exit_status = wait_thr.value

    out_thread.kill
    err_thread.kill
    return exit_status
  end

  onError "Execution shouldn't reach here"
end

# Runs Open3 with suppressed output
def runOpen3Suppressed(*cmd_and_args)
  onError 'Empty runOpen3 command' if cmd_and_args.empty?

  requireCMD cmd_and_args[0]

  Open3.popen2e(*cmd_and_args) do |_stdin, out, wait_thr|
    out.each { |l| }

    exit_status = wait_thr.value
    return exit_status
  end

  onError "Execution shouldn't reach here"
end

# verifies that runOpen3 succeeded
def runOpen3Checked(*cmd_and_args, errorPrefix: '', redError: false)
  result = runOpen3(*cmd_and_args, errorPrefix: errorPrefix, redError: redError)

  if result != 0
    onError 'Running command failed (if you try running this manually you need to ' \
            "make sure that all the comma separated parts are quoted if they aren't " \
            'whole words): ' + cmd_and_args.join(', ')
  end
end

def pathAsArray
  ENV['PATH'].split(File::PATH_SEPARATOR)
end

def pathExtsAsArray
  ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
end

# Cross-platform way of finding an executable in the $PATH.
#
#   which('ruby') #=> /usr/bin/ruby
# from: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
# Modified to work better for windows
def which(cmd)
  # Could actually rather check that this command with the .exe suffix
  # is somewhere, instead of allowing the suffix to change, but that
  # is probably fine
  if OS.windows?
    if cmd.end_with? '.exe'
      # 5 is length of ".exe"
      cmd = cmd[0..-5]
    end
  end

  exts = pathExtsAsArray
  pathAsArray.each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

def askRunSudo(*cmd)
  info "About to run '#{cmd.join ' '}' as sudo. Be prepared to type sudo password"

  runOpen3Checked(*cmd)
end

# Copies file to target folder while preserving symlinks
def copyPreserveSymlinks(source_file, target_folder)
  if File.symlink? source_file

    link_data = File.readlink source_file

    target_file = File.join(target_folder, File.basename(source_file))

    if File.symlink? target

      existing_link = File.readlink target_file

      if link_data == existing_link
        # Already up to date
        return
      end
    end

    FileUtils.ln_sf link_data, target_file

  else

    # Recursive copy should work for normal files and directories
    FileUtils.cp_r source_file, target_folder, preserve: true

  end
end

# Downloads an URL to a file if it doesn't exist
# \param hash The hash of the file. Generate by running this in irb:
# `require 'digest'; Digest::SHA2.new(256).hexdigest(File.read("filename"))`
# hashmethod == 1 default hash
# hashmethod == 2 is hash from require 'sha3'
# hashmethod == 3 is sha1 for better compatibility with download sites that only give that
def downloadURLIfTargetIsMissing(url, target_file, hash, hashmethod = 1, skipcheckifdl = false,
                                 attempts = 5)

  onError 'no hash for file dl' unless hash

  if File.exist? target_file

    return true if skipcheckifdl

    info "Making sure already downloaded file is intact: '#{target_file}'"

  else
    info "Downloading url: '#{url}' to file: '#{target_file}'"

    begin
      File.open(target_file, 'wb') do |output|
        # open method from open-uri
        open(url, 'rb') do |web_data_stream|
          output.write(web_data_stream.read)
        end
      end
    rescue StandardError
      error 'Download failed'
      FileUtils.rm_f target_file

      raise if attempts < 1

      attempts -= 1
      info "Attempting download again, attempts left: #{attempts}"
      return downloadURLIfTargetIsMissing(url, target_file, hash, hashmethod, skipcheckifdl,
                                          attempts)
    end

    onError 'failed to write download to file' unless File.exist? target_file
  end

  # Check hash
  if hashmethod == 1
    dl_hash = Digest::SHA2.new(256).hexdigest(File.read(target_file))
  elsif hashmethod == 2
    require 'sha3'
    dl_hash = SHA3::Digest::SHA256.file(target_file).hexdigest
  elsif hashmethod == 3
    dl_hash = Digest::SHA1.file(target_file).hexdigest
  else
    raise AssertionError
  end

  if dl_hash != hash
    FileUtils.rm_f target_file

    if attempts < 1
      onError "Downloaded file hash doesn't match expected hash, #{dl_hash} != #{hash}"
    else
      attempts -= 1
      error "Downloaded file hash doesn't match expected hash, #{dl_hash} != #{hash}"
      info "Attempting download again, attempts left: #{attempts}"
      return downloadURLIfTargetIsMissing(url, target_file, hash, hashmethod, skipcheckifdl,
                                          attempts)
    end
  end

  success 'Done downloading'
end

# Makes a windows path mingw friendly path
def makeWindowsPathIntoMinGWPath(path)
  modified_path = path.tr('\\', '/')
  modified_path.gsub(%r{^(\w+):[\\/]}) { "/#{Regexp.last_match(1).downcase}/" }
end

# Returns current folder as something that can be used to switch directories in mingwg shell
def getMINGWPWDPath
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

  str.each_byte do |c|
    puts c.to_s(16) + ' : ' + c.chr
  end

  puts 'end string'
end

# Requires that command is found in path. Otherwise shows an error
def requireCMD(cmd_name, extraHelp = nil)
  if cmd_name.start_with?('./') || File.exist?(cmd_name)
    # Skip relative paths
    return
  end

  unless which(cmd_name).nil?
    # Command found
    return
  end

  # Windows specific checks
  if OS.windows?
    # There are a bunch of inbuilt stuff that aren't files so ignore them here
    case cmd_name
    when 'call'
      return
    when 'start'
      return
    when 'mklink'
      return
    end
  end

  # Print current search path
  puts ''
  info 'The following paths were searched for ' +
       pathExtsAsArray.map { |i| "'#{cmd_name}#{i}'" }.join(' or ') + " but it wasn't found:"

  pathAsArray.each do |p|
    puts p
  end

  onError "Required program / tool '#{cmd_name}' is not installed or missing from path.\n" \
          'Please install it and make sure it is in path, then try again. ' \
          '(path is printed above for reference)' + (
            extraHelp ? ' ' + extraHelp : '')
end

# Path helper
# For all tools that need to be in path but shouldn't be installed because of convenience
def runWithModifiedPath(new_path_entries, prependPath = false)
  new_path_entries = [new_path_entries] unless new_path_entries.is_a?(Array)

  old_path = ENV['PATH']

  onError 'Failed to get env path' if old_path.nil?

  separator = if OS.windows?
                ';'
              else
                ':'
              end

  newpath = if prependPath
              new_path_entries.join(separator) + separator + old_path
            else
              old_path + separator + new_path_entries.join(separator)
            end

  info "Setting path to: #{newpath}"
  ENV['PATH'] = newpath

  begin
    yield
  ensure
    info 'Restored old path'
    ENV['PATH'] = old_path
  end
end

def fetch_linux_distributor
  os_release = `lsb_release -is`.strip

  onError "Failed to run 'lsb_release'. Make sure you have it installed" if os_release.empty?

  os_release.downcase
end

def getLinuxOS
  return 'mac' if OS.mac?

  raise 'getLinuxOS called on Windows!' if OS.windows?

  # Override OS type if wanted
  return $pretendLinux if $pretendLinux

  # Pretend to be on fedora to get the package names correctly (as
  # they aren't attempted to be installed this is fine)
  return 'fedora' if (defined? 'SkipPackageManager') && SkipPackageManager

  fetch_linux_distributor
end

# Returns the OS version on Linux. For example `30` on Fedora 30
def fetch_linux_os_version
  `lsb_release -rs`.strip
end

# Version of linux OS + version number getting without allowing
# pretending. This is used for precompiled deps
def linux_identification
  "#{fetch_linux_distributor}_#{fetch_linux_os_version}"
end

def fedora_compatible_oses
  %w[fedora centos rhel]
end

def ubuntu_compatible_oses
  ['ubuntu']
end

# Identifies a compiler based on the command
def identify_compiler_version(executable, version_accuracy: :major)
  raise 'unknown version accuracy' if version_accuracy != :major

  _exit_status, output = runOpen3CaptureOutput executable, '--version'

  match = output.match(/\(GCC\)\s+(\d+)\.(\d+)\.(\d+)/i)

  if match
    major = match.captures[0]
    return "gcc_#{major}"
  end

  match = output.match(/clang\s+version\s+(\d+)\.(\d+)\.(\d+)/i)

  if match
    major = match.captures[0]
    return "clang_#{major}"
  end

  raise 'could not detect compiler type or version'
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
  return if File.exist? linkfile

  FileUtils.ln_sf source, linkfile
end

# Sanitizes path (used by precompiled packager at least)
def sanitizeForPath(str)
  # Code from (modified) http://gavinmiller.io/2016/creating-a-secure-sanitization-function/
  # Bad as defined by wikipedia:
  # https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
  bad_chars = ['/', '\\', '?', '%', '*', ':', '|', '"', '<', '>', '.', ' ']
  bad_chars.each do |c|
    str.gsub!(c, '_')
  end
  str
end

# Parses symbol definition from breakpad data
# call like `platform, arch, hash, name = getBreakpadSymbolInfo data`
def getBreakpadSymbolInfo(data)
  match = data.match(/MODULE\s(\w+)\s(\w+)\s(\w+)\s(\S+)/)

  raise 'invalid breakpad data' if !match || match.captures.length != 4

  match.captures
end

# Returns name of 7zip on platform (7za on linux and 7z on windows)
def p7zip
  if OS.windows?
    '7z'
  else
    '7za'
  end
end

# Returns true if target is a child path of root
def child_path?(root, target)
  return false if target.size < root.size

  target[0...root.size] == root &&
    (target.size == root.size || target[root.size] == '/')
end
