require 'spec_helper'

# spec/lib/tasks/wp_cache_rake_spec.rb
describe 'wp:cache:refresh' do
  include_context 'rake'

  before do
    ReportGenerator.stubs(:generate)
    UsersReport.stubs(:new => report)
    User.stubs(:all => user_records)
  end

  its(:prerequisites) { should include("environment") }

  it "generates a registrations report" do
    subject.invoke
    ReportGenerator.should have_received(:generate).with("users", csv)
  end

  it "creates the users report with the correct data" do
    subject.invoke
    UsersReport.should have_received(:new).with(user_records)
  end
end