require 'rails_helper'

feature 'documentation' do
  let(:user) { create_admin(create(:division)) }

  before { login_as user }

  scenario 'creation' do
    visit new_admin_documentation_path(caller: 'loans#new', html_identifier: 'food')

    # html identifier is pre-filled
    expect(page).to have_field('HTML Identifier', with: 'food')
  end
end
