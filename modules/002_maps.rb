require 'cgi'

class Maps
  def name
    "Maps"
  end

  def yours?(config, something)
    if config.nil? or
       not config.include? 'words' or
       not config.include? 'app' or
       not config.include? 'url' then
      puts " * Add modules/Maps/words, modules/Maps/url, modules/Maps/app keywords in the config file."
      return false
    end

    return config['words'].include? something[0]
  end

  def run(config, something)
    url = nil
    if config['words'].include? something[0]
      url = config['url']
      something.shift

      what = something.join ' '
      url += CGI.escape(what)
    end

    system "#{config['app']} #{url} &"
    return "Open maps: '#{what}'"
  end
end

Maps.new
