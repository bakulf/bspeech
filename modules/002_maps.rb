require 'cgi'

class Maps
  def name
    "Maps"
  end

  def yours?(config, something)
    # yeah... this is the last one.
    if config['mapWords'].include? something[0]
      return true
    end

    false
  end

  def run(config, something)
    url = nil
    if config['mapWords'].include? something[0]
      url = config['mapUrl']
      something.shift

      what = something.join ' '
      url += CGI.escape(what)
    end

    system "#{config['app']} #{url} &"
    return "Open maps: '#{what}'"
  end
end

Maps.new
