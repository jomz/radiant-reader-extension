class AddGroupAccessTypeToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :group_access_type, :string, :length => 3, :default => 'or'
  end

  def self.down
    remove_column :messages, :group_access_type
  end
end
