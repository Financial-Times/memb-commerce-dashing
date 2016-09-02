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
offerHeader = ENV['OFFER_HEADER'] || ''
offerAuth = ENV['OFFER_AUTH'] || ''
offerId = ENV['OFFER_ID'] || ''
acsAuth = ENV['ACS_AUTH'] || ''
acsId = ENV['ACS_ID'] || ''
rtsAuth = ENV['RTS_AUTH'] || ''
rtsId = ENV['RTS_ID'] || ''
subsHeader = ENV['SUBS_HEADER'] || ''
subsAuth = ENV['SUBS_AUTH'] || ''
subsId = ENV['SUBS_ID'] || ''
apiId = ENV['API_ID'] || ''

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
end

def getUptimeMetricsFromPingdom(checkId, apiKey, user, password)

  # Get the unix timestamps
  timeInSecond = 7 * 24 * 60 * 60
  lastTime = (Time.now.to_i - timeInSecond )

  urlUptime = "https://#{CGI::escape user}:#{CGI::escape password}@api.pingdom.com/api/2.0/summary.average/#{checkId}?from=#{lastTime}&includeuptime=true"

  responseUptime = RestClient.get(urlUptime, {"App-Key" => apiKey, "Account-Email" => "ftpingdom@ft.com"})
  responseUptime = JSON.parse(responseUptime.body, :symbolize_names => true)

  avgResponseTime = responseUptime[:summary][:responsetime][:avgresponse]
  send_event(checkId+"resp", { current: avgResponseTime, status: 'uptime-999-or-above'})

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

def checkMembershipObjectWithHeader(widgetId, service, path, authHeader, authKey, objectId)
  url = "https://#{CGI::escape service}.memb.ft.com"+path+objectId 
  response = RestClient.get(url, {authHeader => authKey})
  #responseBody = JSON.parse(response.body, :symbolize_names => true)
  responseCode = response.code

  if responseCode == 200
    send_event(widgetId, {value: 'ok', status: 'available'})
  else
    send_event(widgetId, {value: 'danger', status: 'unavailable' })
  end

end

def checkMembershiObjectViaAWS(widgetId, service, apiId)
  url = "https://#{CGI::escape apiId}.execute-api.eu-west-1.amazonaws.com/prod/getServiceResponse"
  payload = { 'service' => service}
  encoded = JSON.generate(payload)
  header = { 'Content-Type' => 'application/json' }
  response = RestClient.post(url, encoded, header)
  responseBody = JSON.parse(response.body, :symbolize_names => true)
  responseCode = responseBody[:status_code]
  if responseCode == 200
    send_event(widgetId, {value: 'ok', status: 'available'})
  else
    send_event(widgetId, {value: 'danger', status: 'unavailable' })
  end

end
SCHEDULER.every '10s', first_in: 0 do |job|

  checkMembershipObject('als','acc-licence-svc', '/membership/licences/v1/', alsAuth, alsId)
  checkMembershipObjectWithHeader('offerapi','offer-api', '/membership/offers/v1/', offerHeader, offerAuth, offerId)
  checkMembershipObject('acs','acq-context-svc', '/acquisition-contexts/v1/', acsAuth, acsId)
  checkMembershipObject('rts','redeem-token-svc', '/redeemable-tokens/v1/', rtsAuth, rtsId)
  checkMembershipObjectWithHeader('subs','subscription-api-gw-eu-west-1-prod', '/subscriptions?userId=', subsHeader, subsAuth, subsId)
  checkMembershiObjectViaAWS('uds','user-details-svc', apiId)
  checkMembershiObjectViaAWS('pms','payment-mthd-svc', apiId)
  getUptimeMetricsFromPingdom('2109418', apiKey, user, password)
  getUptimeMetricsFromPingdom('1694251', apiKey, user, password)
  getUptimeMetricsFromPingdom('2109444', apiKey, user, password)
  getUptimeMetricsFromPingdom('2110970', apiKey, user, password)
  getUptimeMetricsFromPingdom('2160233', apiKey, user, password)
  getUptimeMetricsFromPingdom('2275954', apiKey, user, password)
  getUptimeMetricsFromPingdom('2286018', apiKey, user, password)

end

