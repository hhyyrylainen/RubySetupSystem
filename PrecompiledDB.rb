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
    "2a9a2b4e7ed8ff99f811b767a224f50c0ee2417438b090ac6202dbf7473a4148"
  ),

  ####################
  # cAudio
  PrecompiledDependency.new(
    "cAudio_master_opts_011351eaf0b6_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "02ff2cba48f731339631768b9a5463283a17a914564e196135de5de5e1737404"
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
    "be09a169c9b23a7e36e56a53075de2a3dc7aa7872cda4b6c6a115f3f899f054e"
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
    "7004dc2adfdb3feb1725605278949d25609199982ba0347988ed34c623854779"
  ),

  ####################
  # FreeType
  PrecompiledDependency.new(
    "FreeType_2_8_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "d49dc4342394c6f5d4706ffae440f6fc0c25ccb7250ce1bfe57ba2a23f139658"
  ),
  
  ####################
  # Newton
  PrecompiledDependency.new(
    "Newton_Dynamics_6d9be8ccce94845d8738244f5fd9da19c53886ca_opts_f056e6310903_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "2565ba6e4177ea8ba28a6165ae4ed73f0e52ea15eaed2c50407dadade5385b36"
  ),

  ####################
  # Ogre
  PrecompiledDependency.new(
    "Ogre_v2-1_opts_57b7e99f7612_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "03192a1e0f5fa6b1e3679dbeaf417fba5b5483ca484d9fc994aaed00e34326fa"
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
    "8de4294310cbad69e19c7805471dac6130c514c004732090260aa73da1d9f265"
  ),

  ####################
  # SFML
  PrecompiledDependency.new(
    "SFML_2_4_x_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "83cab0bf17c06991eaf28d6f3d6ec6a48108259b99603e401726cd7024ed1e43"
  ),

  ####################
  # ZLib
  PrecompiledDependency.new(
    "zlib_1_2_11_opts_ca4510738395_windows_Visual_Studio_15_2017_Win64",
    "https://boostslair.com/rubysetupsystem/precompiled/",
    "4a1a6f16480f7b93687d8fbf8e786fbf185d4710efcda2ec39a8c72885ff999c"
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
