Rails.application.routes.draw do
  #get 'parameters/index'

  #get 'parameter/index'

  root 'static_pages#home'

  get 'static_pages/home'

  get '/settings', to: 'static_pages#settings'
  get '/download', to: 'static_pages#download'
  get '/upload', to: 'static_pages#upload'

  get '/values/get', to: 'values#get'
  get '/values/set', to: 'values#set'
  get '/values/form_get', to: 'values#form_get'
  get '/values/form_set', to: 'values#form_set'

  get '/api/token', to: 'api#get_token'

  get '/api/cpe/values', to: 'api#get_values'
  post '/api/cpe/values', to: 'api#set_values'

  get '/api/cpe/names', to: 'api#get_names'

  get '/api/cpe/attributes', to: 'api#get_attributes'
  post '/api/cpe/attributes', to: 'api#set_attributes'

  post '/api/cpe/object', to: 'api#add_object'
  delete '/api/cpe/object', to: 'api#delete_object'

  get '/api/cpe/get_rpc_method', to: 'api#get_rpc_method'
  get '/api/cpe/get_all_queued_transfers', to: 'api#get_all_queued_transfers'

  post '/api/cpe/reboot', to: 'api#reboot'
  post '/api/cpe/factory_reset', to: 'api#factory_reset'

  get '/api/cpe/message', to: 'api#get_message'
  get '/api/cpe/messages', to: 'api#get_messages'
  delete '/api/cpe/messages', to: 'api#delete_messages'

  post '/api/cpe/download', to: 'api#post_download'
  post '/api/cpe/upload', to: 'api#post_upload'
  get '/api/cpe/url/:operation/:type', to: 'api#get_url'

  get '/download/:type/:name', to: 'api#download_file', name: /[\w\d.]*/
  put '/upload/:type', to: 'api#upload_file'
  post '/upload/:type', to: 'api#upload_file_acs'

  get '/api/model', to: 'api#get_model'
  post '/api/model', to: 'api#post_model'

  get '/api/settings', to: 'api#get_settings'
  put '/api/settings', to: 'api#put_settings'

  get '/api/settings/cpe', to: 'api#get_cpe'
  put '/api/settings/cpe', to: 'api#put_cpe'

  get '/api/settings/acs', to: 'api#get_acs'
  put '/api/settings/acs', to: 'api#put_acs'

  post '/cwmp', to: 'cwmp#cwmp'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
