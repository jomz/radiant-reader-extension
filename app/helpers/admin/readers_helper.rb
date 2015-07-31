module Admin::ReadersHelper
  def render_reader_group_node(group, locals = {})
    @current_node = group
    locals.reverse_merge!(:level => 0, :simple => false).merge!(:group => group)
    render :partial => 'admin/readers/reader_group_node', :locals =>  locals
  end
end