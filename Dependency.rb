#
# Dependency base class
#
require 'zip'
require 'json'

require_relative 'RubyCommon'
require_relative 'Helpers.rb'

### Download settings ###
# Standard args that are handled:
# :version => standard git version select
# :installPath => path where to install the built files (if this dep uses install)
# :noInstallSudo => don't use sudo when installing (on windows administrator might be
#     used instead if this isn't specified)
# :options => override project configure options (shouldn't be used,
#     extraOptions should be used instead)
# :extraOptions => extra things to add to :options, see the individual dependencies
#     as to what specific options they support
# :preCreateInstallFolder => If installPath is specified will create
#     the folder if it doesn't exist
class BaseDep
  attr_reader :Name, :Folder, :FolderName, :RepoURL, :Version

  def initialize(name, foldername, args)
    @Name = name

    @Folder = File.join(CurrentDir, foldername)
    @FolderName = foldername

    # Standard args handling
    if args[:options]

      @Options = args[:options]

      onError 'Provided :options is nil' if @Options.nil?

      puts "#{@Name}: using options: #{@Options}"
    else

      @Options = getDefaultOptions if respond_to? 'getDefaultOptions'

      @Options = [] if @Options.nil?

    end

    raise AssertionError unless @Options.is_a?(Array)

    if args[:extraOptions]
      onError ':extraOptions need to be an array' unless args[:extraOptions].is_a?(Array)
      @Options += args[:extraOptions]
      puts "#{@Name}: using extra options: #{args[:extraOptions]}"
    end

    if args[:version]
      @Version = args[:version]
      puts "#{@Name}: using version: #{@Version}"
    else
      @Version = 'master'
    end

    # For naming precompiled releases from a branch differently
    @BranchEpoch = (args[:epoch])

    if args[:installPath]
      @InstallPath = args[:installPath]
      puts "#{@Name}: using install prefix: #{@InstallPath}"
    end

    if args[:noInstallSudo]
      @InstallSudo = false
      puts "#{@Name}: installing without sudo"
    else
      @InstallSudo = true
    end

    if args[:preCreateInstallFolder] && @InstallPath

      puts "#{@Name}: precreating install folder: #{@InstallPath}"
      FileUtils.mkdir_p @InstallPath
    end

    @Options.push '-DCMAKE_POSITION_INDEPENDENT_CODE=ON' if args[:pic]

    # URL overwriting
    @RepoURL = args[:fork] if args[:fork]
  end

  def HandleStaticAndSharedSelectors(args, prefix: 'BUILD_')
    @Options.push "-D#{prefix}STATIC=#{args[:static]}" if args.include? :static
    @Options.push "-D#{prefix}SHARED=#{args[:shared]}" if args.include? :shared
  end

  def HandleStandardCMakeOptions
    @Options.push "-DCMAKE_INSTALL_PREFIX=#{@InstallPath}" if @InstallPath

    # Linux compiler settings
    @Options.push '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON' if OS.linux?
  end

  def RequiresClone
    !File.exist?(@Folder)
  end

  def IsUsingSpecificCommit
    puts "Checking if '#{@Name}' is using a specific version / commit"

    # If not cloned can't determine
    if self.RequiresClone
      warning "Can't check because this requires cloning"
      return false
    end

    # If no specific thing is set can't figure it out
    unless @Version
      info "Version is empty(#{@Version}). This doesn't use a specific commit"
      return false
    end

    Dir.chdir(@Folder) do
      versionType = GitVersionType.detect(@Version)

      case versionType
      when GitVersionType::HASH, GitVersionType::TAG, GitVersionType::UNSPECIFIED
        puts "This dependency uses a specific git commit (#{@Version})"
        return true
      else
        puts "Detected version (#{@Version}) is not specific: " +
             GitVersionType.typeToStr(versionType)
        return false
      end
    end
  end

  # Lite version of Retrieve
  def MakeSureRightCommitIsCheckedOut
    self.Update
  end

  def Retrieve
    info "Retrieving #{@Name}"

    Dir.chdir(CurrentDir) do
      if self.RequiresClone

        info "Cloning #{@Name} into #{@Folder}"

        # Attempt up to 5 times
        (1..5).each do |i|
          if !self.DoClone

            onError 'Failed to clone repository even after 5 attempts.' if i >= 5

            puts ''
            error "Failed to clone #{@Name}. Deleting previous attempt and trying " \
                  'again in 5 seconds.'
            puts 'Press CTRL+C to cancel'

            sleep(5)

            # Delete attempt
            FileUtils.rm_rf @Folder, secure: true

            info 'Attempting again'
          else
            break
          end
        end
      end

      unless File.exist?(@Folder)
        onError "Retrieve Didn't create a folder for #{@Name} at #{@Folder}"
      end

      unless self.Update
        # Not fatal
        warning "Failed to update dependency #{@Name}"
      end
    end

    success "Successfully retrieved #{@Name}"
  end

  def Update
    Dir.chdir(@Folder) do
      self.DoUpdate
    end
  end

  def Setup
    info "Setting up build files for #{@Name}"
    Dir.chdir(@Folder) do
      unless self.DoSetup
        onError "Setup failed for #{@Name}. Is a dependency missing? or some other cmake error?"
      end
    end
    success "Successfully created project files for #{@Name}"
  end

  def Compile
    info "Compiling #{@Name}"
    Dir.chdir(@Folder) do
      unless self.DoCompile
        onError "#{@Name} Failed to Compile. Are you using a broken version? or has the setup process" \
                ' changed between versions'
      end
    end
    success "Successfully compiled #{@Name}"
  end

  def Install
    info "Installing #{@Name}"
    Dir.chdir(@Folder) do
      unless self.DoInstall
        onError "#{@Name} Failed to install. Did you type in your sudo password?"
      end
    end
    success "Successfully installed #{@Name}"
  end

  #
  # Helpers for subclasses
  #
  def linuxMakeInstallHelper
    if shouldUseSudo(@InstallSudo)

      askRunSudo 'sudo make install'

    else

      warning "Dependency '#{@name}' should have been installed with sudo" if @InstallSudo

      runSystemSafe 'make', 'install'
    end

    $CHILD_STATUS.exitstatus == 0
  end

  # Windows VS cmake INSTALL target
  def vsInstallHelper(winBothConfigurations: false)
    if shouldUseSudo(@InstallSudo)

      onError 'TODO: reimplement administrator installation'

      # Requires admin privileges
      # runWindowsAdmin("#{bringVSToPath} && MSBuild.exe INSTALL.vcxproj
      # /p:Configuration=RelWithDebInfo")
    else

      if @InstallSudo
        warning "Dependency '#{@name}' should have been installed as administrator"
      end

      if winBothConfigurations
        unless runVSCompiler(1, project: 'INSTALL.vcxproj',
                                configuration: (if respond_to?(:translateBuildType)
                                                  translateBuildType('Debug')
                                                else
                                                  'Debug'
                                          end))
          return false
        end
        unless runVSCompiler(1, project: 'INSTALL.vcxproj', configuration:
                                                           buildType)
          return false
        end

        true
      else
        return runVSCompiler 1, project: 'INSTALL.vcxproj', configuration: buildType
      end
    end
  end

  def cmakeUniversalInstallHelper(winBothConfigurations: false)
    if OS.windows?
      vsInstallHelper winBothConfigurations: winBothConfigurations
    else
      linuxMakeInstallHelper
    end
  end

  def standardGitUpdate
    runSystemSafe 'git', 'fetch'

    # make sure the origin is right
    if @RepoURL

      status, origin = runOpen3CaptureOutput('git', 'remote', 'get-url', 'origin')

      if status != 0

        error 'Failed to get current remote git url'
      else

        origin.strip!

        if @RepoURL != origin

          info "Correcting dependency url from #{origin} to #{@RepoURL}"

          if runSystemSafe('git', 'remote', 'set-url', 'origin', @RepoURL) != 0
            error 'Failed to change url'
          end
        end
      end
    end

    if runSystemSafe('git', 'checkout', @Version) != 0
      info "Git checkout was performed in: #{Dir.pwd}"
      return false
    end

    # this doesn't return an error code
    gitPullIfOnBranch @Version

    true
  end

  def clearEmptyOptions
    @Options.reject!(&:empty?)
  end

  def buildType
    if respond_to? :translateBuildType
      translateBuildType CMakeBuildType
    else
      CMakeBuildType
    end
  end

  # Overwrite to support precompiled distribution
  def getInstalledFiles
    warning "This dependency (#{@Name}) doesn't support getting file list for " \
            'precompiled binary'
    false
  end

  # creates a 12 character hash of options
  def optionsHash(length = 12)
    # Don't want to always need this as this may be difficult to compile
    require 'sha3'

    # Get only hash relevant options
    # Filter out paths
    toHash = @Options.reject { |i| i =~ %r{.*/.*(/|$)}i }

    # Reject some known keys
    toHash.delete :epoch

    SHA3::Digest::SHA256.hexdigest(JSON.generate(toHash).to_s)[0..length - 1]
  end

  # Creates a name for precompiled binary (if this doesn't use a
  # commit, it's possible to use :epoch variable for making sure people use newer version)
  def getNameForPrecompiled
    sanitizeForPath("#{@Name}_#{@Version}_" +
                    (@BranchEpoch ? "sv_#{@BranchEpoch}_" : '') +
                    "opts_#{optionsHash}")
  end
end

# Dependency for making cmake based dependencies shorter
class StandardCMakeDep < BaseDep
  def initialize(name, foldername, args)
    super(name, foldername, args)

    # Sensible default, overwrite if not correct
    @CMakeListFolder = '../'
  end

  def DoSetup
    onError 'StandardCMakeDep derived class has no @CMakeListFolder' unless @CMakeListFolder

    FileUtils.mkdir_p 'build'

    Dir.chdir('build') do
      return runCMakeConfigure @Options, @CMakeListFolder, buildType: buildType
    end
  end

  def DoCompile
    Dir.chdir('build') do
      return TC.runCompiler buildType
    end
  end

  def DoInstall
    Dir.chdir('build') do
      return cmakeUniversalInstallHelper
    end
  end
end

# Dependency that needs to be downloaded as a zip
# Derived classes will need to set these in the constructor:
# @UnZippedName = "a"
# @LocalFileName = "a.tar.gz"
# @LocalPath = File.join(CurrentDir, @LocalFileName)
# @DownloadURL = "http://something"
# @DLHash = ""
# @DLHashType = 1 (see downloadURLIfTargetIsMissing in RubyCommon.rb)
class ZipDLDep < BaseDep
  attr_reader :ZipType

  def initialize(name, foldername, args, zipType: :tar)
    super(name, foldername, args)

    @DLHashType = 1
    @ZipType = zipType
  end

  def RequiresClone
    return true unless File.exist?(@Folder)

    return true unless File.exist?(@LocalPath)

    false
  end

  def IsUsingSpecificCommit
    false
  end

  def DoClone
    info "Downloading dependency #{@Name} as a file: #{@DownloadURL}"

    downloadURLIfTargetIsMissing(
      @DownloadURL,
      @LocalPath, @DLHash, @DLHashType
    )

    # Unzip it
    Dir.chdir(CurrentDir) do
      # Remove the old unzip attempt
      if File.exist?(@UnZippedName)
        info "Deleting previous unzip attempt: #{@UnZippedName}"
        FileUtils.rm_rf @UnZippedName, secure: true
      end

      case @ZipType
      when :tar
        unless runSystemSafe('tar', '-xvf', @LocalFileName)
          onError 'failed to run tar on zip: ' + @LocalFileName
        end
      when :zip
        Zip::File.open(@LocalFileName) do |zip_file|
          zip_file.each do |entry|
            # Extract
            puts "Extracting #{entry.name}"
            entry.extract
          end
        end
      when :p7zip
        unless runSystemSafe(p7zip, 'x', @LocalFileName)
          onError 'failed to run 7zip on zip: ' + @LocalFileName
        end
      else
        onError "Invalid zip type used in ZipDLDep: #{@ZipType}"
      end

      expandedUnzip = File.absolute_path(@UnZippedName)

      unless File.exist?(expandedUnzip)
        onError "Unzipping file didn't create expected folder '#{expandedUnzip}'"
      end

      if expandedUnzip != @Folder
        info "Renaming unzipped folder: #{expandedUnzip} => #{@Folder}"
        FileUtils.rm_rf @Folder, secure: true
        FileUtils.mv expandedUnzip, @Folder
      end
    end

    unless File.exist?(@Folder)
      onError "Failed to create wanted directory from downloaded zip (#{@DownloadURL})"
    end
    true
  end

  def DoUpdate
    # RequiresClone and DoClone already handle updating the link in the constructor
    true
  end

  def ChangeZipType(zipType)
    @ZipType = zipType
  end

  def GetExtensionForZipType
    case @ZipType
    when :tar
      # this isn't the only possible value with tar
      '.tar.bz2'
    when :tar_xz
      '.tar.xz'
    when :zip
      '.zip'
    when :p7zip
      '.7z'
    else
      onError "unknown zip type: #{@ZipType}"
    end
  end
end

# Combination of zip and cmake
class ZipAndCmakeDLDep < ZipDLDep
  def initialize(name, foldername, args, zipType: :tar)
    super(name, foldername, args, zipType: zipType)

    @CMakeListFolder = '../'
  end

  def DoSetup
    onError 'StandardCMakeDep derived class has no @CMakeListFolder' unless @CMakeListFolder

    FileUtils.mkdir_p 'build'

    Dir.chdir('build') do
      return runCMakeConfigure @Options, @CMakeListFolder, buildType: buildType
    end
  end

  def DoCompile
    Dir.chdir('build') do
      return TC.runCompiler buildType
    end
  end

  def DoInstall
    Dir.chdir('build') do
      return cmakeUniversalInstallHelper
    end
  end
end
