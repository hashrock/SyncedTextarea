

$: << File.expand_path('../../lib/', __FILE__)
require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'diff_match_patch'


configure do
  set :server, 'thin'
  set :sockets, []
  set :original, "Hello There"
end




get '/sync' do
  if !request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send(JSON.generate(["init",settings.original]))
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        @dmp = DiffMatchPatch.new
        EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
        patch = JSON.parse(msg)[1];
        patches = @dmp.patch_fromText(patch)
        patched = @dmp.patch_apply(patches, settings.original)
        set :original, patched[0]
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
