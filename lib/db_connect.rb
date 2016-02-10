# encoding: utf-8
require 'pg'
require 'byebug'
require 'uri/http'
require 'public_suffix'

class DbConnect
  attr_reader :params

  def initialize(params)
    @params = params
    @connect = PG.connect(dbname: 'illegal_content_manager_development', user: 'dev', password: 'dev')
  end

  def push_data
    begin
      create_page
      create_content
    ensure
      @connect.close if @connect
    end
  end

  def domain_id
    conn = @connect.exec("SELECT id FROM domains WHERE domain = '#{domain.reverse}'")

    id = conn.first['id'].to_i if conn.first

    create_domain unless id

    id || domain_id
  end

  def create_page
    @connect.prepare(
      'statement1',
      'INSERT INTO pages
      (query_id, url, content, body, source, created_at,
        updated_at, content_type, domain_id) values ($1, $2, $3, $4, $5, $6, $7, $8, $9)'
    )

    @connect.exec_prepared('statement1', page_data_arr)
  end

  def page_id
    conn = @connect.exec("SELECT id FROM pages WHERE url = '#{params[:url]}'")

    conn.first['id'].to_i
  end

  def create_content
    @connect.prepare(
      'statement2',
      'INSERT INTO contents (page_id, created_at, updated_at, suspicious_level, remains_votes, state) VALUES ($1, $2, $3, $4, $5, $6)'
    )

    @connect.exec_prepared('statement2', content_data_arr)
  end

  def create_domain
    @connect.prepare(
      'statement3',
      'INSERT INTO domains (domain, created_at, updated_at) VALUES ($1, $2, $3)'
    )

    @connect.exec_prepared('statement3', [domain.reverse, Time.now, Time.now])
  end

  def page_data_arr
    [
      params[:query_id],
      params[:url],
      params[:content_html],
      params[:body_text],
      params[:source],
      Time.now,
      Time.now,
      "text/html; charset=utf-8",
      domain_id
    ]
  end

  def content_data_arr
    [
      page_id,
      Time.now, #created_at
      Time.now, #updated_at
      1,        #suspicious_level
      1,        #remains_votes
      'created' #state
    ]
  end

  def domain
    uri = URI.parse(params[:url])
    domain = PublicSuffix.parse(uri.host)
    domain.domain
  end
end
