require 'rails_helper'

feature 'public division flow' do
  let(:division) { create(:division) }

  it 'displays division information' do
    visit public_division_path(short_name: division.short_name)
    expect(page).to have_content(division.name)
  end
end
