# List of precompiled things. Could maybe be better if this was online
# somewhere and was downloaded (as JSON to not run untrusted code)
require_relative 'PrecompiledDependency.rb'

# Dependency is a BaseDep derived class that can be used with a dependency
def getSupportedPrecompiledPackage(dependency)

  # Immediately skip if not used
  if $usePrecompiled == false
    return
  end

  # This always prints a warning if not found
  files = dependency.getInstalledFiles

  if !files
    # Not supported
    return nil
  end

  # Supported, now just need to find one matching ourPlatform
  ourPlatform = describePlatform
  fullName = dependency.getNameForPrecompiled + "_" + ourPlatform
  
  package = getPrecompiledByName(fullName)
  
  if !package
    warning "No precompiled release of #{dependency.Name} found for current platform: " +
            fullName
    # TODO: list close matches
    return
  end

  info "Found precompiled version of #{dependency.Name}: " + fullName

  # Found. Determine what to do based on UsePrecompiled
  if $usePrecompiled != true
    # Ask
    moveForward = false
    while !moveForward
      puts ""
      info "A precompiled version of #{dependency.Name} is available for your platform."
      puts "What would you like to do? (You can skip this question in the future " +
           "by specifying --precompiled or --no-precompiled on the command like)"
      puts ""
      puts "You can run this setup again to make a different choice if something doesn't work."
      puts "You can also press CTRL+C to cancel setup."
      puts ""
      puts "[Y]es  - use all available precompiled libraries\n" +
           "[N]o   - don't use precompiled libraries\n" + 
           "[O]nce - use precompiled for this and ask again for next one \n" + 
           "[S]kip - don't use precompiled for this dependency but ask again for next one\n"
      
      puts ""
      print "> "
      choice = STDIN.gets.chomp.upcase

      puts "Selection: #{choice}"

      case choice
      when "Y"
        puts "Using this precompiled and all other ones"
        moveForward = true
        $usePrecompiled = true
      when "O"
        puts "Using this precompiled dependency"
        moveForward = true
      when "N"
        puts "Not using any precompiled dependencies"
        $usePrecompiled = false
        return nil        
      when "S"
        puts "Skipping using this precompiled dependency"
        return nil
      else
        puts "Invalid. Please type in Y, N, O or S"
      end
    end
  end

  # Using
  info "Using precompiled binary for #{dependency.Name}"
  package
end

BigListOfPrecompiledStuff = [

  ####################
  # AngelScript
  PrecompiledDependency.new(
    "AngelScript_2_32_0_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "e7d36d0c53dba1d09dd1ddf1ae9ad3952753bd8efe74cbe5eda4885142378267"
  ),

  ####################
  # CEGUI
  PrecompiledDependency.new(
    "CEGUI_7f1ec2e2266e_opts_8cfea9cd347a_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "921eaf18c202a8850a2f14f8162279315492d6db0e1c5564a90760ebd140c534"
  ),

  ####################
  # FFmpeg
  PrecompiledDependency.new(
    "FFmpeg_release_3_3_opts_2f846f8da7dc_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "b252d311565ed6b3efa11cf06ef3eaec7942fe80635c8b11f3d3ae5e5def2dcf"
  ),

  ####################
  # FreeImage
  PrecompiledDependency.new(
    "FreeImage_master_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "8671bdd8500188d54d7978f118b8ce427ea0ca5a0333fc496d0e4b11d3ea35a2"
  ),
  PrecompiledDependency.new(
    "FreeImage_master_sv_2_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "6c32eb67cfd78491ad2e036a42fe2af2331900e6b6503ca1e7bcb51245b85b51"
  ),
  PrecompiledDependency.new(
    "FreeImage_master_sv_3_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "0d9b91b364064ec6925082d900d3d07bbd3e3bd18e5741b5f21d7e38e4adee8a"
  ),

  ####################
  # FreeType
  PrecompiledDependency.new(
    "FreeType_2_8_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "24a4225e6efc1d15e59432ffc3917d5e45db6ed93b7c24e53f870c7dc9c89c8f"
  ),
  
  ####################
  # Newton
  PrecompiledDependency.new(
    "Newton_Dynamics_e60733c5a6eafd952b7b981f3c6aa06ccc5b326e_opts_" +
    "f056e6310903_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "c7c76d2798d836baff5c025e670b2d92e5aa4d8d5af9a608a0491037e3084a97"
  ),

  ####################
  # Ogre
  PrecompiledDependency.new(
    "Ogre_v2-1_opts_57b7e99f7612_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "7e840db847276d35df8e3a77ad37881f8cce743a89f411f219797b60cfd80605"
  ),

  ####################
  # SDL2
  PrecompiledDependency.new(
    "SDL2_release-2_0_6_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "839c6b48f0279d7e18face17fbe15ce06443186c816ec5104c13435fcc13bab6"
  ),

  ####################
  # SFML
  PrecompiledDependency.new(
    "SFML_2_4_x_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "b95d716a9b33ca7a079cdc863af27696c12b6b11bd3e59a7a6bdd808e0aedec0"
  ),

  ####################
  # ZLib
  PrecompiledDependency.new(
    "zlib_1_2_11_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "b2faec0ffa827de1736b5f9a504947082b816bc8bb218e18555e812617661ec8"
  ),
]

def getPrecompiledByName(name)
  # puts "Looking for precompiled: " + name
  BigListOfPrecompiledStuff.each{|p|

    # puts "Checking:" + p.FullName
    if p.FullName == name
      return p
    end
  }

  nil
end
