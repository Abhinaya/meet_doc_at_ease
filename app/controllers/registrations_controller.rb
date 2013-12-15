class RegistrationsController < ApplicationController
  require 'twilio-ruby'
  include ActionView::Helpers::TextHelper
  skip_before_filter :verify_authenticity_token

  def create
    patient = Patient.create!(name: params[:name])
    redirect_to patients_path(patient)
  end

  def show
    message = params["txtweb-message"] || ""
    message_split = message.split(" ")
    from = message_split[1]
    to = message_split[3]
    routes = RestClient.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{from}&destination=#{to}&sensor=false")
    route = Route.create(directions: JSON.parse(routes)["routes"].first["legs"].first["steps"].collect{ |r| r["end_location"]})
    @route_instructions = "Please look into the map for tracking #{home_url(route.id)} #{strip_tags(@route_instructions)}. " + JSON.parse(routes)["routes"].first["legs"].first["steps"].collect{ |r| r["html_instructions"]}.join(" -> ")
    intimate_control_room
  end


  private
  def permit_params
    params.permit!
  end

  def intimate_control_room
    account_sid = 'ACdbf40a97127a8ad93496fdd02268b4eb'
    auth_token = '9610a0197afad48fa385b2ed433a352c'

    # set up a client to talk to the Twilio REST API
    @client = Twilio::REST::Client.new account_sid, auth_token

    @client.account.messages.create({
      :from => '+19708185644',
      :to => '+918754506975',
      :body  => strip_tags(@route_instructions)
    })
  end
end
