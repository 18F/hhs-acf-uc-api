class EnrollmentProxy < ActiveRestClient::ProxyBase
  ID_PATTERN = /\/(\d+)\//
  get "/enrollment" do
    if url =~ ID_PATTERN
      match = url.match ID_PATTERN
      url "uac_info%7B*,/uac_program_info,/uac_sponsor_list%7D?uac_id=#{match[1]}/:json"
    else
      url "uac_info%7B*,/uac_program_info,/uac_sponsor_list%7D/%3Ajson"
    end
    response = passthrough
    translate(response) do |body|
      result = body['uac_info']
      result.each do |enrollment|
        enrollment['programs'] = enrollment['uac_program_info']
        enrollment.except! 'uac_program_info'
        enrollment['sponsors'] = enrollment['uac_sponsor_list']
        enrollment.except! 'uac_sponsor_list'
      end
    end
  end
end

class Enrollment < ActiveRestClient::Base
  verbose true
  proxy EnrollmentProxy
  base_url Rails.application.config.htsql_server_url

  get :all, "/enrollment"
  get :find, "/enrollment/:id/"

  after_request :fix_names

  private

  def fix_names(name, response)
    # HTSQL returns it as "application/javascript",
    # but ActiveRestClient throws ResponseParseException for that
    response.response_headers["content-type"] = "application/json"
  end
end
