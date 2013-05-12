class OpenApp
  def name
    "OpenApp"
  end

  def yours?(config, something)
    matchs = [ "open", "apri", "esegui", "run" ]
    return config['magicWords'].include? something[0]
  end

  def run(config, something)
    config['apps'].each do |k,v|
      if something[1] == k
        system "#{v} &"
        return v
      end
    end

    return "What?"
  end
end

OpenApp.new
