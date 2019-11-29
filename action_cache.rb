require 'json'

ACTION_CACHE_FILENAME = 'RubySetupSystemCache.json'.freeze

# Helper for skipping some actions that don't need to rerun or
# checking if something needs to rerun
class ActionCache
  attr_reader :cache_file

  def initialize(cache_location, action_key)
    @cache_file = File.join cache_location, ACTION_CACHE_FILENAME
    @key = action_key.to_s
    @cache = {}

    load_cache
  end

  def load_cache
    if File.exist? @cache_file
      begin
        @cache = JSON.parse(File.read(@cache_file))
      rescue StandardError => e
        error "Cannot read cache file: #{@cache_file}, due to error: #{e}, deleting it"
        @cache = {}
        File.unlink @cache_file
      end
    end

    @cache[@key] = {} unless @cache.include? @key
  end

  def save_cache
    File.write @cache_file, JSON.dump(@cache)
  end

  def performed?(**action_parameters)
    action_parameters.each  do |k, v|
      return false if @cache[@key][k.to_s] != v
    end

    true
  end

  def mark_performed(**action_parameters)
    action_parameters.each do |k, v|
      @cache[@key][k.to_s] = v
    end
  end

  # Pass a block to be executed if the action is not ran with the action parameters
  def perform_if_needed(**action_parameters)
    return if performed?(**action_parameters)

    yield

    mark_performed(**action_parameters)
  end
end
