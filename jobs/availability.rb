require 'net/http'
require 'json'
require 'rest-client'
require 'cgi'
require 'json'

apiKey = ENV['PINGDOM_API_KEY'] || ''
user = ENV['PINGDOM_USER'] || ''
password = ENV['PINGDOM_PASSWORD'] || ''

def performCheckAndSendEventToWidgets(widgetId, urlHostName, urlPath, tlsEnabled)

  if tlsEnabled
    http = Net::HTTP.new(urlHostName, 443)
    http.use_ssl = true
  else
    http = Net::HTTP.new(urlHostName, 80)
  end
  #url = urlHostName
  #response = RestClient.get(url)
  #JSON.parse(response)
  response = http.request(Net::HTTP::Get.new(urlPath))
  #state = json[:state]

  #if state == 'Good To Go'  
  if response.code == '200'
    send_event(widgetId, { value: 'ok', status: 'available' })
  else
    send_event(widgetId, { value: 'danger', status: 'unavailable' })
  end

end

def getUptimeMetricsFromPingdom(checkId, apiKey, user, password)

  # Get the unix timestamps
  timeInSecond = 7 * 24 * 60 * 60
  lastTime = (Time.now.to_i - timeInSecond )

  urlUptime = "https://#{CGI::escape user}:#{CGI::escape password}@api.pingdom.com/api/2.0/summary.average/#{checkId}?from=#{lastTime}&includeuptime=true"
  responseUptime = RestClient.get(urlUptime, {"App-Key" => apiKey, "Account-Email" => "ftpingdom@ft.com"})
  responseUptime = JSON.parse(responseUptime.body, :symbolize_names => true)

  totalUp = responseUptime[:summary][:status][:totalup]
  totalDown = responseUptime[:summary][:status][:totaldown]
  uptime = (100 * (totalUp.to_f / (totalDown.to_f + totalUp.to_f))).round(2)

  if uptime >= 99.90
    send_event(checkId, { current: uptime, status: 'uptime-999-or-above' })
  else
    send_event(checkId, { current: uptime, status: 'uptime-below-999' })
  end



end

SCHEDULER.every '10s', first_in: 0 do |job|

  performCheckAndSendEventToWidgets('alsglobal', 'acc-licence-svc.memb.ft.com', '/__gtg', true)
  performCheckAndSendEventToWidgets('alseu', 'acc-licence-svc-euwest1-prod.memb.ft.com', '/__gtg', true)
  performCheckAndSendEventToWidgets('alsus', 'acc-licence-svc-useast1-prod.memb.ft.com', '/__gtg', true)
  getUptimeMetricsFromPingdom('2014224', apiKey, user, password)
  getUptimeMetricsFromPingdom('2014311', apiKey, user, password)
  getUptimeMetricsFromPingdom('2014309', apiKey, user, password)
  
end

