require 'enumerable_std_deviation'
require 'uri'

class Check < ActiveRecord::Base
  serialize :custom_properties, JSON
  serialize :data, JSON
  serialize :headers, JSON

  store :incident_checking, accessors: [:response_times, :response_codes], coder: JSON
  store :configurations, accessors: [:email_warn, :email_bad, :warn_thresh, :bad_thresh], coder: JSON

  validates :name, presence: true
  validates :url, presence: true
  validates :frequency, presence: true
  validates :frequency, numericality: { only_integer: true, greater_than: 0 }
  validates :method, presence: true
  validate :post_must_have_data, on: :create
  validate :url_formatting, on: :create

  has_many :incidents, :dependent => :destroy

  # how many response times before we start checking for incidents
  MIN_CHECK_LENGTH = 15

  # TODO: make these configurable with defaults
  MEAN_WARN_THRESHOLD = 1.25
  MEAN_BAD_THRESHOLD = 1.5
  STD_BAD_CUTOFF = 0.28
  STD_WARN_CUTOFF = 0.18

  after_initialize :initialize_defaults, :if => :new_record?

  def post_must_have_data
    if self.method == "POST"
      if !self.data
        errors.add(:data, "Can't be empty for a POST.")
      else
        errors.add(:data, "Must have data for a post body.") unless !self.data.empty?
      end
    end
  end

  def url_formatting
    uri = URI.parse(self.url)
    if !uri
      errors.add(:url, "Invalid.")
    end
    if !url.start_with?("http")
      errors.add(:url, "Must start with http/https.")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "Invalid.")
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

  def check_for_incidents(response)
    timeIncident = check_for_response_time_incidents(response)
    codeIncident = check_for_response_code_incidents(response)

    if !timeIncident && !codeIncident && ! self.is_ok?
      create_ok("Issue resolved.", response)
    end

    timeIncident || codeIncident
  end

  def to_hash
    attrs = self.attributes
    attrs.delete("configurations")
    attrs.delete("incident_checking")
    attrs.delete("created_at")
    attrs.delete("updated_at")
    attrs.delete("http_username")
    attrs.delete("http_password")

    attrs.to_options
  end

  def is_ok?
    self.incidents.empty? or self.incidents.last.is_ok?
  end

  def is_warn?
    not self.incidents.empty? and self.incidents.last.is_warn?
  end

  def is_bad?
    not self.incidents.empty? and self.incidents.last.is_bad?
  end

  def status_icon_css_text
    return "" if self.incidents.empty?
    return incidents.last.status_icon_css_text
  end

  def mean_time(ignore_recent=false)
    return 0 if self.response_times.nil? or self.response_times.empty?
    
    allTimes = ignore_recent ? self.response_times : self.response_times.slice(0, 29)
    allTimes.mean
  end

  def index_timeframe
    timeframe = "this_48_hours"

    if ((Time.now - created_at) / 1.hour).round < 1
      timeframe = "this_60_minutes"
    elsif ((Time.now - created_at) / 1.hour).round < 2
      timeframe = "this_120_minutes"
    elsif ((Time.now - created_at) / 1.hour).round < 6
      timeframe = "this_240_minutes"
    elsif ((Time.now - created_at) / 1.hour).round < 24
      timeframe = "this_24_hours"
    end

    timeframe
  end

  def show_timeframe
    timeframe = "this_48_hours"

    if ((Time.now - created_at) / 1.hour).round < 1
      timeframe = "this_60_minutes"
    elsif ((Time.now - created_at) / 1.hour).round < 2
      timeframe = "this_120_minutes"
    elsif ((Time.now - created_at) / 1.hour).round < 6
      timeframe = "this_240_minutes"
    elsif ((Time.now - created_at) / 1.hour).round < 24
      timeframe = "this_24_hours"
    end

    timeframe
  end

  def timeframe_interval(timeframe)
    interval = "hourly"

    if timeframe.ends_with?("minutes")
      interval = "minutely"
    end

    interval
  end

  private
  def check_for_response_time_incidents(response)
    issueFound = false

    return issueFound if not self.response_times or self.response_times.empty? or self.response_times.length < MIN_CHECK_LENGTH

    # first we want to see if the latest request time is way off the median
    allOldTimes = self.response_times.slice(0, 29)
    oldTimesMax = allOldTimes.max

    normalizedOldTimes = allOldTimes.normalize
    normalizedTimes = self.response_times.normalize

    oldTimesMean = allOldTimes.mean

    # compare the current time to the old mean
    if self.response_times.last / oldTimesMean > MEAN_BAD_THRESHOLD
      create_bad("Response time was a lot higher than the mean.", response)
      issueFound = true
    elsif self.response_times.last / oldTimesMean > MEAN_WARN_THRESHOLD
      create_warn("Response time was higher than the mean.", response)
      issueFound = true
    end

    # look at the standard deviation with the current time
    if normalizedTimes.standard_deviation > STD_BAD_CUTOFF
      create_bad("Variance in response times very volatile.", response)
      issueFound = true
    elsif normalizedTimes.standard_deviation > STD_WARN_CUTOFF
      create_warn("Variance in response times volatile.", response)
      issueFound = true
    end

    issueFound
  end

  def check_for_response_code_incidents(response)
    issueFound = false

    return issueFound if not self.response_codes or self.response_codes.empty?
    latestCode = self.response_codes.last.to_i
    secondToLastCode = self.response_codes.length > 1 ? self.response_codes[self.response_codes.length - 2].to_i : nil

    # lets do 300's first
    if latestCode >= 300 && latestCode < 400
      create_warn("Got a #{latestCode} response code.", response)
      issueFound = true
    end

    # now 400's
    if latestCode >= 400 && latestCode < 500
      if secondToLastCode && (secondToLastCode >= 400 && secondToLastCode < 500)
        create_bad("Got more than one #{latestCode} response code in a row.", response)
      else
        create_warn("Got a #{latestCode} response code.", response)
      end

      issueFound = true
    end

    # and last 500's
    if latestCode >= 500 && latestCode < 600
      if secondToLastCode && (secondToLastCode >= 500 && secondToLastCode < 600)
        create_bad("Got more than one #{latestCode} response code in a row.", response)
      else
        create_warn("Got a #{latestCode} response code.", response)
      end

      issueFound = true
    end

    issueFound
  end

  def last_incident_matches?(info)
    not incidents.empty? and incidents.last.info == info
  end

  def create_ok(message, response)
    return if last_incident_matches?(message)
    Incident.create_ok_from_check(self, message, response)
  end

  def create_warn(message, response)
    return if last_incident_matches?(message)
    Incident.create_warn_from_check(self, message, response)
  end

  def create_bad(message, response)
    return if last_incident_matches?(message)
    Incident.create_bad_from_check(self, message, response)
  end

  def initialize_defaults
    self.email_warn = false
    self.email_bad = true
    self.warn_thresh = MEAN_WARN_THRESHOLD
    self.bad_thresh = MEAN_BAD_THRESHOLD
  end
end
