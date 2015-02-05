class Check < ActiveRecord::Base
  serialize :custom_properties, JSON
  serialize :data, JSON

  validates :name, presence: true
  validates :url, presence: true
  validates :method, presence: true

  has_many :incidents

  def to_hash
    self.attributes.to_options
  end


end
