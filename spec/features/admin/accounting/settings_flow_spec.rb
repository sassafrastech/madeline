require 'rails_helper'

feature 'settings flow', :accounting do
  let(:division) { Division.root }
  let(:user) { create_admin(division) }

  before do
    login_as(user, scope: :user)
  end

  describe "authentication" do
    context "no qb connection" do

      # only case in accounting where division should not have accts or qb_connection at start of spec
      before do
        division.qb_connection.delete
      end

      scenario do
        visit "/admin/accounting/settings"
        expect(page).to have_content 'Not Connected'
        click_on 'Click To Connect'
        expect(page).to have_content "Connected to "
        expect(page).to have_content "QuickBooks data import pending"
      end
    end
  end

  describe "initial page load and authentication" do
    context "qb connection exists but qb grant invalid" do
      before do
        division.qb_connection.update_attributes!(invalid_grant: true)
      end
      scenario do
        visit "/admin/accounting/settings"
        expect(page).to have_content 'Not Connected'
        click_on 'Click To Connect'
        expect(page).to have_content "Connected to "
        expect(page).to have_content "QuickBooks data import pending"
      end
    end

    context "qb connection exists and qb grant is valid" do
      scenario do
        visit "/admin/accounting/settings"
        expect(page).to have_content "Connected to "
      end
    end
  end

  # describe "setting details" do
  #   # accounts
  #   # closed books date
  #   # read-only
  #   # submit form
  # end
  #
  describe "disconnect" do

  end
end