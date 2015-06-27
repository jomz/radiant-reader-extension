class AddDisabledToReaders < ActiveRecord::Migration
  def self.up
    add_column :readers, :disabled, :boolean
  end

  def self.down
    remove_column :readers, :disabled
  end
end
