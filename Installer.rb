require 'etc'

# Install runner. This is responsible for bulk of the things that RubySetupSystem does
class Installer
  # basedepstoinstall Is an array of BaseDep derived objects that install
  # the required libraries
  def initialize(basedepstoinstall)
    @libraries = basedepstoinstall

    # TODO: change to checking respond_to? each
    onError('Installer passed something else than an array') unless @libraries.is_a?(Array)

    @self_lib = nil
  end

  # Adds an extra library
  def addLibrary(lib)
    @libraries.push lib
  end

  # If the main project being built is available as a RubySetupSystem
  # library it can be added here to install its dependencies
  def registerSelfAsLibrary(selflib)
    @self_lib = selflib
  end

  def enabled_libs
    @libraries.select { |i| lib_enabled i }
  end

  def do_prerequisite_installs(lib)
    # Verifying that it works
    begin
      # Require that this list method exists
      deps = lib.depsList
    rescue RuntimeError
      # Not used on platform. Should always be used on non-windows
      unless OS.windows?
        onError "Dependency #{lib.Name} prerequisites fetch failed. This needs to " \
                'work on non-windows platforms'
      end

      return
    end

    onError 'empty deps' unless deps

    if !DoSudoInstalls || SkipPackageManager

      warning 'Automatic dependency installation is disabled!: please install: ' \
              "'#{deps.join(' ')}' manually for #{lib.Name}"
    else

      # Actually install
      info "Installing prerequisites for #{lib.Name}..."

      lib.installPrerequisites

      success 'Prerequisites installed.'

    end
  end

  def install_prerequisites
    return if OnlyMainProject

    enabled_libs.each do |x|
      do_prerequisite_installs x if x.respond_to?(:installPrerequisites)
    end
  end

  def retrieve_deps(precompiled)
    info "Using #{precompiled.length} precompiled libraries"

    if !SkipPullUpdates && !OnlyMainProject
      puts ''
      info 'Retrieving dependencies'
      puts ''

      enabled_libs.each do |x|
        # Precompiled is handled later
        next if precompiled.include? x.Name

        x.Retrieve
      end

      puts ''
      success 'Successfully retrieved all dependencies. Beginning compile'
      puts ''
    else

      warning 'Not updating dependencies. This may or may not work' if SkipPullUpdates

      # Make sure the folders exist, at least
      enabled_libs.each do |x|
        # Precompiled is handled later
        next if precompiled.include? x.Name

        if x.RequiresClone
          info 'Dependency is missing, downloading it despite update pulling is disabled'
          x.Retrieve
        elsif x.IsUsingSpecificCommit
          info "Making sure dependency '#{x.Name}' has right commit even though " \
               'pull updates is disabled'
          x.MakeSureRightCommitIsCheckedOut
        end
      end
    end

    return if precompiled.empty?

    puts ''
    info 'Retrieving precompiled dependencies'
    puts ''

    precompiled.each do |_key, p|
      p.retrieve
    end

    puts ''
    success 'Successfully retrieved precompiled'
    puts ''
  end

  # Runs the whole thing
  # calls onError if fails
  def run
    success 'Starting RubySetupSystem run.'

    install_prerequisites

    # Determine what can be precompiled
    precompiled = {}

    enabledLibs.each do |x|
      pre = getSupportedPrecompiledPackage x

      precompiled[x.Name] = pre if pre
    end

    retrieve_deps precompiled

    unless OnlyMainProject

      info 'Configuring and building dependencies'

      enabledLibs.each do |x|
        if precompiled.include? x.Name

          puts "Extracting precompiled dependency #{x.Name}"
          precompiled[x.Name].install

        else
          x.Setup
          x.Compile
          x.Install
        end

        x.Enable if x.respond_to?(:Enable)

        puts ''
      end

      puts ''
      success 'Dependencies done, configuring main project'
    end

    puts ''

    if OnlyDependencies

      success 'All done. Skipping main project'
      exit 0
    end

    if $options.include?(:projectFullParallel)
      $compileThreads = if $options.include?(:projectFullParallelLimit)
                          [Etc.nprocessors, $options[:projectFullParallelLimit]].min
                        else
                          Etc.nprocessors
                        end

      info "Using fully parallel build for main project, threads: #{$compileThreads}"
    end

    # Install project dependencies
    do_prerequisite_installs @self_lib if @self_lib

    # Make sure dependencies are enabled even if they aren't built this run
    @libraries.each do |x|
      x.Enable if x.respond_to?(:Enable)
    end

    # The project compile script is allowed to run next
  end

  # Returns true if lib is enabled (ie. not disabled)
  def lib_enabled(lib)
    # Disable check
    if NoSpecificDeps
      NoSpecificDeps.each do |selected|
        if selected.casecmp(lib.Name).zero? || selected.casecmp(lib.FolderName).zero?
          info "Dependency #{lib.Name} was specified to be skipped"
          return false
        end
      end
    end

    if !OnlySpecificDeps
      true
    else

      OnlySpecificDeps.each do |selected|
        if selected.casecmp(lib.Name).zero? || selected.casecmp(lib.FolderName).zero?
          return true
        end
      end

      info "Dependency #{lib.Name} is not selected to be setup"
      false
    end
  end
end
