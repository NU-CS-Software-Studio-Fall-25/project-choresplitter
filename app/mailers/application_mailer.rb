class ApplicationMailer < ActionMailer::Base
  # You need to verify this email in SendGrid settings (ask GPT)
  default from: "albertluo2027@u.northwestern.edu"
  layout "mailer"
end
