# Methods for copying libraries including symbolic links to them

require_relative "RedistributableLibsList.rb"

# Copies files to a directory following all symlinks but also copying the symlinks if their
# names are different
# Also if stripfiles is true will run strip on each of the files
def copyPossibleSymlink(path, target, stripfiles = false, log = false)

  if not File.exist?(path)
    warning "Skipping copying non-existant file: #{path}" if log
    return
  end

  info "Copying file: #{path} to #{target}" if log 
  
  if File.lstat(path).symlink?
    
    link = File.join(File.dirname(path), File.readlink(path))

  else
    link = nil
  end

  if link

    info "File #{path} is a symlink to #{link}" if log

    if not File.basename(link) == File.basename(path)

      # Symlink target has a different name, so copy the symlink
      #FileUtils.cp path, target
      linkname = File.join(target, File.basename(path)) 
      FileUtils.ln_sf File.basename(link), linkname

      if not File.lstat(linkname).symlink?
        onError "Link creation failed (#{linkname} => #{File.basename(link)})"
      end
      
      info "Created symlink #{linkname} pointing to #{File.basename(link)}" if log
    end

    # Follow the link
    info "Following symlink to #{link}" if log
    copyPossibleSymlink(link, target, stripfiles, log)
    
  else

    info "Copying plain file: #{path}" if log
    
    # Plain old file
    FileUtils.cp path, target
    
    if stripfiles
      runOpen3Checked "strip", File.join(target, File.basename(path))
      info "Stripped file #{File.join(target, File.basename(path))}" if log
    end
  end
end

HandledLibraries = []

# Copies a dependency library to target directory following all symlinks along the way
# Ignores some common things that CMake adds that aren't actually libraries
def copyDependencyLibraries(libs, target, strip, log)

  libs.each do |lib|

    # Skip empty stuff
    if not lib or lib.empty? or lib == "optimized" or lib == "debug" or lib =~ /-l.*/
      next
    end

    # Skip duplicates
    if HandledLibraries.include? lib
      next
    end

    onError "Dependency library file #{lib} doesn't exist" if not File.exists? lib

    copyPossibleSymlink(lib, target, strip, log)
    HandledLibraries.push lib
    
  end
end

# Finds library matching regex and returns that folder
def findLibraryFolder(libs, regex)

  libs.each do |lib|

    if lib =~ regex

      return File.dirname lib
      
    end
  end

  "didn't find library matching regex"
end



# Uses ldd on a file to find dependency libraries
def lddFindLibraries(binary)

  result = []

  libs = `ldd "#{binary}"`

  libs.each_line do |line|

    line.strip!

    if line.empty?
      next
    end

    if match = line.match(/\s+=>\s+(.*?\.so[^\s]*)/i)
      
      lib = match.captures[0]

      # Skip non-existing filles
      if not File.exist? lib or not Pathname.new(lib).absolute?
        next
      end

      if not isGoodLDDFound lib
        next
      end

      # And finally skip ones that are in the staging or build directory
      if not isInSubdirectory(CurrentDir, lib)

        puts "ldd found library: " + lib 

        result.push lib
        
      end
    end
  end

  result
end




#
# Library specific finder
#

# Finds CEGUI plugins and adds them to the list
def findCEGUIPlugins(libs, ceguiversion)

  ceguiDir = findLibraryFolder(libs, /.*CEGUIBase.*/i)

  ceguiDir = File.join(ceguiDir, "cegui-#{ceguiversion}.0")
  
  if not File.exists? ceguiDir
    onError "Failed to find CEGUI root directory for dynamic libs (#{ceguiDir})"
  end

  info "Looking for CEGUI plugins in #{ceguiDir}"

  Dir.chdir(ceguiDir) do

    Dir["*.so"].each do |ceguilib|

      libs.push File.absolute_path(ceguilib)
      
    end
    
  end
  
end

# Finds Ogre plugins and adds them to the list
# Plugin names is an array containing names like 'RenderSystem_GL' and 'Plugin_ParticleFX'
def findOgrePlugins(libs, pluginnames)

  ogreDir = File.join(findLibraryFolder(libs, /.*OgreMain.*/i), "OGRE")

  if not File.exists? ogreDir
    onError "Failed to find Ogre root directory for plugins (#{ogreDir})"
  end

  pluginnames.each do |lib|

    # This is a symbolic link but the dependency copy function should figure it out
    file = File.absolute_path(File.join(ogreDir, lib + ".so"))

    onError "Ogre library #{file} doesn't exist" if not File.exists? file
    
    libs.push file
    
  end
  
end

# Boost thread library is a ld script. This finds the actual libraries
def findRealBoostThread(libs)

  boostDir = findLibraryFolder(libs, /.*boost_thread.*/i)

  if not File.exists? boostDir
    onError "Failed to find boost_thread directory for getting actual libraries (#{boostDir})"
  end
  
  # Copy the actual files
  Dir.chdir(boostDir) do

    Dir["libboost_thread.*"].each do |lib|

      libs.push File.absolute_path(lib)
      
    end
    
  end
end
