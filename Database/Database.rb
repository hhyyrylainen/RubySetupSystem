# Implements downloadable database that is signed with a SSL certificate
require 'open-uri'
require 'json'
require 'openssl'

require_relative 'PrecompiledDependency'
require_relative '../RubyCommon'

class Database
  attr_reader :Name, :URL
  
  def initialize(name, url, keyFile)
    @Name = name
    @URL = url
    @Key = loadKeyFromFile keyFile
    @KeyFile = keyFile

    puts "Downloading signature of #{@Name}"
    open(url + ".sha512", "rb", read_timeout: 10) do |req|
      @Signature = req.read
    end
    
    puts "Downloading: #{@URL}"
    open(url, "rb", read_timeout: 20) do |req|
      text = req.read

      # Verify signature
      puts "Verifying download signature"

      if !@Key.verify OpenSSL::Digest::SHA512.new, @Signature, text
        raise "Downloaded file/signature is not signed with the required key"
      end

      success "Signature is good"
      
      @Data = JSON.parse(text)
    end

    @Precompiled = {}

    @Data["precompiled"].each{|key, value|
      @Precompiled[key] = PrecompiledDependency.new key, baseURL, value["hash"]
    }
  end

  def baseURL
    @Data["baseurl"]
  end

  def info
    puts %{Database "#{@Name}" from #{@URL}}
    puts %{verified by key "#{@KeyFile}"}
    puts %{has base url of "#{baseURL}"}
    puts %{contains #{@Precompiled.length} precompiled dependencies"}
  end

  def getPrecompiled(name)
    @Precompiled[name]
  end

  def search(name)
    @Precompiled.select{|key, value|
      key.include? name
    }.map{|key, value| value}
  end
  
end

def loadDatabase(name, url, key)
  begin
    $remoteDatabases.push(Database.new name, url, key)
    return true
  rescue Exception => e
    warning "Failed to download database #{name}, error: #{e}"
    return false
  end
end

def loadKeyFromFile(file)
  OpenSSL::X509::Certificate.new(File.read file).public_key
end
     

# Loads and returns all the default databases
def getDefaultDatabases
  if !$remoteDatabasesLoaded
    info "Loading remote databases..."

    $remoteDatabases = []

    failures = false

    if !loadDatabase "boostslair",
                     "https://boostslair.com/rubysetupsystem/database.json",
                     File.expand_path('rubysetupsystem.cert', __dir__)
      failures = true
    end

    if failures
      warning "One or more databases failed to download."
      warning "Precompiled and other features may be unavailable."
    end
    
    $remoteDatabasesLoaded = true
    info "#{$remoteDatabases.length} remote databases loaded"
  end

  $remoteDatabases
end
