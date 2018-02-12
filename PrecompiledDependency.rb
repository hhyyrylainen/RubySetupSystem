# This file contains general things for supporting precompiled dependencies

# Generates a string that describes the current platform and compiler
def describePlatform
  TC.name.gsub(' ', '_')
end



# Class that handles the definition of a precompiled dependency and applying it if wanted
class PrecompiledDependency

  attr_reader :Name, :Version, :Platform, :URL, :RelativeUnPack
  
  def initialize(name, version, platform, url, relativeunpack = "")

    @Name = name
    @Version = version
    @Platform = platform
    @URL = url
    @RelativeUnPack = relativeunpack
  end

  def matches(platform, error = true)
    if platform != @Platform
      
      if error
        error "Precompiled dependency #{@Name} doesn't match platform (package)#{@Platform} " +
              "!= #{platform}(current system)"
      end
      return false
    end

    true
  end

end


