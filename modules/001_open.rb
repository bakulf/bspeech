class OpenApp
  def name
    "OpenApp"
  end

  def yours?(something)
    matchs = [ "open", "apri", "esegui", "run" ]
    return matchs.include? something[0]
  end

  def run(config, something)
    config.each do |k,v|
      if something[1] == k
        system "#{v} &"
        return v
      end
    end

    return "What?"
  end
end

OpenApp.new
