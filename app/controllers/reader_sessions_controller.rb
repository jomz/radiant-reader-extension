class ReaderSessionsController < ReaderActionController
  helper :reader

  before_filter :require_reader, :only => :destroy
  radiant_layout { |controller| Radiant::Config['reader.layout'] }
  
  def show
    @reader = current_reader
    respond_to do |format|
      format.html { 
        if !@reader
          redirect_to reader_login_url
        elsif @reader.inactive?
          redirect_to reader_activation_url
        else
          redirect_to reader_profile_url
        end
      }
      format.js {
        render :partial => 'readers/controls', :layout => false
      }
    end
  end
  
  def new
    if current_reader
      if current_reader.activated?
        cookies[:error] = t('already_logged_in')
        redirect_to reader_url(current_reader)
      else
        cookies[:error] = t('account_requires_activation')
        redirect_to reader_activation_url
      end
    else
      @reader_session = ReaderSession.new
      expires_now
    end
  end
  
  def create
    @reader_session = ReaderSession.new(params[:reader_session])
    if @reader_session.save
      if @reader_session.reader.activated? && @reader_session.reader.clear_password        
        @reader_session.reader.clear_password = ""                          # we forget the cleartext version on the first successful login
        @reader_session.reader.save(false)
      end
      respond_to do |format|
        format.html {
          flash[:notice] = t('hello').titlecase + " #{@reader_session.reader.name}. " + t('welcome_back')
          redirect_back_or_to default_loggedin_url
        }
        format.js { 
          redirect_back_with_format(:js)
        }
      end
      
    else
      respond_to do |format|
        format.html { 
          flash[:error] = t('login_unknown')
          render :action => :new 
        }
        format.js { 
          render :action => :new, :layout => false 
        }
      end
    end
  end
  
  def destroy
    current_reader_session.destroy
    if current_user
      cookies[:session_token] = { :expires => 1.day.ago }
      current_user.forget_me
      session['user_id'] = nil
      current_user = nil
    end
    flash[:notice] = t('logout_message')
    redirect_to reader_login_url
  end
  
protected

  def default_loggedin_url
    reader_url(@reader_session.reader)
  end

end
