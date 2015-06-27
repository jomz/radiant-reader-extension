class CreateEmailLayout < ActiveRecord::Migration
  def self.up
    unless Layout.find_by_name(:email)
      Layout.create(:name => 'email', :content => "<r:content />")
    end
  end

  def self.down
    # Let it be
  end
end
