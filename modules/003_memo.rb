require 'cgi'

class Memo
  def name
    "Memo"
  end

  def yours?(config, something)
    if config['memoAdd'].include? something[0] or
       config['memoPlay'].include? something[0]
      return true
    end
  end

  def run(config, something)
    cmd = something.shift
    msg = something.join ' '

    if config['memoAdd'].include? cmd
      File.open(config['memoFile'], 'a') do |f|
        f.puts msg
      end

      system "echo #{msg} | text2wave  | aplay"

    elsif config['memoPlay'].include? cmd
      File.open(config['memoFile'], 'r').each_line do |f|
        system "echo \"#{f}\" | text2wave  | aplay"
        sleep 0.5
      end
    end

    return "Fatto"
  end
end

Memo.new
