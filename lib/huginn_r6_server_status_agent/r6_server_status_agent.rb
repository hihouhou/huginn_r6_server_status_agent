module Agents
  class R6ServerStatusAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule '1h'

    description do
      <<-MD
      The Github notification agent fetches notifications and creates an event by notification.

      `changes_only` is only used to emit event about a status' change.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "AppID ": "e3d5ea9e-50bd-43b7-88bf-39794f4e3d40",
            "MDM": "4073",
            "SpaceID": "5172a557-50b5-4665-b7db-e3f2e8c5041d",
            "Category": "Instance",
            "Name": "Rainbow Six Siege - PC - LIVE",
            "Platform": "PC",
            "Status": "Online",
            "Maintenance": null,
            "ImpactedFeatures": [
        
            ]
          }
    MD

    def default_options
      {
        'changes_only' => 'true',
        'expected_receive_period_in_days' => '2',
      }
    end

    form_configurable :changes_only, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string

    def validate_options

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      fetch
    end

    private

    def fetch
      require 'net/http'
      require 'uri'
      
      uri = URI.parse("https://game-status-api.ubisoft.com/v1/instances?appIds=e3d5ea9e-50bd-43b7-88bf-39794f4e3d40")
      response = Net::HTTP.get_response(uri)
      
      log "request  status : #{response.code}"

      payload = JSON.parse(response.body)
      if interpolated['changes_only'] == 'true'
        if payload.to_s != memory['last_status']
          create_event payload: payload[0]
          memory['last_status'] = payload.to_s
        end
      else
        create_event payload: payload[0]
        if payload.to_s != memory['last_status']
          memory['last_status'] = payload.to_s
        end
      end
    end
  end
end
