class ReaderMessageDelivery < ActiveRecord::Base
  belongs_to :message
  serialize :target_group_ids, Array
end
