# spec/lib/tasks/wp_cache_rake_spec.rb
require 'spec_helper'

describe 'rake wp:cache:refresh' do
  include_context 'rake'

  its(:prerequisites) { should include('environment') }

  it 'generates a registrations report' do
    subject.invoke
    ReportGenerator.should have_received(:generate).with('users', csv)
  end

  it 'creates the users report with the correct data' do
    subject.invoke
    UsersReport.should have_received(:new).with(user_records)
  end
end