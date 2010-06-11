class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up<% attributes.each do |attribute| %>
    <%= migration_action %>_column :<%= table_name %>, :<%= attribute.name %><% if migration_action == 'add' %>, :<%= attribute.type %><% end -%>
  <%- end %>
  end

  def self.down<% attributes.reverse.each do |attribute| %>
    <%= migration_action == 'add' ? 'add' : 'remove' %>_column :<%= table_name %>, :<%= attribute.name %><% if migration_action == 'remove' %>, :<%= attribute.type %><% end -%>
  <%- end %>
  end
end
