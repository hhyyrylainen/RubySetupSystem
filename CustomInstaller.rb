# Supports installing libraries that don't have proper crossplatform
# installation
require 'fileutils'

class CustomInstaller

  # @param basepath Is the target folder to install to
  # @param sourceroot Is the main level folder relative to which include files are copied
  def initialize(basepath, sourceroot)
    @BasePath = basepath
    @SourcePath = sourceroot

    if not File.exists? @SourcePath
      onError "Installer root path doesn't exist: #{@SourcePath}"
    end

    FileUtils.mkdir_p @BasePath

    @Includes = []
    @Libraries = []
    
  end

  # Add include files to install
  def addInclude(includes)
    
  end

  # Add library files to install (these are *.lib, *.dll, *.a or *.so files)
  def addLibrary(libraryfiles)
  
  end

  def run

    if @Includes.empty? and @Libraries.empty?
      onError "CustomInstaller has empty file lists"
    end

    info "Starting custom install library files to: #{@BasePath}"

    
    onError "todo"
    success "Done running install"
    
  end

end
