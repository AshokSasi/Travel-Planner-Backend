# Preview all emails at http://localhost:3000/rails/mailers/trip_mailer
class TripMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/trip_mailer/invite_email
  def invite_email
    TripMailer.invite_email
  end

end
