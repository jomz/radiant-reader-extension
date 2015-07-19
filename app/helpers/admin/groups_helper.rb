module Admin::GroupsHelper
  def render_admin_group_node(group, locals = {})
    @current_node = group
    locals.reverse_merge!(:level => 0, :simple => false).merge!(:group => group)
    render :partial => 'admin/groups/group_node', :locals =>  locals
  end
end

