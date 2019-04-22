# This file contains general things for supporting precompiled dependencies
require 'fileutils'

# Generates a string that describes the current platform and compiler
def describePlatform
  TC.name.gsub(' ', '_')
end



# Class that handles the definition of a precompiled dependency and applying it if wanted
# It is required that THIRD_PARTY_INSTALL points to the folder where precompiled files
# should be unzipped to
class PrecompiledDependency

  attr_reader :FullName, :URL, :RelativeUnPack, :Hash, :ZipName
  
  def initialize(name, url, hash, relativeunpack = "")

    @FullName = name
    @ZipName = name + ".7z"
    @URL = url + @ZipName
    @Hash = hash
    @RelativeUnPack = relativeunpack

    if !@Hash || @Hash.length <= 10
      onError "PrecompiledDependency has no valid hash: " + @Hash
    end
  end

  # Retrieves this dependency
  def retrieve

    info "Retrieving precompiled dependency " + @FullName

    FileUtils.mkdir_p dlFolder

    download targetFile
    success "Done"
    
  end

  def download(target)
    downloadURLIfTargetIsMissing @URL, target, @Hash, 2
  end

  def to_s
    %{dependency "#{@FullName}" from #{@URL} with hash #{@Hash}}
  end

  def dlFolder
    File.join CurrentDir, "PrecompiledCache"
  end

  def targetFile
    File.join dlFolder, @ZipName
  end

  # Unzips this to where it should go
  def install

    FileUtils.mkdir_p THIRD_PARTY_INSTALL

    Dir.chdir(THIRD_PARTY_INSTALL){

      info "Unzipping precompiled '#{@FullName}' to #{THIRD_PARTY_INSTALL}"

      # Overwrite everything
      runOpen3Checked(*p7zip, "x", targetFile, "-aoa")

      # TODO:
      # puts "Verifying that unzipping created wanted files"

      success "Done unzipping"
    }
    
  end
  
end


