require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'diff_match_patch'

configure do
  set :server, 'thin'
  set :sockets, []
  set :textdata, "Hello There"
end

get '/' do
  redirect 'index.html'
end

get '/sync' do
  if !request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send(JSON.generate(["init",settings.textdata]))
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        #Update textdata by patch
        @dmp = DiffMatchPatch.new
        EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
        patch = JSON.parse(msg)[1];
        patches = @dmp.patch_fromText(patch)
        patched = @dmp.patch_apply(patches, settings.textdata)
        set :textdata, patched[0]
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
