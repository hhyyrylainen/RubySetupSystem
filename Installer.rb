# Installer class
## Install runner
class Installer
  # basedepstoinstall Is an array of BaseDep derived objects that install
  # the required libraries
  def initialize(basedepstoinstall)

    @Libraries = basedepstoinstall

    if not @Libraries.kind_of?(Array)
      onError("Installer passed something else than an array")
    end

    @SelfLib = nil
  end

  # Adds an extra library
  def addLibrary(lib)

    @Libraries.push lib
  end

  # If the main project being built is available as a RubySetupSystem
  # library it can be added here to install its dependencies
  def registerSelfAsLibrary(selflib)

    @SelfLib = selflib
  end

  def doPrerequisiteInstalls(lib)
    # Verifying that it works
    begin
      # Require that this list method exists
      deps = lib.depsList
    rescue RuntimeError
      # Not used on platform. Should always be used on non-windows
      if !OS.windows?
        onError "Dependency #{lib.Name} prerequisites fetch failed. This needs to " + 
                "work on non-windows platforms"
      end
      
      return
    end
    
    onError "empty deps" if !deps
    
    if !DoSudoInstalls or SkipPackageManager

      warning "Automatic dependency installation is disabled!: please install: " +
              "'#{deps.join(' ')}' manually for #{lib.Name}"
    else
      
      # Actually install
      info "Installing prerequisites for #{lib.Name}..."
      
      lib.installPrerequisites
      
      success "Prerequisites installed."
      
    end    
  end

  # Runs the whole thing
  # calls onError if fails
  def run

    success "Starting RubySetupSystem run."

    if not OnlyMainProject and
      @Libraries.each do |x|

        if x.respond_to?(:installPrerequisites)
          
          self.doPrerequisiteInstalls x
        end
      end
    end

    if not SkipPullUpdates and not OnlyMainProject
      puts ""
      info "Retrieving dependencies"
      puts ""
      
      @Libraries.each do |x|

        x.Retrieve
        
      end

      puts ""
      success "Successfully retrieved all dependencies. Beginning compile"
      puts ""
    else

      if SkipPullUpdates
        warning "Not updating dependencies. This may or may not work"
      end
      
    end

    if not OnlyMainProject

      info "Configuring dependencies"

      @Libraries.each do |x|

        x.Setup
        x.Compile
        x.Install

        if x.respond_to?(:Enable)
          x.Enable
        end
        
        puts ""
        
      end

      puts ""
      success "Dependencies done, configuring main project"
    end

    puts ""
    
    if OnlyDependencies

      success "All done. Skipping main project"
      exit 0
    end

    # Install project dependencies
    if @SelfLib
      self.doPrerequisiteInstalls @SelfLib
    end

    # Make sure dependencies are enabled even if they aren't built this run
    @Libraries.each do |x|

      if x.respond_to?(:Enable)
        x.Enable
      end
    end
    
  end
  
end
