# This file contains general things for supporting precompiled dependencies
require 'fileutils'

# Generates a string that describes the current platform and compiler
# TODO: move this somewhere more sensible
def describePlatform
  TC.name.tr(' ', '_')
end

# Class that handles the definition of a precompiled dependency and applying it if wanted
# It is required that THIRD_PARTY_INSTALL points to the folder where precompiled files
# should be unzipped to
class PrecompiledDependency
  attr_reader :FullName, :URL, :RelativeUnPack, :Hash, :ZipName

  def initialize(name, url, hash, relativeunpack = '')
    @zip_type = :tar_xz
    @FullName = name
    @ZipName = if @zip_type == :p7zip
                 name + '.7z'
               elsif @zip_type == :tar_xz
                 name + '.tar.xz'
               else
                 onError 'unknown zip type in precompiled'
               end
    @URL = url + @ZipName
    @Hash = hash
    @RelativeUnPack = relativeunpack
    @for_dependency = nil

    onError 'PrecompiledDependency has no valid hash: ' + @Hash if !@Hash || @Hash.length <= 10
  end

  # The precompiled db doesn't know for which dependency this
  # precompiled is for, so the dependency need to be provided through
  # this method (this is done by retrieve precompiled before returning
  # a result.
  def precompiled_this_is_for(dep)
    @for_dependency = dep
  end

  # Retrieves this dependency
  def retrieve
    info 'Retrieving precompiled dependency ' + @FullName

    FileUtils.mkdir_p dl_folder

    download target_file
    success 'Done'
  end

  def download(target)
    downloadURLIfTargetIsMissing @URL, target, @Hash, 2
  end

  def to_s
    %(dependency "#{@FullName}" from #{@URL} with hash #{@Hash})
  end

  def dl_folder
    File.join CurrentDir, 'PrecompiledCache'
  end

  def target_file
    File.join dl_folder, @ZipName
  end

  def target_files_exist
    return false unless @for_dependency

    @for_dependency.getInstalledFiles.each do |f|
      return false unless File.exist? f
    end

    true
  end

  # Unzips this to where it should go
  def install
    unless @for_dependency
      onError "The dependency this precompiled object is for is unset, can't install"
    end

    FileUtils.mkdir_p THIRD_PARTY_INSTALL

    # Only unzip if needed
    # This cache is shared with all precompiled dependencies
    cache = ActionCache.new THIRD_PARTY_INSTALL, @for_dependency.Name + '_unzipped'

    params = { archive_name: @ZipName, hash: @Hash }

    if cache.performed?(**params) && target_files_exist
      info "Skipping unzipping precompiled (#{@ZipName}) as cache says it was already " \
           'unzipped and all target files exist'
      return
    end

    cache.mark_performed(**params)
    cache.save_cache

    Dir.chdir(THIRD_PARTY_INSTALL) do
      info "Unzipping precompiled '#{@FullName}' to #{THIRD_PARTY_INSTALL}"

      # Overwrite everything on unzip

      if @zip_type == :p7zip
        runOpen3Checked(p7zip, 'x', target_file, '-aoa')
      elsif @zip_type == :tar_xz
        runOpen3Checked('tar', '-xf', target_file, '--overwrite')
      else
        onError 'unknown zip type'
      end

      puts 'Verifying that unzipping created wanted files'

      @for_dependency.getInstalledFiles.each do |f|
        onError "Unzipping precompiled did not create needed file: #{f}" unless File.exist? f
      end

      info 'All specified files exist'

      success 'Done unzipping'
    end
  end
end
