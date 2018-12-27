# Supports installing libraries that don't have proper crossplatform
# installation
require 'fileutils'

class CustomInstaller

  attr_accessor :IncludeFolder

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

    # Target folders
    @IncludeFolder = "include"
    @ExtraIncludePrefix = ""
    @Libfolder = "lib"
  end

  # Add include files to install
  def addInclude(*includes)
    @Includes.push *includes
  end

  # Add library files to install (these are *.lib, *.dll, *.a or *.so files)
  def addLibrary(*libraryFiles)
    @Libraries.push *libraryFiles
  end

  # Sets an extra path prefix for includes
  def setIncludePrefix(prefix)
    @ExtraIncludePrefix = prefix
  end

  def setIncludeFolder(include)
    @IncludeFolder = include
  end

  def run

    if @Includes.empty? and @Libraries.empty?
      onError "CustomInstaller has empty file lists"
    end

    # Flatten the things
    @Includes.flatten!
    @Libraries.flatten!

    info "Starting custom install library files to: #{@BasePath}"
    count = 0
    
    includeTarget = File.join(@BasePath, @IncludeFolder)

    if @ExtraIncludePrefix
      includeTarget = File.join(includeTarget, @ExtraIncludePrefix)
    end

    @Includes.each{|f|

      relativePart = Pathname.new(f).relative_path_from(Pathname.new @SourcePath)

      # relativePart includes the filename so strip that
      targetFolder = File.join(includeTarget, relativePart.dirname)

      FileUtils.mkdir_p targetFolder

      copyPreserveSymlinks f, targetFolder
      count += 1
    }

    libraryTarget = File.join(@BasePath, @Libfolder)

    if !@Libraries.empty?
      FileUtils.mkdir_p libraryTarget
    end

    @Libraries.each{|f|

      copyPreserveSymlinks f, libraryTarget
      count += 1
    }
    
    success "Done running install. Copied #{count} files/folders"
    true
  end

end
