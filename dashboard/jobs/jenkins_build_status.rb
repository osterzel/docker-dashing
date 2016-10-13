require 'net/http'
require 'json'

JENKINS_ENABLED = ENV['JENKINS_ENABLED'] || 'false'
JENKINS_URI = ENV['JENKINS_URI'] || "http://localhost:8080/"
JENKINS_USER = ENV['JENKINS_USER'] || "null"
JENKINS_PASSWORD = ENV['JENKINS_PASSWORD'] || "null"

JENKINS_AUTH = {
  'name' => JENKINS_USER,
  'password' => JENKINS_PASSWORD
}

if JENKINS_ENABLED != "true"
	puts "Jenkins plugin disabled set JENKINS_ENABLED=true to enable"
else

  SCHEDULER.every '10s' do

    json = getFromJenkins(JENKINS_URI + 'api/json?pretty=true')

    failedJobs = Array.new
    succeededJobs = Array.new
    array = json['jobs']
    array.each {
      |job|

      next if job['color'] == 'disabled'
      next if job['color'] == 'notbuilt'
      next if job['color'] == 'blue'
      next if job['color'] == 'blue_anime'

      jobStatus = '';
      if job['color'] == 'yellow' || job['color'] == 'yellow_anime'
        jobStatus = getFromJenkins(job['url'] + 'lastUnstableBuild/api/json')
      elsif job['color'] == 'aborted' || job['color'] == 'aborted_anime'
        jobStatus = getFromJenkins(job['url'] + 'lastUnsuccessfulBuild/api/json')
      else
        jobStatus = getFromJenkins(job['url'] + 'lastFailedBuild/api/json')
      end

      culprits = jobStatus['culprits']

      if ! culprits.blank?
        culpritName = getNameFromCulprits(culprits)
        if culpritName != ''
           culpritName = culpritName.partition('<').first
        end
      end

      failedJobs.push({ label: job['name'], value: culpritName})
    }

    failed = failedJobs.size > 0

    send_event('jenkinsBuildStatus', { failedJobs: failedJobs, succeededJobs: succeededJobs, failed: failed })
  end

  def getFromJenkins(path)

    uri = URI.parse(path)
    response = nil
    Net::HTTP.start(uri.host, uri.port, :verify_mode => OpenSSL::SSL::VERIFY_NONE, :use_ssl => uri.scheme == 'https') do |http|
       request = Net::HTTP::Get.new uri.request_uri
       if JENKINS_AUTH['name']
         request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
       end
       response = http.request request 
    end

    json = JSON.parse(response.body)
    return json
  end

  def getNameFromCulprits(culprits)
    culprits.each {
      |culprit|
      return culprit['fullName']
    }
    return ''
  end
end
