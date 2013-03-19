class Admin::ReaderConfigurationController < Admin::ConfigurationController
  helper :reader

  only_allow_access_to :index, :show, :new, :create, :edit, :update, :remove, :destroy, :settings,
    :when => :admin,
    :denied_url => { :controller => 'pages', :action => 'index' },
    :denied_message => 'You must be an administrator to add or modify readers'

end