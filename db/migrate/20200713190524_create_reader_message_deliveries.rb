class CreateReaderMessageDeliveries < ActiveRecord::Migration
  def self.up
    create_table :reader_message_deliveries do |t|
      t.integer :message_id
      t.text    :target_group_ids
      t.timestamps
    end
  end

  def self.down
    drop_table :reader_message_deliveries
  end
end
