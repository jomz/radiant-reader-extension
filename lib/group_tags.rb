module GroupTags
  include Radiant::Taggable
  include ReaderHelper

  class TagError < StandardError; end
  desc %{
    The root 'group' tag is not meant to be called directly.
    All it does is summon a group object so that its fields can be displayed with eg.

    <pre><code><r:group:name /></code></pre>

    To show a particular group, supply an id or name attribute. There is no access control
    involved here: if you choose to show a group on an unrestricted page, it will appear.

    Note that because of limitations in radius this has to be done in a containing root tag:

    <pre><code><r:group id="1"><r:group:url /></r:group></code></pre>
  }
  tag 'group' do |tag|
    if tag.attr['id']
      tag.locals.group = Group.find_by_id(tag.attr['id'])
    elsif tag.attr['name']
      tag.locals.group = Group.find_by_name(tag.attr['name'])
    elsif @mailer_vars
      tag.locals.group = @mailer_vars[:@group]
    end
    tag.locals.group ||= tag.locals.page.homegroup
    tag.expand if tag.locals.group
  end

  [:name, :description, :url].each do |field|
    desc %{
      Displays the #{field} field of the currently relevant group. Works in email messages too.

      <pre><code><r:group:#{field} /></code></pre>
    }
    tag "group:#{field}" do |tag|
      tag.locals.group.send(field)
    end
  end

  desc %{
    Sets the page scope to this group's home page

    <pre><code><r:group:homepage>...</r:group:homepage /></code></pre>
  }
  tag "group:homepage" do |tag|
    tag.expand if tag.locals.page = tag.locals.group.homepage
  end

  desc %{
    Expands if this group has messages.

    <pre><code><r:group:if_messages>...</r:group:if_messages /></code></pre>
  }
  tag "group:if_messages" do |tag|
    tag.expand if tag.locals.group.messages.ordinary.published.any?
  end

  desc %{
    Expands if this group does not have messages.

    <pre><code><r:group:unless_messages>...</r:group:unless_messages /></code></pre>
  }
  tag "group:unless_messages" do |tag|
    tag.expand unless tag.locals.group.messages.ordinary.published.any?
  end

  desc %{
    Loops through the non-functional messages (ie not welcomes and reminders) that belong to this group
    and that have been sent, though not necessarily to the present reader (which is the point, really).

    <pre><code><r:group:messages:each>...</r:group:messages:each /></code></pre>
  }
  tag "group:messages" do |tag|
    tag.locals.messages = tag.locals.group.messages.ordinary.published
    tag.expand
  end
  tag "group:messages:each" do |tag|
    result = []
    tag.locals.messages.each do |message|
      tag.locals.message = message
      result << tag.expand
    end
    result
  end

  desc %{
    Loops through the subgroups of the current group

    <pre><code><r:group:subgroups:each>...</r:group:subgroups:each /></code></pre>
  }
  tag "group:subgroups" do |tag|
    tag.expand
  end
  tag "group:subgroups:each" do |tag|
    result = []
    options = group_find_options(tag)
    groups = tag.locals.group.children.all(options)
    groups.each do |group|
      tag.locals.group = group
      result << tag.expand
    end
    result.join('')
  end

  def group_find_options tag
    attr = tag.attr.symbolize_keys
    options = {}

    by = (attr[:by] || 'position').strip
    order = (attr[:order] || 'asc').strip
    order_string = ''
    if Group.columns.map(&:name).include?(by)
      order_string << by
    else
      raise TagError.new("`by' attribute of `each' tag must be set to a valid field name")
    end
    if order =~ /^(asc|desc)$/i
      order_string << " #{$1.upcase}"
    else
      raise TagError.new(%{`order' attribute of `each' tag must be set to either "asc" or "desc"})
    end
    options[:order] = order_string
    options
  end
end
