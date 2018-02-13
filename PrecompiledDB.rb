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
    "a0b21ccf829f8fd6bf0b85c79bde6e2cf6343694ac4c85ed52d45c338c5c2a9c"
  ),

  PrecompiledDependency.new(
    "AngelScript_2_32_0_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "9430a6992d5416c6f1a8668d251597663174751aa2fb9fbfa22ed06d54ec1a9d"
  ),

  PrecompiledDependency.new(
    "SFML_2_4_x_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "ea94b311daa13c6cd9f562f2b384e96c42d232795df3fd4f41c5cb559905e8d8"
  ),

  PrecompiledDependency.new(
    "FFmpeg_release_3_3_opts_925a0a52f22b_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "ea2b39d01edfe18202a98419f3b18ee598233bc8048ba79aa1185bd02314b678"
  ),

  PrecompiledDependency.new(
    "zlib_1_2_11_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "e3c52ac2c923cd164e88981445d25a02d91bcc28d66bf6918c109419489fb717"
  ),

  PrecompiledDependency.new(
    "FreeImage_master_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "e4293582344f4ee8fb2604b4f36b7788d73c04309b6f8e592b705193b207aa98"
  ),


  PrecompiledDependency.new(
    "SDL2_release-2_0_6_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "76d4d1d26e237e62b1fa2403a5454b55179950e0fb433658c15031ae7c7c6368"
  ),

  PrecompiledDependency.new(
    "FreeType_2_8_opts_0fe2c1a5b1a1_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "27fe04e5213de5ddcb16fc1c0874e2d4e18205d825b5810eb2b075532698b7d7"
  ),

  PrecompiledDependency.new(
    "Ogre_v2-1_opts_d4df521f2849_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "a73f8b0fa7e220f8d3df48e086c1acd298927c35bfbf79a8954c00eb3f7dc7d3"
  ),

  PrecompiledDependency.new(
    "CEGUI_7f1ec2e2266e_opts_e42b439ab66a_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "e14fa9219ed78eb327ff43e7e877814b16639850c8ba650b2546842b2c114de4"
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
