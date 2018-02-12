# This file contains general things for supporting precompiled dependencies

# Generates a string that describes the current platform and compiler
def describePlatform
  TC.name.gsub(' ', '_')
end



# Class that handles the definition of a precompiled dependency and applying it if wanted
class PrecompiledDependency

  attr_reader :FullName, :URL, :RelativeUnPack, :Hash
  
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

end


