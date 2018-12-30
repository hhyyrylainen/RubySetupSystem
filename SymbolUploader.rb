# Helpers for creating symbol upload scripts. This is meant to be ran after
# a packaging script
require "fileutils"
require 'uri'

# An extra dependency just for this script
require 'httparty'

require_relative 'RubyCommon.rb'

def checkRunFolder(suggested)

  buildFolder = File.join(suggested, "build", "Symbols")

  onError("Not ran from base folder (no build/Symbols directory exists)") if
    not File.exist?(buildFolder)

  buildFolder
end

def projectFolder(baseDir)

  File.expand_path File.join(baseDir, "../../")

end

def getExtraOptions(opts)

  opts.on("--token token", "Set to your API token") do |t|
    $options[:apiToken] = t
  end

  opts.on("--url url", "Override the default symbol destination") do |u|
    $options[:overrideURL] = u
  end

end

def extraHelp
  puts $extraParser
end

require_relative 'RubySetupSystem.rb'

if !$options[:apiToken]
  error "You must provide an API token (--token)"
  exit 2
end

# This object holds the configuration needed for making a release
class SymbolDestinationProperties

  attr_accessor :url

  def initialize(url)
    @url = url
  end
end


def findSymbolFiles(folder)

  symbols = []

  Dir.glob(File.join folder, "**/*"){|i|

    if !File.file? i
      next
    end

    begin

      platform, arch, hash, name = getBreakpadSymbolInfo File.read i

      if !platform || !arch || !hash || !name
        raise "not a breakpad file"
      end

      # Some extra sanity checks
      if name.count(' ') > 0 || (arch != "x86_64" && arch != "x86") ||
         (platform != "Linux" && platform != "Windows")
        puts "File properties: ", platform, arch, hash, name
        raise "file has invalid looking data"
      end      
      

    rescue
      warning "Invalid file: #{i}"
      next
    end

    symbols.push({
                   file: i,
                   platform: platform,
                   arch: arch,
                   hash: hash,
                   name: name,
                   size: File.size(i).to_f / 2**20
                 })
  }

  symbols
end

def queryExistingSymbols(symbols, url)

  query = []

  symbols.each{|s|

    query.push(
      {
        hash: s[:hash],
        name: s[:name]
      }
    )
  }

  response = HTTParty.post(URI.join(url, "api/v1/symbols/all?token=#{$options[:apiToken]}"),
                           body: {to_check: query})

  if !response.include?("existing") || response["errors"].length > 0
    puts response
    onError "Invalid http response"
  end

  response["existing"]
end

def uploadSymbol(symbol, url)

  response = HTTParty.post(URI.join(url, "api/v1/symbols?token=#{$options[:apiToken]}"),
                           body: {
                             data: File.open(symbol[:file], 'rb')
                           })

  if !response
    puts response
    onError "invalid response (null)"
  end
  
  if !response.include?("name") || response["name"] != symbol[:name]
    puts response
    onError "Invalid response for upload"
  end

  success "Uploaded: #{symbol[:name]}"
end


# Main run method
def runUploadSymbols(props)

  url = props.url

  if $options[:overrideURL]
    url = $options[:overrideURL]
  end
  
  info "Starting symbol upload to: #{url}"

  symbols = findSymbolFiles(CurrentDir)

  info "Found #{symbols.length} symbol files"

  # Determine which symbols aren't on the server
  existing = queryExistingSymbols symbols, url
  
  symbols.reject! {|item| existing.any?{|exist|
                     exist["name"] == item[:name] && exist["hash"] == item[:hash]}
  }

  info "Symbol count that server doesn't have: #{symbols.length}"

  if symbols.length < 1

    success "Nothing to do"
    exit 0
  end

  puts "New symbol names:"
  symbols.each{|i|
    puts "#{i[:name]}: #{i[:hash]}"
  }

  # Ask
  totalSize = symbols.reduce(0) {|sum, item| sum + item[:size]}
  info "You are about to upload #{symbols.length} symbols " +
       "with size of #{totalSize.round 2} MiB"
  moveForward = false
  while !moveForward
    puts "Is this OK? [Y/n]"
    print "> "
    choice = STDIN.gets.chomp.upcase

    puts "Selection: #{choice}"

    case choice
    when "Y", "y"
      puts "Continuing to upload"
      moveForward = true
    when "N", "n"
      puts "Canceling"
      exit 0
    else
      puts "Invalid. Please answer Y/N"
    end
  end

  info "Beginning upload"

  symbols.each{|i|
    uploadSymbol i, url
  }

  success "Done sending symbols."
end
