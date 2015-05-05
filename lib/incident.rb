require 'json'

class Incident < ActiveRecord::Base
  serialize :check_response, JSON

  belongs_to :check

  STATUS_OK = 1
  STATUS_WARN = 2
  STATUS_BAD = 3

  NUM_TO_KEEP = 50

  scope :most_recent_for_check, ->(check, limit) {
    where(:check_id => check.id).order('created_at desc').limit(limit)
  }

  scope :old_incidents_for_check, ->(check, offset) {
    where(:check_id => check.id).order('created_at desc').offset(offset)
  }

  after_create do
    oldIncidents = Incident.old_incidents_for_check(self.check, Incident::NUM_TO_KEEP)
    
    oldIncidents.each do |incident|
      Incident.destroy(incident.id)
    end
  end

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
    message = "Incident report for check '#{check.name}':<br><br>" +
      info + "<br><br>" +
      "Check Response: <br><br>" +
      "<pre>" +
      JSON.pretty_generate(check_response) +
      "</pre>"
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
