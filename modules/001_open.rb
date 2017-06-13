class OpenApp
  def name
    "OpenApp"
  end

  def yours?(config, something)
    if config.nil? or
       not config.include? 'words' or
       not config.include? 'apps' then
      puts " * Add a modules/OpenApp/words and modules/OpenApp/apps keywords in the config file for this module."
      return false
    end

    return config['words'].include? something[0]
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
