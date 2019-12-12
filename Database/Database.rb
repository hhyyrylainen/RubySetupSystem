# Implements downloadable database that is signed with a SSL certificate
require 'open-uri'
require 'json'
require 'openssl'

require_relative 'PrecompiledDependency'
require_relative '../RubyCommon'

# Base database class
class BaseDatabase
  attr_reader :Name

  def initialize(name)
    @Name = name

    @Precompiled = {}
    @Data = nil
  end

  def base_url
    @Data['baseurl']
  end

  def handle_loaded_data
    @Data['precompiled'].each do |key, value|
      @Precompiled[key] = PrecompiledDependency.new key, base_url, value['hash']
    end
  end

  def info
    puts %(Base database "#{@Name}")
    common_info
  end

  def common_info
    puts %(has base url of "#{base_url}")
    puts %(contains #{@Precompiled.length} precompiled dependencies")
  end

  def getPrecompiled(name)
    get_precompiled name
  end

  def get_precompiled(name)
    @Precompiled[name]
  end

  def search(name)
    @Precompiled.select do |key, _value|
      key.include? name
    end.map { |_key, value| value }
  end

  def each
    @Precompiled.each do |key, value|
      yield key, value
    end
  end

  def add(dep)
    @Precompiled[dep.FullName] = dep
  end

  def write(file)
    File.open(file, 'wb') do |f|
      f.puts JSON.pretty_generate serialize
    end
  end

  def serialize
    precompiled = {}

    @Precompiled.each do |key, value|
      if key != value.FullName
        warning "Precompiled key doesn't match its name: #{key} != #{value.Fullname}"
      end

      precompiled[key] = { hash: value.Hash }
    end

    precompiled = precompiled.sort.to_h

    {
      baseurl: base_url,
      precompiled: precompiled
    }
  end
end

# Online database
class Database < BaseDatabase
  attr_reader :URL

  def initialize(name, url, keyFile)
    super name

    @URL = url
    @Key = loadKeyFromFile keyFile
    @KeyFile = keyFile

    puts "Downloading signature of #{@Name}"
    open(url + '.sha512', 'rb', read_timeout: 10) do |req|
      @Signature = req.read
    end

    puts "Downloading: #{@URL}"
    open(url, 'rb', read_timeout: 20) do |req|
      text = req.read

      # Verify signature
      puts 'Verifying download signature'

      unless @Key.verify OpenSSL::Digest::SHA512.new, @Signature, text
        raise 'Downloaded file/signature is not signed with the required key'
      end

      success 'Signature is good'

      @Data = JSON.parse(text)
    end

    handle_loaded_data
  end

  def info
    puts %(Database "#{@Name}" from #{@URL})
    puts %(verified by key "#{@KeyFile}")
    common_info
  end
end

# Local database
class LocalDatabase < BaseDatabase
  attr_reader :base_url

  def initialize(name, base_url: 'unset')
    super name

    @base_url = base_url

    @Data = {
      'baseurl' => base_url,
      'precompiled' => []
    }

    handle_loaded_data
  end

  def read_from_file(file)
    @Data = JSON.parse File.read(file)
    handle_loaded_data
    @base_url = @Data['baseurl']
  end

  def info
    puts %(Local database "#{@Name}")
    common_info
  end
end

def load_database(name, url, key)
  $remoteDatabases.push(Database.new(name, url, key))
  true
rescue StandardError => e
  warning "Failed to download database #{name}, error: #{e}"
  false
end

def load_local_database_from_file(name, file)
  db = LocalDatabase.new name
  db.read_from_file file
  db
end

def loadKeyFromFile(file)
  OpenSSL::X509::Certificate.new(File.read(file)).public_key
end

# Loads and returns all the default databases
def getDefaultDatabases
  unless $remoteDatabasesLoaded
    info 'Loading remote databases...'

    $remoteDatabases = []

    failures = false

    unless load_database 'boostslair',
                         'https://boostslair.com/rubysetupsystem/database.json',
                         File.expand_path('rubysetupsystem.cert', __dir__)
      failures = true
    end

    if failures
      warning 'One or more databases failed to download.'
      warning 'Precompiled and other features may be unavailable.'
    end

    $remoteDatabasesLoaded = true
    info "#{$remoteDatabases.length} remote databases loaded"
  end

  $remoteDatabases
end
