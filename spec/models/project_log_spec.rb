require 'rails_helper'

describe ProjectLog, :type => :model do
  it_should_behave_like 'translatable', ['summary', 'details']
  it_should_behave_like 'media_attachable'
  it_should_behave_like 'option_settable', ['progress_metric']


  it 'has a valid factory' do
    expect(create(:project_log)).to be_valid
  end
end
