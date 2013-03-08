
module SyncPad
  require 'sinatra/base'
  require 'json'
  require 'diff_match_patch'
  require 'pusher'
  class App < Sinatra::Base
    configure do
      @@textdata = "Hello There"
      Pusher.app_id = ENV['PUSHER_APP_ID']
      Pusher.key = ENV['PUSHER_KEY']
      Pusher.secret = ENV['PUSHER_SECRET']
    end

    get '/' do
      redirect 'index.html'
    end

    get '/init' do
      @@textdata
    end

    post '/sync' do
      id = params[:id]
      patch = params[:msg]
      @dmp = DiffMatchPatch.new
      Pusher['test_channel'].trigger('my_event', {:id => id, :msg => patch})
      patches = @dmp.patch_fromText(patch)
      patched = @dmp.patch_apply(patches, @@textdata)
      @@textdata = patched[0]
    end
  end
end