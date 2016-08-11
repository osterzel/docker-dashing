#!/usr/bin/env ruby

require 'net/http'
require 'json'

SENSU_ENABLED = ENV['SENSU_ENABLED'] || 'false'
SENSU_API_ENDPOINT = ENV.fetch('SENSU_API_ENDPOINT') { 'http://localhost:4567' }
# Set user and password if you want to enable authentication.
# Otherwise, leave them blank.
SENSU_API_USER = ENV.fetch('SENSU_API_USER') { '' }
SENSU_API_PASSWORD = ENV.fetch('SENSU_API_PASSWORD') { '' }

if SENSU_ENABLED != 'true'
  puts "Sensu plugin disabled, set SENSU_ENABLED=true to enable"
else

  SCHEDULER.every '30s', :first_in => 0 do |job|

    critical_count = 0
    warning_count = 0
    client_warning = Array.new
    client_critical = Array.new
    auth = (SENSU_API_USER.empty? || SENSU_API_PASSWORD.empty?) ? false : true

    event = ["Failed"]
    begin
        uri = URI(SENSU_API_ENDPOINT+"/events")
        req = Net::HTTP::Get.new(uri)
        req.basic_auth SENSU_API_USER, SENSU_API_PASSWORD if auth
        response = Net::HTTP.start(uri.hostname, uri.port) {|http|
          http.request(req)
        }
        events = JSON.parse(response.body)
    rescue 
      puts "Unable to connect to sensu endpoint"
    end
    warn = Array.new
    crit = Array.new

    events.each do |event|
      status = event['check']['status']
      if status == 1
        warn.push(event)
        warning_count += 1
      elsif status == 2
        crit.push(event)
        critical_count += 1
      end
    end
    if !warn.empty?
      warn.each do |entry|
        client_warning.push( {:label=>entry['client']['name'], :value=>entry['check']['name']} )
      end
    end
    if !crit.empty?
      crit.each do |entry|
        client_critical.push( {:label=>entry['client']['name'], :value=>entry['check']['name']} )
      end
    end

    status = "green" 
    if critical_count > 0 
      status = "red"
    elsif warning_count > 0
      status = "yellow"
    end
   
    send_event('sensu-status', { criticals: critical_count, warnings: warning_count, status: status })
    send_event('sensu-warn-list', { items: client_warning })
    send_event('sensu-crit-list', { items: client_critical })

  end
end