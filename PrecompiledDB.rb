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
    "AngelScript_2482_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "4932ec2ca2f6481e578e092cf6218428d5e1d67160e1cc9ffb29f43a1ace7263"
  ),

  ####################
  # OpenAL soft
  PrecompiledDependency.new(
    "OpenAL_Soft_master_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "d2ed1dfb6d4d34db6550764f05b70144a918e414035aa264d87f6f383626d5a8"
  ),

  ####################
  # cAudio
  PrecompiledDependency.new(
    "cAudio_master_opts_011351eaf0b6_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "f04fce8e31349d99e0cf449dd6589bcd590ef4e73e1c7a677c6a210be9d4e622"
  ),

  ####################
  # CEF
  PrecompiledDependency.new(
    "CEF_3_3325_1756_g6d8faa4_opts_3f87dc45b818_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "28bb3a9f709e683b5eb52e4133cf99c1110dc2249d4da056505001f5df5535f7"
  ),  

  ####################
  # CEGUI
  PrecompiledDependency.new(
    "CEGUI_7f1ec2e2266e_opts_8cfea9cd347a_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "894d515a4d66a3029f87d3a9d6ae50f981e3eba07c1317e0dcfb6f58a6cb0ff0"
  ),

  ####################
  # FFmpeg
  PrecompiledDependency.new(
    "FFmpeg_release_3_3_opts_2f846f8da7dc_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "57cb56606cd9b68883b5208832cae56b4b2a612fa22ff9b1948b3bd8d3c527c5"
  ),

  ####################
  # FreeImage
  PrecompiledDependency.new(
    "FreeImage_master_sv_3_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "e969e6d34636b9963c9e88e51e24604a6f75daf72c92922946b45511b49e6232"
  ),

  ####################
  # FreeType
  PrecompiledDependency.new(
    "FreeType_2_8_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "029a54dc5f07a416e120154d3fdc56f99a7d12ff6063f8fa976d5354637c58a5"
  ),
  
  ####################
  # Newton
  PrecompiledDependency.new(
    "Newton_Dynamics_6d9be8ccce94845d8738244f5fd9da19c53886ca_opts_f056e6310903_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "4960c8f5c4fc5829958adae0c64904c0290569c815ef93d15ee5ca05b4206b4d"
  ),

  ####################
  # Ogre
  PrecompiledDependency.new(
    "Ogre_v2-1_opts_21186a65e415_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "f0831022edb469d4099d52161cd31e4131f86292405343c15822994c3d8502b5"
  ),

  ####################
  # OpenAL Soft
  PrecompiledDependency.new(
    "OpenAL_Soft_master_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "7dbbdd853bdd7db25ffaa1369ce794079b233b89c36e0742dc10558a0fc4a99a"
  ),

  ####################
  # SDL2
  PrecompiledDependency.new(
    "SDL2_release-2_0_6_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "119a64500442537148c93bea2d2cf097c9edec37ec64cd497d8703963e646ce1"
  ),

  ####################
  # SFML
  PrecompiledDependency.new(
    "SFML_2_4_x_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "685c477023f7154410edd8addc4f3c649903830a9fd5e2fca9825dcc25dea89b"
  ),

  ####################
  # ZLib
  PrecompiledDependency.new(
    "zlib_1_2_11_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "938f50ff0b64cec5a3357637893ce2dbd83436fcf8185dea4a8654cc424f0b36"
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
