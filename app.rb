require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'slim'
require 'sass'
require 'coffee_script'
require 'force'
require 'securerandom'
require 'sinatra/base'
require 'hashie'

module Sinatra
  module SOQLHelper
    module Methods
      def quote(text, like: false)
        if like then
          text.to_s.gsub settings.quote_like_regex, settings.quote_replacement
        else
          text.to_s.gsub settings.quote_regex, settings.quote_replacement
        end
      end
    end

    def self.registered(app)
      app.helpers SOQLHelper::Methods
      app.set :quote_regex, /[\n\r\t\b\f"'\\]/
      app.set :quote_like_regex, /[\n\r\t\b\f"'\\%_]/
      app.set :quote_replacement, {"\n" => '\n', "\r" => '\r', "\t" => '\t', "\b" => '\b', "\f" => '\f',
                                   '"' => '\"', '\'' => '\\\'', '\\' => '\\\\'}
    end
  end
  register SOQLHelper
end

configure do
  use Rack::Session::Cookie, secret: SecureRandom.random_bytes(100)
end

configure :development do
  require 'dotenv'
  Dotenv.load
  set :bind, '0.0.0.0'
end

get '/' do
  slim :index
end

post '/login' do
  params = JSON.parse request.body.read, symbolize_names: true
  mail = params[:mail].to_s
  return 403 if mail.empty?

  client = Force.new
  contact = client.query("select Id from Contact where Email = '#{quote mail}' limit 1").first
  id = if contact.nil? then
         client.create! 'Contact', Email: mail, LastName: 'Newbie'
       else
         contact.Id
       end

  uuid = SecureRandom.uuid
  client.create! 'ContactLogin__c', Name: uuid, Contact__c: id

  'ok'
end

get '/login/:token' do |token|
  client = Force.new
  contact_token = client.query("select Id, UsedAt__c, CreatedDate, Contact__r.Id from ContactLogin__c where Name = '#{quote token}' limit 1").first
  return 403 if contact_token.nil?
  return 403 unless contact_token.UsedAt__c.nil?
  return 403 if Time.parse(contact_token.CreatedDate) < Time.now - 24 * 60

  client.update 'ContactLogin__c', Id: contact_token.Id, UsedAt__c: Time.now.utc.iso8601
  session.destroy
  session[:id] = contact_token.Contact__r.Id

  redirect to '/app'
end

get '/app' do
  @picklist_values = Force.new.picklist_values 'Contact', 'Picklist__c'
  slim :app
end

get '/app.css' do
  sass :app
end

get '/app.js' do
  coffee :app
end

get '/contact' do
  return 403 if session[:id].nil?
  client = Force.new
  contact = client.find 'Contact', session[:id]
  json contact
end

post '/contact' do
  return 403 if session[:id].nil?
  client = Force.new
  e = Hashie::Mash.new JSON.parse request.body.read
  client.update! 'Contact',
                 Id: session[:id], FirstName: e.FirstName, LastName: e.LastName,
                 Number__c: e.Number__c, Text__c: e.Text__c,
                 Picklist__c: e.Picklist__c, Bool__c: e.Bool__c
  e = client.find 'Contact', e.Id
  json e
end

get '/contact_item' do
  return 403 if session[:id].nil?
  contact_id = session[:id]
  client = Force.new
  contact_items = client.query "select Id, Name, Text__c, Number__c, LastModifiedDate from ContactItem__c where Contact__c = '#{quote contact_id}'"
  json contact_items.to_a
end

post '/contact_item/:id' do |id|
  return 403 if session[:id].nil?
  client = Force.new
  e = Hashie::Mash.new JSON.parse request.body.read
  client.update! 'ContactItem__c',
                 Id: e.Id, Name: e.Name, Number__c: e.Number__c, Text__c: e.Text__c
  e = client.find 'ContactItem__c', e.Id
  json e
end

post '/contact_item' do
  return 403 if session[:id].nil?
  client = Force.new
  e = Hashie::Mash.new JSON.parse request.body.read
  id = client.create! 'ContactItem__c',
                      Name: e.Name, Number__c: e.Number__c, Text__c: e.Text__c, Contact__c: session[:id]
  e = client.find 'ContactItem__c', id
  json e
end

delete '/contact_item/:id' do |id|
  return 403 if session[:id].nil?
  client = Force.new
  client.destroy! 'ContactItem__c', id
  'ok'
end
