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
    "ef604aab3a7a8653aae48114d5908336edc0c1c90fa83ea1d33b6043a6b20ed8"
  ),

  ####################
  # openal soft
  PrecompiledDependency.new(
    "OpenAL_Soft_master_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "28b5958e434ab19b0b2881eb9690e6824e8b5bb627fc9e60ea627dfaeac21650"
  ),

  ####################
  # cAudio
  PrecompiledDependency.new(
    "cAudio_master_opts_011351eaf0b6_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "54970d941117217819a3f91a34c3d3c7d7c220acb8e811d7a1a11209c929cc47"
  ),

  ####################
  # CEF
  PrecompiledDependency.new(
    "CEF_3_3325_1756_g6d8faa4_opts_3f87dc45b818_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "85f6d2e66af7ddcfbe7f80338f8ea359bbef8a37a2ad478b99c09e88ffef8dce"
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
    "d8ea47177c844dfe24dbbc09c52cefb483761ddb14522e865b1ee318414a9ac0"
  ),

  ####################
  # FreeImage
  PrecompiledDependency.new(
    "FreeImage_master_sv_3_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "10df8b8a54e64adfa9d385cacfcca7b163ac8e9682a63dbd935ad0f3accf9ba8"
  ),

  ####################
  # FreeType
  PrecompiledDependency.new(
    "FreeType_2_8_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "8dab51b3a7979b07637032905185b3b8c04f58d5e094d807133c800c8c7f6ae0"
  ),
  
  ####################
  # Newton
  PrecompiledDependency.new(
    "Newton_Dynamics_6d9be8ccce94845d8738244f5fd9da19c53886ca_opts_f056e6310903_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "50076ddb0225a7eb440bbb67ac07d74186068a31be2c796a6920beeea446e68b"
  ),

  ####################
  # Ogre
  PrecompiledDependency.new(
    "Ogre_v2-1_opts_57b7e99f7612_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "0caf2a05072da4915da5ddd562d0f0a08d829c35ee8ed3575dea08faa004c60f"
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
    "3e78ea3e2dc99720a2f5087d33309ded494993840777a84d6c3cc4d93cc9c2e6"
  ),

  ####################
  # SFML
  PrecompiledDependency.new(
    "SFML_2_4_x_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "b0e4c9d02e5bd8aee92f3971a1e3cb2e76c000d17573cf41b012eafddf67bc6b"
  ),

  ####################
  # ZLib
  PrecompiledDependency.new(
    "zlib_1_2_11_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "68177dbcce70c835dafb7e4f60b36c46d1a3390183517aaf004b2f160945ddae"
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
