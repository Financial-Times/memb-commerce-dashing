require 'net/http'
require 'json'
require 'rest-client'
require 'cgi'
require 'json'

apiKey = ENV['PINGDOM_API_KEY'] || ''
user = ENV['PINGDOM_USER'] || ''
password = ENV['PINGDOM_PASSWORD'] || ''
alsAuth = ENV['ALS_AUTH'] || ''
alsId = ENV['ALS_ID'] || ''
offerAuth = ENV['OFFER_AUTH'] || ''
offerId = ENV['OFFER_ID'] || ''
acsAuth = ENV['ACS_AUTH'] || ''
acsId = ENV['ACS_ID'] || ''
rtsAuth = ENV['RTS_AUTH'] || ''
rtsId = ENV['RTS_ID'] || ''

def performCheckAndSendEventToWidgets(widgetId, urlHostName, urlPath, authKey)

  url = "https://"+urlHostName+urlPath 
  response = RestClient.get(url, {"auth" => authKey})
  responseBody = JSON.parse(response.body, :symbolize_names => true)
  responseCode = response.code
  state = responseBody[:state]
  
  if responseCode == 200
    if state == "Good To Go"
      send_event(widgetId, {value: 'ok', status: 'available'})
    else
      send_event(widgetId, {value: 'danger', status: 'unavailable' })
    end
  else
    send_event(widgetId, {value: 'danger', status: 'unavailable' })
  end

  #if tlsEnabled
  #  http = Net::HTTP.new(urlHostName, 443)
  #  http.use_ssl = true
  #else
  #  http = Net::HTTP.new(urlHostName, 80)
  #end
  ##url = urlHostName
  ##response = RestClient.get(url)
  #response = http.request(Net::HTTP::Get.new(urlPath))
  ##json = JSON.parse(response)
  ##state = json[:state]

  ##if state == 'Good To Go'  
  #if response.code == '200'
  #  send_event(widgetId, { value: 'ok', status: 'available' })
  #else
  #  send_event(widgetId, { value: 'danger', status: 'unavailable' })
  #end

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

def checkMembershipObject(widgetId, service, path, authKey, objectId)
  url = "https://#{CGI::escape service}.memb.ft.com"+path+objectId 
  response = RestClient.get(url, {"auth" => authKey})
  #responseBody = JSON.parse(response.body, :symbolize_names => true)
  responseCode = response.code

  if responseCode == 200
    send_event(widgetId, {value: 'ok', status: 'available'})
  else
    send_event(widgetId, {value: 'danger', status: 'unavailable' })
  end

end

def checkOffer(widgetId, service, path, authKey, objectId)
  url = "https://#{CGI::escape service}.memb.ft.com"+path+objectId 
  response = RestClient.get(url, {"X-remclisf" => authKey})
  #responseBody = JSON.parse(response.body, :symbolize_names => true)
  responseCode = response.code

  if responseCode == 200
    send_event(widgetId, {value: 'ok', status: 'available'})
  else
    send_event(widgetId, {value: 'danger', status: 'unavailable' })
  end

end
SCHEDULER.every '10s', first_in: 0 do |job|

  performCheckAndSendEventToWidgets('alsglobal', 'acc-licence-svc.memb.ft.com', '/__gtg', alsAuth)
  performCheckAndSendEventToWidgets('alseu', 'acc-licence-svc-euwest1-prod.memb.ft.com', '/__gtg', alsAuth)
  performCheckAndSendEventToWidgets('alsus', 'acc-licence-svc-useast1-prod.memb.ft.com', '/__gtg', alsAuth)
  getUptimeMetricsFromPingdom('2014224', apiKey, user, password)
  getUptimeMetricsFromPingdom('2014311', apiKey, user, password)
  getUptimeMetricsFromPingdom('2014309', apiKey, user, password)
  checkMembershipObject('als','acc-licence-svc', '/membership/licences/v1/', alsAuth, alsId)
  checkOffer('offerapi','offer-api', '/membership/offers/v1/', offerAuth, offerId)
  checkMembershipObject('acs','acq-context-svc', '/acquisition-contexts/v1/', acsAuth, acsId)
  checkMembershipObject('rts','redeem-token-svc', '/redeemable-tokens/v1/', rtsAuth, rtsId)
  getUptimeMetricsFromPingdom('2109418', apiKey, user, password)
  getUptimeMetricsFromPingdom('1694251', apiKey, user, password)
  getUptimeMetricsFromPingdom('2109444', apiKey, user, password)
  getUptimeMetricsFromPingdom('2110970', apiKey, user, password)
  

end

