class TripMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.trip_mailer.invite_email.subject
  #
  def invite_email
    @email = params[:email]
    @trip = params[:trip]
    @url = params[:url]

    mail(to: @email, subject: "You have been invited to join the trip: #{@trip.name}")
  end
end
