require 'cgi'

class Search
  def name
    "Search"
  end

  def yours?(config, something)
    # yeah... this is the last one.
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
