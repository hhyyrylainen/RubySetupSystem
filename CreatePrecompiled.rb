# Helper file for creating tools for creating pre-compiled
# dependencies to be put into PrecompiledDB
# Any file using this must set PRECOMPILED_INSTALL_FOLDER and create a method:
# dependency_object_by_name(name) that returns the dependency by name
# also if --all option or creating missing is needed also all_dependencies
# needs to be implemented

# If you get errors on windows do `ridk install` and try all the 3 options
# then install this gem
require 'sha3'

require 'optparse'
require 'fileutils'
require 'pathname'

require_relative 'RubyCommon.rb'

require_relative 'PrecompiledDB.rb'

def checkRunFolder(suggested)
  suggested
end

def projectFolder(baseDir)
  baseDir
end

def getExtraOptions(opts)
  if defined? all_dependencies
    opts.on('--all', 'Make packages of all the dependencies') do |b|
      $options[:buildAll] = b
    end

    opts.on('--missing', 'Make packages of the dependencies with missing packages') do |b|
      $options[:buildMissing] = b
    end

    opts.on('--bundle', 'Make a single package of all processed dependencies') do |b|
      $options[:bundle] = b
    end
  end
end

def extraHelp
  puts 'CreatePrecompiled: tool for packaging binaries for others to download ' \
       'using RubySetupSystem'
end

def parseExtraArgs
  $toPackageDeps = ARGV.dup
  ARGV.clear
end

require_relative 'RubySetupSystem.rb'

# Programming error
raise AssertionError unless PRECOMPILED_INSTALL_FOLDER

# Read extraOptions
DependencyInstallFolder = File.join(CurrentDir, PRECOMPILED_INSTALL_FOLDER)

if !$toPackageDeps && !$options[:buildAll] && !$options[:buildMissing]
  onError('CreatePrecompiled: expected a list of dependencies to package, ' \
          'instead got nothing')
end

$stripPackagedFiles = OS.windows? ? false : true

unless File.exist? DependencyInstallFolder
  onError "Didn't find dependency install folder '#{DependencyInstallFolder}'"
end

info 'This is RubySetupSystem precompiled dependency packager'
info "Current platform is #{describePlatform}"

puts ''
puts "Finding precompiled binaries in: #{DependencyInstallFolder}"
puts "Stripping packaged files: #{$stripPackagedFiles}"
puts ''

CurrentPlatform = describePlatform

# Returns true if a file needs to be stripped
def needs_strip(file)
  extension = File.extname file

  return false if File.symlink?(file)

  # Executable on linux
  if !OS.windows? && File.executable?(file)

    _status, output = runOpen3CaptureOutput 'file', file

    return true if output =~ /.*not\sstripped.*/i
  end

  return true if extension =~ /\.a/ || extension =~ /\.so(\.[\d\.]+)?/

  false
end

def strip_files_if_needed(files)
  return [] unless $stripPackagedFiles

  to_restore = []

  files.each do |f|
    next unless needs_strip f

    puts "Stripping file (saving a backup which will be restored afterwards): #{f}"

    original_name = f + '_original'

    FileUtils.mv f, original_name
    to_restore.append(original: f, renamed: original_name)

    params = ['-o', f, original_name]

    # Only remove debug info as otherwise AR (.a) files get their indexes destroyed
    params.append '--strip-debug' if File.extname(f) =~ /\.a/

    # We use 'strip' to also copy the file in addition to stripping so
    # that we don't have to do the copy ourselves
    runOpen3Checked 'strip', *params
    onError 'Strip failed on file: ' + f.to_s unless File.exist? f
  end

  to_restore
end

def restore_stripped_files(to_restore)
  return if to_restore.empty?

  puts 'Restoring original versions of stripped files'
  to_restore.each do |item|
    File.unlink item[:original]
    FileUtils.mv item[:renamed], item[:original]
    puts "Restored: #{item[:original]}"
  end
end

# Packages a single dependency
def package_dependency(dep, bundle_info)
  info "Starting packaging #{dep}"

  instance = if dep.is_a? String
               dependency_object_by_name dep
             else
               dep
             end

  onError "Invalid dependency name: #{dep}" unless instance

  files = instance.getInstalledFiles

  if !files || files.empty?
    error "Dependency '#{dep}' has no files to package"
    return nil
  end

  # Add symbolic link targets
  links_found = true
  total_links = 0
  handled = []

  while links_found

    links_found = false

    files.each  do |f|
      full = File.join(DependencyInstallFolder, f)

      next if handled.include? full

      next unless File.exist?(full) && File.symlink?(full)

      link_target = File.join(File.dirname(f), File.readlink(full))

      unless child_path?(DependencyInstallFolder,
                         File.join(DependencyInstallFolder, link_target))
        onError 'symbolic link to be installed points outside the dependency folder: ' +
                link_target.to_s
      end

      links_found = true
      total_links += 1
      handled.append full
      files.append link_target
    end
  end

  handled = nil

  info "Resolved #{total_links} symbolic links in packaged file list" if total_links > 0

  precompiled_name = instance.getNameForPrecompiled + '_' + CurrentPlatform
  zip_name = precompiled_name + '.tar.xz'
  info_file = precompiled_name + '_info.txt'
  hash_file = precompiled_name + '_hash.txt'

  # Check that all exist
  Dir.chdir(DependencyInstallFolder) do
    files.each do |f|
      unless File.exist? f
        onError "Dependency file that should be packaged doesn't exist: " + f.to_s
      end
    end

    files_to_restore = strip_files_if_needed files

    File.open(info_file, 'w') do |f|
      f.puts "RubySetupSystem precompiled library for #{CurrentPlatform}"
      f.puts instance.Name + ' retrieved from ' + instance.RepoURL
      f.puts instance.Version.to_s + ' Packaged at ' + Time.now.to_s
      f.puts ''
      f.puts "You can probably find license from the repo url if it isn't included here"
      f.puts 'This info file is included in ' + zip_name
    end

    # When bundling everything needs to be made clean
    File.unlink zip_name if File.exist?(zip_name) && $options[:bundle]

    info "Compressing files into #{zip_name}"

    # Write a tar file with lzma compression
    runSystemSafe('tar', '-cJf', zip_name, info_file, *files)

    restore_stripped_files files_to_restore

    onError 'Failed to create zip file' unless File.exist? zip_name

    hash = SHA3::Digest::SHA256.file(zip_name).hexdigest

    # Write hash to file
    File.open(hash_file, 'w') do |f|
      f.puts hash
    end

    success "Done with #{dep}, created: #{zip_name}"
    info "#{zip_name} SHA3: " + hash
    # info "#{zip_name} PLATFORM: " + CurrentPlatform
    bundle_info[:dep_files].append zip_name
    return { name: precompiled_name, hash: hash }
  end
end

# Main handling for dependency list
def package_dependencies(dependencies, bundle_info)
  puts "Starting packaging for #{dependencies.size} dependencies"

  new_database = LocalDatabase.new 'create_precompiled_local_db'

  databases = getDefaultDatabases
  onError 'database loading failed' unless databases

  created = 0

  dependencies.each do |dep|
    info = package_dependency dep, bundle_info

    if info.nil?
      warning "Could not package dependency: #{dep.Name}"
      next
    end

    puts 'Adding to local database instance'
    precompiled = PrecompiledDependency.new info[:name], databases[0].base_url, info[:hash]
    databases[0].add precompiled
    new_database.add precompiled
    created += 1
    puts ''
  end

  puts "Created #{created} new package(s)"

  return if created < 1

  updated_db_file = File.join DependencyInstallFolder, 'database.json'
  puts "Writing updated database file: #{updated_db_file}"
  databases[0].write updated_db_file

  return unless $options[:bundle]

  missing_db_file = File.join DependencyInstallFolder, 'added_entries_to_database.json'
  puts "Writing missing entries database file: #{missing_db_file}"
  new_database.write missing_db_file
  bundle_info[:db_file] = missing_db_file
end

# Main function for missing
def run_package_for_missing(bundle_info)
  puts 'Packaging dependencies missing for current platform'

  $usePrecompiled = true

  puts 'Making sure databases are loaded...'
  databases = getDefaultDatabases

  if databases
    success 'Databases loaded'
  else
    onError 'database loading failed'
  end

  to_package = []

  all_dependencies.each do |dep|
    puts "Checking dependency: #{dep.Name}"

    precompiled = getSupportedPrecompiledPackage dep

    next if precompiled

    puts 'No precompiled available. Creating package'

    to_package.append dep
  end

  if to_package.empty?
    success 'No missing precompiled dependencies found'
    return
  end

  package_dependencies to_package, bundle_info
end

# Main function for all
def run_package_for_specified(bundle_info)
  if $options[:buildAll]
    info 'Packaging all dependencies'

    $toPackageDeps = []

    all_dependencies.each do |dep|
      files = dep.getInstalledFiles

      $toPackageDeps.push dep.Name if files && !files.empty?
    end

    puts $toPackageDeps.to_s
  end

  package_dependencies $toPackageDeps, bundle_info
end

# Main function
def run_packager
  puts ''
  puts "Packaging dependencies: #{$toPackageDeps}"
  puts "Target folder: #{DependencyInstallFolder}"

  bundle_info = {
    zip: File.join(DependencyInstallFolder, "new_precompiled_for_#{describePlatform}.tar.xz"),
    dep_files: []
  }

  # When bundling everything needs to be made clean
  File.unlink bundle_info[:zip] if File.exist?(bundle_info[:zip]) && $options[:bundle]

  if $options[:buildMissing]
    run_package_for_missing bundle_info
  else
    run_package_for_specified bundle_info
  end

  puts ''
  success 'Done creating.'

  if $options[:bundle]
    info 'Beginning bundle operation for the created precompiled packages'

    if bundle_info[:dep_files].empty?
      puts 'No dependencies were created, skipping bundling'
    else
      Dir.chdir(DependencyInstallFolder)  do
        files = bundle_info[:dep_files]

        files.each do |f|
          onError "dependency zip file doesn't exist: #{f}" unless File.exist? f
        end

        info_relative = Pathname.new(bundle_info[:db_file]).relative_path_from(
          DependencyInstallFolder
        ).to_s

        runOpen3Checked('tar', '-cJf', bundle_info[:zip], info_relative, *files)
      end

      raise 'Failed to create bundle' unless File.exist? bundle_info[:zip]

      success "Bundle done: #{bundle_info[:zip]}"
    end
  end

  puts 'Make sure everything was up to date before distributing.'
  true
end
