# List of precompiled things. New database implementation is in the Database folder
require_relative 'Database/Database'

# Dependency is a BaseDep derived class that can be used with a dependency
def getSupportedPrecompiledPackage(dependency)
  # Immediately skip if not used
  return if $usePrecompiled == false

  files = dependency.getInstalledFiles

  unless files
    # Not supported
    return nil
  end

  # Supported, now just need to find one matching ourPlatform
  ourPlatform = describePlatform
  fullName = dependency.getNameForPrecompiled + '_' + ourPlatform

  package = getPrecompiledByName(fullName)

  unless package
    warning "No precompiled release of #{dependency.Name} found for current platform: " +
            fullName
    # TODO: list close matches
    return
  end

  info "Found precompiled version of #{dependency.Name}: " + fullName

  package.precompiled_this_is_for dependency

  # Found. Determine what to do based on UsePrecompiled
  if $usePrecompiled != true
    # Ask
    moveForward = false
    until moveForward
      puts ''
      info "A precompiled version of #{dependency.Name} is available for your platform."
      puts 'What would you like to do? (You can skip this question in the future ' \
           'by specifying --precompiled or --no-precompiled on the command like)'
      puts ''
      puts "You can run this setup again to make a different choice if something doesn't work."
      puts 'You can also press CTRL+C to cancel setup.'
      puts ''
      puts "[Y]es  - use all available precompiled libraries\n" \
           "[N]o   - don't use precompiled libraries\n" \
           "[O]nce - use precompiled for this and ask again for next one \n" \
           "[S]kip - don't use precompiled for this dependency but ask again for next one\n"

      puts ''
      print '> '
      choice = STDIN.gets.chomp.upcase

      puts "Selection: #{choice}"

      case choice
      when 'Y'
        puts 'Using this precompiled and all other ones'
        moveForward = true
        $usePrecompiled = true
      when 'O'
        puts 'Using this precompiled dependency'
        moveForward = true
      when 'N'
        puts 'Not using any precompiled dependencies'
        $usePrecompiled = false
        return nil
      when 'S'
        puts 'Skipping using this precompiled dependency'
        return nil
      else
        puts 'Invalid. Please type in Y, N, O or S'
      end
    end
  end

  # Using
  info "Using precompiled binary for #{dependency.Name}"
  package
end

def getPrecompiledByName(name)
  databases = getDefaultDatabases

  databases.each  do |db|
    precompiled = db.getPrecompiled name

    return precompiled if precompiled
  end

  nil
end
