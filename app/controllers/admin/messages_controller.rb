class Admin::MessagesController < Admin::ResourceController
  only_allow_access_to :index, :show, :new, :create, :edit, :update, :remove, :destroy, :settings,
    :when => :admin,
    :denied_url => { :controller => 'pages', :action => 'index' },
    :denied_message => 'You must be an administrator to add or modify readers'

  helper :reader
  skip_before_filter :load_model
  before_filter :load_model, :except => :index    # we want the filter to run before :show too
  before_filter :set_function, :only => :new
  before_filter :get_group, :only => :new

  # here :show is the preview/send page
  # continue_url is extended below to redirect to show rather than index after editing.
  def show

  end
  
  def destroy
    if @message
      @message.destroy
      flash[:notice] = 'The message has been succesfully deleted.'
    else
      flash[:error] = 'Could not find that message. It must have been already deleted.'
    end
    redirect_to admin_messages_url
  end

  # mock email view called into an iframe in the :show view
  # the view calls @message.preview, which returns the message body
  def preview
    render :layout => false
  end

  def deliver
    @readers = []
    case params['delivery']
    when "all"
      @readers = @message.possible_readers
    when "inactive"
      @readers = @message.inactive_readers
    when "unsent"
      @readers = @message.undelivered_readers
    when "selected_groups"
      load_selected_groups
      load_readers_for_groups
    when "newsletter_and_selected_groups"
      load_selected_groups
      load_readers_for_groups_and_newsletter
    else
      redirect_to admin_message_url(@message)
      return
    end

    failures = @message.deliver(@readers) || []
    if failures.length == @readers.length
      flash[:error] = t("reader_extension.all_deliveries_failed")
    else
      if failures.any?
        addresses = failures.map(&:email).to_sentence
        flash[:notice] = t("reader_extension.some_deliveries_failed")
      else
        flash[:notice] = t("reader_extension.message_delivered")
      end
      @message.update_attribute :sent_at, Time.now
    end
    redirect_to admin_message_url(@message)
  end

protected

  def load_selected_groups
    if params[:group_ids] && !params[:group_ids].empty?
      @groups = Group.find(params[:group_ids])
    else
      @groups = []
    end
  end

  def load_readers_for_groups
    @readers = @groups.empty? ? [] : Reader.in_groups(@groups)
  end

  def load_readers_for_groups_and_newsletter
    newsletter_group = Group.find(211)
    raise ArgumentError.new("This feature needs a newsletter group") unless newsletter_group
    @readers = @groups.empty? ? [] : Reader.in_groups(@groups).also_in_group(newsletter_group)
  end

  def continue_url(options)
    if action_name == "destroy"
      redirect_to admin_messages_url
    else
      options[:redirect_to] || (params[:continue] ? {:action => 'edit', :id => model.id} : admin_message_url(model))
    end
  end

  def set_function
    if params[:function]
      model.function_id = params[:function]
    end
  end

  def get_group
    @group = Group.find(params[:group_id]) if params[:group_id]
  end

end
