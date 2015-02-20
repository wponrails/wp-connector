require 'spec_helper'

describe WpApiWorker do

  it { is_expected.to be_processed_in :default }
  it { is_expected.to be_retryable false }
  it { is_expected.to be_unique }

  it 'calls create_or_update_all on model' do
    subject.perform('Post', 12)
    expect().to have_enqueued_job('Awesome', true)
  end
end