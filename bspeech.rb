#!/usr/bin/env ruby

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

  def initialize(config)
    readConfig config

    @filename = Tempfile.new('foo').path + ".flac"
    puts "Filename: #{@filename}"

    @@value = 0
    @post = '__VALUE__'
  end

  def run
    @state = Sleeping
    loop do
      runInternal
    end
  end

private
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

  def processingText
    @settings['modules'].each do |m, k|
      k['words'].each do |word|
        if @text.start_with? word
          puts "Execution method #{m}..."

          if k.include? 'cmd'
            eval k['cmd']
          end

          @@value = k['value'] if k.include? 'value'
          @post = k['post'] if k.include? 'post'

          post = @post.gsub('__VALUE__', "#{@@value}")

          cmd = "curl -s -X POST -H 'Content-Type: application/json' -d '#{post}' '#{@settings['url']}'"
          puts cmd
          system cmd

          return
        end
      end
    end
  end

  def readConfig(filename)

    # No config? Let's create it:
    if not File.exist? filename
      puts "Config file `#{filename}' doesn't exist."
      exit
    end

    # Loading the config:
    config = YAML.load_file filename
    if config == false or config.nil? or config['bspeech'].nil?
      puts "No configuration!!"
      exit
    end

    @settings = config['bspeech']
  end
end

a = BSpeech.new(ARGV[0])
a.run
