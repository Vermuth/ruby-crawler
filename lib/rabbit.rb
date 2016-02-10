# encoding: utf-8
require 'bunny'
require 'byebug'
require_relative 'crawler'
require_relative 'db_connect'

class Receiver

  def initialize
    @conn = Bunny.new
    @conn.start
  end

  def receive_message
    ch = @conn.create_channel
    queue  = ch.queue('downloads')

    queue.subscribe(block: true) do |_, _, body|
      # url, source, query_id
      hash_results = hash(skip_empty body)

      #body, content
      parse_data = Crawler.new(hash_results).download

      combined_data = hash_results.merge(parse_data)

      DbConnect.new(combined_data).push_data
    end

    @conn.close
  end

  private

  def skip_empty(body)
    body.split('::').select{ |x| !x.empty? }
  end

  def hash(results)
    {
      url: encode(results[0]),
      source: results[2],
      query_id: results[3]
    }
  end

  def encode(url)
    url.encode('utf-8', invalid: :replace)
  end

end

conntection = Receiver.new
conntection.receive_message