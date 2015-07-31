class AccountsController < ReaderActionController
  helper :reader
  
  before_filter :check_registration_allowed, :only => [:new, :create, :activate]
  before_filter :no_removing, :only => [:remove, :destroy]
  before_filter :i_am_me, :only => [:show, :edit, :edit_profile]
  before_filter :default_to_self, :only => [:show]
  before_filter :restrict_to_self, :only => [:edit, :edit_profile, :update, :resend_activation]
  before_filter :get_readers_and_groups, :only => [:index, :show]
  before_filter :require_reader, :except => [:new, :create, :activate]
  before_filter :require_reader_visibility
  before_filter :ensure_groups_subscribable, :only => [:update, :create]

  def index
    respond_to do |format|
      format.html {
        set_expiry
        render :template => 'readers/index'
      }
      format.csv {
        send_data Reader.csv_for(@readers), :type => 'text/csv; charset=utf-8; header=present', :filename => "everyone.csv"
      }
      format.vcard {
        send_data Reader.vcards_for(@readers), :filename => "everyone.vcf"
      }
    end
  end

  def show
    respond_to do |format|
      format.html {
        set_expiry
        render :template => 'readers/show'
      }
      format.vcard {
        send_data @reader.vcard.to_s, :filename => "#{@reader.filename}.vcf"	
      }
    end
  end
  
  def dashboard
    # @reader = current_reader
    expires_now
  end

  def new
    if current_reader
      flash[:error] = t('reader_extension.already_logged_in')
      redirect_to url_for(current_reader) and return
    end
    @reader = Reader.new
    session[:return_to] = request.referer
    session[:email_field] = @reader.generate_email_field_name
  end
  
  def edit
    expires_now
  end

  def edit_profile
    expires_now
  end

  def create
    @reader = Reader.new(params[:reader])
    @reader.clear_password = params[:reader][:password]

    unless @reader.email.blank?
      flash[:error] = t('reader_extension.please_avoid_spam_trap')
      @reader.email = ''
      @reader.errors.add(:trap, t("reader_extension.must_be_empty"))
      render :action => 'new' and return
    end

    unless @email_field = session[:email_field]
      flash[:error] = 'please_use_form'
      redirect_to new_reader_url and return
    end

    @reader.email = params[@email_field.intern]
    if (@reader.valid?)
      @reader.save!
      if Radiant::Config["reader.require_confirmation?"]
        @reader.send_activation_message
      else
        @reader.activate!
      end
      self.current_reader = @reader
      redirect_to reader_activation_url
    else
      @reader.email_field = session[:email_field]
      render :action => 'new'
    end
  end

  def update
    params[:reader][:clear_password] = params[:reader][:password] if params[:reader][:password]
    if @reader.update_attributes(params[:reader])
      flash[:notice] = t('reader_extension.account_updated')
      redirect_to reader_dashboard_url
    else
      render :action => 'edit'
    end
  end
  
protected

  def set_expiry
    if Radiant.config['directory.visibility'] == 'public'
      expires_in 1.day, :public => true, :private => false
    else
      expires_now
    end
  end

  def i_am_me
    params[:id] = current_reader.id if current_reader && params[:id] == 'me'
  end

  def default_to_self
    params[:id] ||= current_reader.id
  end
  
  def restrict_to_self
    flash[:error] = t("reader_extension.cannot_edit_others") if params[:id] && params[:id] != current_reader.id.to_s
    @reader = current_reader
  end
  
  def require_password
    return true if @reader.valid_password?(params[:reader][:current_password])

    # might as well get any other validation messages while we're at it
    @reader.attributes = params[:reader]
    @reader.valid?
    
    flash[:error] = t('reader_extension.password_incorrect')
    @reader.errors.add(:current_password, "not_correct")
    render :action => 'edit' and return false
  end
  
  def no_removing
    flash[:error] = t('reader_extension.cannot_delete_readers')
    redirect_to admin_readers_url
  end
  
  def check_registration_allowed
    unless Radiant::Config['reader.allow_registration?']
      flash[:error] = t("reader_extension.registration_disallowed")
      redirect_to reader_login_url
      false
    end
  end
  
private

  def get_readers_and_groups
    @readers = Reader.enabled.visible_to(current_reader)
    @groups = current_reader.groups
    @reader = Reader.find(params[:id]) if params[:id]
  end

  def require_reader_visibility
    # more useful than a 404 but perhaps too informative?
    raise ReaderError::AccessDenied, "You do not have permission to see that person." if @reader && !@reader.visible_to?(current_reader)
  end

  def ensure_groups_subscribable
    if params[:reader] && params[:reader][:group_ids]
      params[:reader][:group_ids].each do |g|
        raise ReaderError::AccessDenied, "One of those groups is not public and does not accept subscriptions." unless Group.find(g).public?
      end
    end
    true
  end

end
