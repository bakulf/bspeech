require 'cgi'

class Search
  def name
    "Search"
  end

  def yours?(config, something)
    if config.nil? or not config.include? 'fallbackUrl' or not config.include? 'words' then
      puts " * Add a modules/fallbackUrl and modules/words keywords in the config file for the 999_search module"
      return false
    end

    true
  end

  def run(config, something)
    url = config['fallbackUrl']
    if config['words'].include? something[0]
      url = config['words'][something[0]];
      something.shift
    end

    what = something.join ' '
    url += CGI.escape(what)

    system "#{config['app']} #{url} &"
    return "Searching '#{what}'"
  end
end

Search.new
