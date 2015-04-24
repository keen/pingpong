require 'json'

class Incident < ActiveRecord::Base
  serialize :check_response, JSON

  belongs_to :check

  STATUS_OK = 1
  STATUS_WARN = 2
  STATUS_BAD = 3

  scope :most_recent_for_check, ->(check, limit) {
    where(:check_id => check.id).order('created_at desc').limit(limit)
  }

  def self.create_bad_from_check(check, info, response)
    self.createFromCheck(STATUS_BAD, check, info, response)
  end

  def self.create_warn_from_check(check, info, response)
    self.createFromCheck(STATUS_WARN, check, info, response)
  end

  def self.create_ok_from_check(check, info, response)
    self.createFromCheck(STATUS_OK, check, info, response)
  end

  def is_ok?
    self.incident_type == STATUS_OK
  end

  def is_warn?
    self.incident_type == STATUS_WARN
  end

  def is_bad?
    self.incident_type == STATUS_BAD
  end

  def status_icon_css_text
    is_ok? ? "" : is_warn? ? " warning" : " error"
  end

  def email_subject
    subject = ""

    if is_warn?
      subject = "Warning"
    elsif is_bad?
      subject = "Failure"
    end

    subject + " for check '#{check.name}'"
  end

  def email_body
    message = "Incident report for check '#{check.name}':\n\n" +
      info + "\n\n" +
      "Check Response: \n\n" +
      JSON.pretty_generate(JSON.parse(check_response))
  end

  private
  def self.createFromCheck(status, check, info, response)
    inc = Incident.new
    inc.info = info
    inc.incident_type = status
    inc.check_response = response

    check.incidents << inc

    inc
  end
end
