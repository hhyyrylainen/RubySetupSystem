#
# Dependency base class
#

require_relative "Helpers.rb"

### Download settings ###
# Standard args that are handled:
# :version => standard git version select
# :installPath => path where to install the built files (if this dep uses install)
# :noInstallSudo => don't use sudo when installing (on windows administrator might be
#     used instead if this isn't specified)
# :options => override project configure options (extraOptions should be used instead)
# :extraOptions => extra things to add to :options, see the individual dependencies
#     as to what specific options they support
# :preCreateInstallFolder => If installPath is specified will create
#     the folder if it doesn't exist
class BaseDep
  attr_reader :Name, :Folder
  
  def initialize(name, foldername, args)

    @Name = name
    
    @Folder = File.join(CurrentDir, foldername)
    @FolderName = foldername

    # Standard args handling
    if args[:options]

      @Options = args[:options]
      puts "#{@Name}: using options: #{@Options}"
    else

      @Options = self.getDefaultOptions
      
    end

    raise AssertionError if !@Options.kind_of?(Array)

    if args[:extraOptions]
      @Options += args[:extraOptions]
      puts "#{@Name}: using extra options: #{args[:extraOptions]}"
    end

    if args[:version]
      @Version = args[:version]
      puts "#{@Name}: using version: #{@Version}"
    end

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
  end

  def RequiresClone
    not File.exist?(@Folder)
  end
  
  def Retrieve
    info "Retrieving #{@Name}"

    Dir.chdir(CurrentDir) do
      
      if self.RequiresClone
        
        info "Cloning #{@Name} into #{@Folder}"

        if not self.DoClone
          onError "Failed to clone repository"
        end

      end

      if not File.exist?(@Folder)
        onError "Retrieve Didn't create a folder for #{@Name} at #{@Folder}"
      end

      if not self.Update
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
      if not self.DoSetup
        onError "Setup failed for #{@Name}. Is a dependency missing? or some other cmake error?"
      end
    end
    success "Successfully created project files for #{@Name}"
  end
  
  def Compile
    info "Compiling #{@Name}"
    Dir.chdir(@Folder) do
      if not self.DoCompile
        onError "#{@Name} Failed to Compile. Are you using a broken version? or has the setup process"+
                " changed between versions"
      end
    end
    success "Successfully compiled #{@Name}"
  end

  def Install
    info "Installing #{@Name}"
    Dir.chdir(@Folder) do
      if not self.DoInstall
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

      askRunSudo "sudo make install"
      
    else

      if @InstallSudo
        warning "Dependency '#{@name}' should have been installed with sudo"
      end
      
      system "make install"
    end

    $?.exitstatus == 0
  end

  def standardGitUpdate

    system "git fetch"
    
    system "git checkout #{@Version}"
    
    gitPullIfOnBranch @Version
    
    $?.exitstatus == 0    
  end
  
  def clearEmptyOptions
    @Options.reject!(&:empty?)
  end
end
