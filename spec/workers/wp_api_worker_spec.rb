require 'bundler/setup'
Bundler.setup

require File.join(File.dirname(__FILE__), '..', '..', 'app', 'workers', 'wp_api_worker')

describe WpApiWorker do

  xit { is_expected.to be_processed_in :default }
  xit { is_expected.to be_retryable false }
  xit { is_expected.to be_unique }

  xit 'calls create_or_update_all on model' do
    subject.perform
    expect().to have_enqueued_job('Awesome', true)
  end
end