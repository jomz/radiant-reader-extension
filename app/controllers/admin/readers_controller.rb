class Admin::ReadersController < Admin::ResourceController
  helper :reader
  paginate_models

  only_allow_access_to :new, :create, :edit, :update, :remove, :destroy, :settings,
    :when => :admin,
    :denied_url => { :controller => 'pages', :action => 'index' },
    :denied_message => 'You must be an administrator to add or modify readers'

  def create
    model.update_attributes!(params[:reader])
    model.clear_password = params[:reader][:password] if params[:reader] && params[:reader][:password]      # condition is so that radiant tests pass
    model.send_invitation_message
    flash[:notice] = t('reader_extension.reader_saved')
    response_for :create
  end

  private

    def load_models
      base_scope = model_class
      if params['q']
        base_scope = base_scope.search(params['q'])
      end
      self.models = paginated? ? base_scope.paginate(pagination_parameters) : base_scope.all
    end


end