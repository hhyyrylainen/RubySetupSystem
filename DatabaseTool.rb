#!/usr/bin/env ruby
# Tool for doing things with the RubySetupSystem databases
require_relative 'RubyCommon'
require_relative 'PrecompiledDB'
require_relative 'Database/Database'

require 'tmpdir'
require 'optparse'

EXPECTED_KEY_PATH = File.expand_path '~/.ssl/rubysetupsystem.pem'.freeze

#
# Parse options
#

$options = {}
OptionParser.new do |opts|
  opts.on('-i', '--info', 'Show information about databases') do |_b|
    $options[:info] = true
  end

  opts.on('-f', '--find name', 'Find a precompiled dependency containing name') do |n|
    $options[:find] = n
  end

  opts.on('-l', '--download name', 'Download a precompiled library with name') do |n|
    $options[:dl] = n
  end

  opts.on('-a', '--apply bundle-file,more-bundles', Array,
          'Applies a bundle to the current database and prepares upload files') do |f|
    $options[:apply] = f
  end

  opts.on('--[no-]override',
          'When applying new precompiled deps overwrite unconditionally') do |b|
    $options[:override] = b
  end

  opts.on('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

# Handles applying bundles to the existing db
class BundleApplyHandler
  def initialize(bundles)
    @bundles = if !bundles.is_a? Array
                 [bundles]
               else
                 bundles
               end

    @bundles.each do |bundle|
      onError "non existant file: #{bundle}" unless File.exist? bundle
      onError "provided path is a folder: #{bundle}" if File.directory? bundle
    end

    onError 'no bundles given' if @bundles.empty?

    @upload_base = 'precompiled_upload'
    @upload_info = File.join @upload_base, 'database.json'
    @upload_info_signature = @upload_info + '.sha512'
    @upload_archives = File.join @upload_base, 'precompiled'
    @new_count = 0
  end

  def run
    dbs = getDefaultDatabases

    @db = dbs ? dbs[0] : nil

    onError 'no target database' unless @db

    info 'Target database:'
    @db.info

    FileUtils.mkdir_p @upload_base
    FileUtils.mkdir_p @upload_archives

    # Handle all bundles
    @bundles.each do |bundle|
      handle_bundle bundle
    end

    # Did we do anything?
    if @new_count < 1
      success 'No new precompiled libraries found in bundle.'
      return
    end

    can_sign = File.exist? EXPECTED_KEY_PATH

    @db.write @upload_info

    if can_sign
      info 'Attempting to sign the new database file with rubysetupsystem.pem key...'

      runOpen3Checked('openssl', 'dgst', '-sha512', '-sign', EXPECTED_KEY_PATH, '-out',
                      @upload_info_signature, @upload_info)

      success 'Signing done'
    end

    puts "Added #{@new_count} db entries"

    success "Finished. Upload files from #{@upload_base} to the server"
    unless can_sign
      puts "Note: you must create the signature (#{@upload_info_signature}) before uploading."
    end
  end

  def handle_bundle(bundle)
    info "Adding entries from #{bundle} to db"

    info 'Unzipping the bundle'
    # The created temporary dir here is automatically removed
    Dir.mktmpdir('rubysetupsystem_') do |path|
      puts "Unzip temporary folder is: #{path}"
      unzip_directory = path

      result = runOpen3('tar', '-xf', bundle, '-C', unzip_directory.to_s)

      raise 'unzip command failed to execute' unless result.to_i.zero?

      unzipped_info_file = File.join unzip_directory, 'added_entries_to_database.json'

      raise 'Unzipping failed to create expected entries json file' unless \
        File.exist? unzipped_info_file

      success 'Bundle has been unzipped. Reading info.'

      bundle_info = load_local_database_from_file 'bundle', unzipped_info_file

      puts 'Bundle DB info:'
      bundle_info.info

      bundle_info.each do |key, value|
        next if $options[:override] != true && @db.get_precompiled(key)

        to_move_zip = File.join unzip_directory, value.ZipName
        puts "#{key} is a new precompiled dependency. At path: #{to_move_zip}"

        # Move to upload folder
        FileUtils.mv to_move_zip, @upload_archives

        # Add to db
        @db.add value
        @new_count += 1
      end
    end
  end
end

unless ARGV.empty?
  # Handle extra args

  unless ARGV.empty?

    onError('Unkown arguments. See --help. This was left unparsed: ' + ARGV.join(' '))
  end
end

if $options[:info]
  getDefaultDatabases.each do |db|
    db.info
    puts ''
  end
elsif $options[:find]
  getDefaultDatabases.each do |db|
    db.search($options[:find]).each do |dep|
      puts dep
    end
  end
elsif $options[:dl]

  precompiled = getPrecompiledByName $options[:dl]

  onError 'no library with specified name found' unless precompiled

  precompiled.download precompiled.ZipName

elsif $options[:apply]

  BundleApplyHandler.new($options[:apply]).run

else
  error 'No operation specified. Use -h to see help'
end
