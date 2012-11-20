#require 'base64'
require 'dragonfly'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'multi_json'

helpers do
  def dragonfly
    Dragonfly[:images]
  end

  def image_sha(payload)
    Digest::SHA1.hexdigest("#{payload}#{dragonfly.secret}")[0...8]
  end

  def validate_sha(data)
    sha = image_sha(data)

    halt 400, {'Content-Type' => 'text/plain'}, 'Invalid sha' unless sha == params['sha']
  end

end

not_found do
  [404, {'Content-Type' => 'text/plain'}, ['404 Not found']]
end

error do
  [500, {'Content-Type' => 'text/plain'}, ['500 An error occured']]
end

get '/' do
  'ok'
end

get '/images/*' do |data|
  validate_sha(data)

  steps = Dragonfly::Serializer.b64_decode(data)

  steps = MultiJson.load(steps)

  image = steps.inject(dragonfly) do |image, step|
    raise "invalid job description" unless image.respond_to?(step.first)

    image.send(*step)
  end

  begin
    Timeout::timeout(25) { image.to_response(env) }
  rescue Timeout::Error => e
    halt 500
  rescue OpenURI::HTTPError => e
    halt 404
  end
end


