class <%= migration_class_name %> < ActiveRecord::Migration
  def change
<%- if migration_action == 'add' -%>
<% attributes.each do |attribute| -%>
  <%- if attribute.reference? -%>
    add_reference :<%= table_name %>, :<%= attribute.name %><%= attribute.inject_options %>
  <%- else -%>
    add_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
    <%- if attribute.has_index? -%>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
    <%- end -%>
  <%- end -%>
<%- end -%>
<%- end -%>
<%- if migration_action == 'remove' -%>
<% attributes.each do |attribute| -%>
<%- if migration_action -%>
  <%- if attribute.reference? -%>
    remove_reference :<%= table_name %>, :<%= attribute.name %><%= attribute.inject_options %>
  <%- else -%>
    <%- if attribute.has_index? -%>
    remove_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
    <%- end -%>
    remove_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
  <%- end -%>
<%- end -%>
<%- end -%>
<%- end -%>
<%- if migration_action == 'rename' -%>
<% attributes.each_with_index do |attribute, index| -%>
  <%- next if index % 2 != 0 %>
  rename_column :<%= table_name %>, :<%= attribute.name %>, :<%= attributes.at(index+1).name %>
<%- end -%>
<%- end -%>
  end
end
