class Incident < ActiveRecord::Base
  belongs_to :check

  STATUS_OK = 1
  STATUS_WARN = 2
  STATUS_BAD = 3
end
