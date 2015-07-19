class Admin::GroupsController < Admin::ResourceController
  only_allow_access_to :index, :show, :new, :create, :edit, :update, :remove, :destroy, :settings,
    :when => :admin,
    :denied_url => { :controller => 'pages', :action => 'index' },
    :denied_message => 'You must be an administrator to add or modify readers'

  helper :reader
  paginate_models
  skip_before_filter :load_model
  before_filter :load_model, :except => :index    # we want the filter to run before :show too
  
  def show
    
  end
  
  def load_models
    # Group.arrange is used on admin/groups/index
  end
  
  def load_model
    self.model = if params[:id]
      model_class.find(params[:id])
    else
      model_class.new(:parent_id => params[:parent_id])
    end
  end
  
end
