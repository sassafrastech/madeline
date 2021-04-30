require "rails_helper"

feature "loan details" do
  let!(:div_us) { create(:division, name: "United States", short_name: "us") }
  let!(:loan) do
    create(
      :loan,
      :public, :active, :with_translations, :with_loan_media, :with_coop_media, :with_log_media,
      division: div_us
    )
  end
  let!(:organization) { loan.organization }
  let!(:active_loans) do
    create_list(:loan, 2,
      :public, :active, :with_translations, organization: organization, division: div_us)
  end
  let!(:completed_loans) do
    create_list(:loan, 2,
      :public, :completed, :with_translations, organization: organization, division: div_us)
  end
  let!(:hidden_past_loans) do
    create_list(:loan, 2,
      :public, :prospective, :with_translations, organization: organization, division: div_us)
  end

  before { visit public_loan_path("us", loan) }

  it "should have general information about loan" do
    # redirect to appropriate division page
  end

  context "with past loans from same cooperative" do
    xit "should show past loan information" do
      active_loans.each do |loan|
        expect(page).to have_content loan.status
        expect(page).to have_content loan.signing_date_long
        expect(page).to have_content loan.summary
      end

      completed_loans.each do |loan|
        expect(page).to have_content loan.status
        expect(page).to have_content loan.signing_date_long
        expect(page).to have_content loan.summary
      end

      hidden_past_loans.each do |loan|
        expect(page).not_to have_content loan.status
        expect(page).not_to have_content loan.signing_date_long
        expect(page).not_to have_content loan.summary
      end
    end
  end
end
