# encoding: utf-8
require 'mechanize'
require 'loofah'
require 'byebug'

class Crawler
  def initialize(params)
    agent = Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
    end

    @page = agent.get(params[:url])
  end

  def download
    body_html = @page.body

    content = Loofah.fragment(body_html).scrub!(:whitewash).text

    hash(body_html, squish(content))
  end

  private

  def hash(body_html, content_text)
    {
      body_text: convert(content_text),
      content_html: convert(body_html)
    }
  end

  def squish(content)
    content
      .gsub(/\A[[:space:]]+/, '')
      .gsub!(/[[:space:]]+\z/, '')
      .gsub!(/[[:space:]]+/, ' ')
  end

  def convert(text)
    begin
      cleaned = text.force_encoding('UTF-8')

      unless cleaned.valid_encoding?
        cleaned = text.encode( 'UTF-8', 'Windows-1251')
      end

      cleaned
    rescue
      text.encode!( 'UTF-8', invalid: :replace, undef: :replace )
    end
  end

end
