class Check < ActiveRecord::Base
  serialize :custom_properties, JSON
  serialize :data, JSON

  store :incident_checking, accessors: [:response_times, :response_codes], coder: JSON

  validates :name, presence: true
  validates :url, presence: true
  validates :frequency, presence: true
  validates :method, presence: true
  validate :post_must_have_data, on: :create

  has_many :incidents

  def post_must_have_data
    if self.method == "POST"
      errors.add(:data, "Must have data for a post body.") unless !self.data.empty?
    end
  end

  def add_response_time(time)
    if self.response_times
      self.response_times.push(time)
      self.response_times = self.response_times.slice(-30, 30) if self.response_times.size > 30
    else
      self.response_times = [time]
    end
  end

  def add_response_code(code)
    if self.response_codes
      self.response_codes.push(code)
      self.response_codes = self.response_codes.slice(-30, 30) if self.response_codes.size > 30
    else
      self.response_codes = [code]
    end
  end

  def to_hash
    attrs = self.attributes
    attrs.delete("incident_checking")
    attrs.delete("created_at")
    attrs.delete("updated_at")
    attrs.delete("http_username")
    attrs.delete("http_password")

    attrs.to_options
  end

end
