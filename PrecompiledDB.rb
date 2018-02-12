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

  PrecompiledDependency.new(
    "Newton_Dynamics_e60733c5a6eafd952b7b981f3c6aa06ccc5b326e_opts_b3f626757418" +
    "_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "adcdc38a3ddd0eda1610605d8dd1bc6605f898b112b3c5df22fff5a1490faad9"
  ),

  PrecompiledDependency.new(
    "AngelScript_2_32_0_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "0bbba50992be9180f048d2fd4f6702c9f7934cbc04e184abd57092b5b83c72c4"
  ),

  PrecompiledDependency.new(
    "SFML_2_4_x_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "e88569754eae0c4976a53be90693a0a171ae9b19fe24334422d76a671c64a796"
  ),

  PrecompiledDependency.new(
    "FFmpeg_release_3_3_opts_925a0a52f22b_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "03906e9322ee0a00df893799f9b52ed8db89b4707453387bcc6dc1ea1775415f"
  ),

  PrecompiledDependency.new(
    "zlib_1_2_11_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "2a85c407c61f2fed8cd4161ebd1384a9ab358f9fd15200af1da149f7d4c26723"
  ),

  PrecompiledDependency.new(
    "FreeImage_master_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "c98c9591f3d43f6f5c7f04813c4b3235028fad7240e9b24994baea685d03862b"
  ),


  PrecompiledDependency.new(
    "SDL2_release-2_0_6_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "3f5b1968d881989b420f94a16cc423f7528426521b9e1875d0fc0429218c067f"
  ),

  PrecompiledDependency.new(
    "FreeType_2_8_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "5dca62727907e6502b3797c77a83dfc45d4aa193e163d29da284904e37e3bc10"
  ),

  PrecompiledDependency.new(
    "Ogre_v2-1_opts_d4df521f2849_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "13d790613d012d1f52513e458bb8199b2dae95c47bf68874802320030ccede71"
  ),

  PrecompiledDependency.new(
    "CEGUI_7f1ec2e2266e_opts_e42b439ab66a_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "ac902d0614b496bc8731efa43c69859754b53f91ffabcf380461a2c41c8e79d2"
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
