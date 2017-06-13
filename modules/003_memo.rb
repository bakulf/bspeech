require 'cgi'

class Memo
  def name
    "Memo"
  end

  def yours?(config, something)
    if config.nil? or
       not config.include? 'file' or
       not config.include? 'add' or
       not config.include? 'play' then
      puts " * Add modules/Memo/file modules/Memo/add and a module/Memo/play keywords in the config file."
      return false
    end

    return (config['add'].include? something[0] or
            config['play'].include? something[0])
  end

  def run(config, something)
    cmd = something.shift
    msg = something.join ' '

    if config['add'].include? cmd
      File.open(config['file'], 'a') do |f|
        f.puts msg
      end

      system "echo #{msg} | text2wave | aplay"

    elsif config['play'].include? cmd
      File.open(config['file'], 'r').each_line do |f|
        system "echo \"#{f}\" | text2wave  | aplay"
        sleep 0.5
      end
    end

    return "Fatto"
  end
end

Memo.new
