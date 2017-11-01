class AddPositionToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :position, :integer
    Group.reset_column_information
    Group.find(:all).reject { |g| g.children.empty? }.each do |g|
      g.children.each_with_index do |child, index|
        child.update_attribute :position, index
      end
    end
  end

  def self.down
    remove_column :groups, :position
  end
end
