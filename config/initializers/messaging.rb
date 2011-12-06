# This configuration is suitable for development, it should be managed by puppet
# in production.
# TODO: Check if this is thread/forked process safe under passenger. Possible risk
# that client connections get copied when passenger forks a process but the mutexes
# protecting those connections do not.
require 'active_record_ext'
require 'messenger'

ActiveRecord::Base.marples_client_name = 'need-o-tron'
ActiveRecord::Base.marples_logger = Rails.logger

if Rails.env.test? or ENV['NO_MESSENGER'].present?
  NeedStateListener.client = Marples::NullTransport.instance
  ActiveRecord::Base.marples_transport = Marples::NullTransport.instance
  Messenger.transport = Marples::NullTransport.instance
else
  stomp_url = "failover://(stomp://support.cluster:61613,stomp://support.cluster:61613)"
  NeedStateListener.logger = Rails.logger

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        Messenger.transport = Stomp::Client.new stomp_url
        NeedStateListener.client = Stomp::Client.new stomp_url
        ActiveRecord::Base.marples_transport = Stomp::Client.new stomp_url
      end
    end
  else
    Messenger.transport = Stomp::Client.new stomp_url
    NeedStateListener.client = Stomp::Client.new stomp_url
    ActiveRecord::Base.marples_transport = Stomp::Client.new stomp_url
  end
end
