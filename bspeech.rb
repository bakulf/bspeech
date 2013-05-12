#!/usr/bin/env ruby

@@withUI = false
begin
  require "gtk2"
  @@withUI = true
rescue LoadError => e
  puts "No UI will be used"
end

require 'tempfile'
require 'rubygems'
require 'json/pure'
require "yaml"

class BSpeech
  RATE = 16000
  TIMEOUT = 10

  # states
  Sleeping   = 0
  Recording  = 1
  Processing = 2
  Ready      = 3
  Ending     = 4

  ErrorJSON  = -1
  ErrorData  = -2

  def initialize
    readConfig
    loadModules

    @filename = Tempfile.new('foo').path + ".flac"
    puts "Filename: #{@filename}"
  end

  def run
    @state = Sleeping

    if @@withUI
      @thr = Thread.new do
        runInternal
      end

      @n = Notification.new(@settings['markup'])
      prevState = nil
      startTime = Time.now

      GLib::Timeout.add 200 do
        if @state == Recording && Time.now - startTime > TIMEOUT
          quit "Something wrong is happening. Sorry!"
        end

        if prevState != @state
          if @state == Sleeping
            @n.show "Wait..."
          elsif @state == Recording
            @n.show "Recording"
          elsif @state == Processing
            @n.show "Processing"
          elsif @state == ErrorJSON
            quit  "JSON error"
          elsif @state == ErrorData
            quit  "Sorry... can you repeat?"
          elsif @state == Ready
            @n.show @text
          elsif @state == Ending
            @n.quit @text
          end

          prevState = @state
        end
        true
      end

      Gtk.main
    else
      runInternal
    end
  end

  def runInternal
    cmd = "rec -r #{RATE} -q -b 16 #{@filename} silence 1 0.1 5% 1 1.0 5% channels 1"
    puts "Executing '#{cmd}`"

    @state = Recording
    IO.popen cmd do |data|
      @pid = data.pid
    end

    return if @pid == 0

    puts "Processing..."
    @state = Processing
    cmd = "curl -s -X POST -H \"Content-Type:audio/x-flac; rate=#{RATE}\" -T #{@filename} " +
          "\"https://www.google.com/speech-api/v1/recognize?xjerr=1&client=chromium&lang=#{@settings['language']}&maxresults=10&pfilter=0\""

    json = ''
    IO.popen cmd do |data|
      @pid = data.pid
      json += data.read
    end
    @pid = 0

    File.unlink @filename

    data = JSON.parse json
    if not data.include? 'hypotheses'
      puts "Error in the JSON doc"
      @state = ErrorJSON
      return
    end

    @text = nil
    if not data['hypotheses'].empty?
      @text = data['hypotheses'][0]['utterance']
    end

    if @text.nil?
      puts "What?"
      @state = ErrorData
      return
    end

    @state = Ready
    puts "Text: #{@text}"

    processingText
  end

private
  def processingText
    texts = @text.split

    msg = ''
    @modules.each do |m|
      name = m.name

      config = nil
      if @settings.include? 'modules' and
         @settings['modules'].include? name
        config = @settings['modules'][name]
      end

      if m.yours? config, texts
        msg += m.run config, texts
        break
      end
    end

    if msg.empty?
      @text += "\ndoesn't match any module."
    else
      @text = msg
    end

    @state = Ending
  end

  def quit(msg)
    if @pid > 0
      Process.kill "TERM", @pid
      @pid = 0
    end

    @n.quit msg
  end

  def readConfig
    filename = ENV['HOME'] + '/.bspeech.yml'

    # No config? Let's create it:
    if not File.exist? filename
      file = File.open filename, 'w'

      file.write "bspeech:\n"
      file.write "  markup: <span font_desc=\"Purisa 30\" foreground=\"red\">%s</span>\n"
      file.close
    end

    # Loading the config:
    config = YAML.load_file(ENV['HOME'] + '/.bspeech.yml')
    if config == false or config.nil? or config['bspeech'].nil?
      puts "No configuration! Remove ~/.bspeech.yml or fix it!"
      exit
    end

    @settings = config['bspeech']
  end

  def loadModules
    @modules = []

    dirname = ENV['HOME'] + '/.bspeech'

    # Directory + example
    if not File.exist? dirname
      Dir.mkdir dirname
      f =File.open dirname + '/example.rb', 'w'
      f.write "class Example\n  def name\n    \"Example\"\n  end\n" +
              "  def yours?(config, something)\n    true" +
              "\n  end\n\n  def run(config, something)\n    # ...\n    \"Hello world!\"" +
              "\n  end\nend\n\n" +
              "# Here, create our object and leave it as return value:\n" +
              "Example.new\n"
      f.close
    end

    # Let's load the modules
    d = Dir.open dirname
    modules = []
    while file = d.read do
      next if file.start_with? '.'
      modules.push dirname + '/' + file
    end

    modules.sort.each do |m|
      loadModule m
    end
  end

  def loadModule(file)
    puts "Loading #{file}..."

    data = ''
    File.open(file, "r").each_line do |line|
      data += line
    end

    obj = eval data
    @modules.push obj
  end
end

# Notification class
class Notification
  TIMEOUT = 100

  def initialize(markup)
    @markup = markup

    @window = Gtk::Window.new Gtk::Window::POPUP
    @window.decorated = false
    @window.set_keep_above true
    @window.set_app_paintable true
    @window.window_position = Gtk::Window::POS_CENTER_ALWAYS

    @label = Gtk::Label.new
    @label.justify = Gtk::Justification::CENTER
    @window.add @label

    @window.signal_connect('expose-event') do expose end

    colormap = @window.screen.rgba_colormap
    @window.set_colormap @window.screen.rgba_colormap if not colormap.nil?

    @window.set_can_focus false
    @label.set_can_focus false
  end

  def destroy
    @window.destroy
  end

  def show(text)
    @label.set_markup @markup.sub("%s", text)
    @window.resize 1, 1
    @window.show_all

    @window.set_opacity 1
  end

  def quit(text)
    show text
    GLib::Timeout.add 1000 do
      Gtk.main_quit
    end
  end

  private
  def expose
    c = @window.window.create_cairo_context

    c.set_source_rgba(1.0, 1.0, 1.0, 0.0)
    c.set_operator Cairo::OPERATOR_SOURCE
    c.paint
    c.destroy

    false
  end
end

a = BSpeech.new
a.run
