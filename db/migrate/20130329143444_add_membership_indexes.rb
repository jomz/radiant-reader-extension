class AddMembershipIndexes < ActiveRecord::Migration
  def self.up
    add_index :memberships, :group_id
    add_index :memberships, :reader_id
  end

  def self.down
    remove_index :memberships, :group_id
    remove_index :memberships, :reader_id
  end
end
