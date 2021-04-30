require 'rails_helper'

describe LoanPolicy do
  it_should_behave_like 'base_policy', :loan
  it_should_behave_like 'division_owned_scope', :loan

  subject { LoanPolicy.new(user, Loan.where(conditions)) }
  let!(:public_division) { create(:division) }
  let!(:public_div_featured_active_loan) { create(:loan, :active, division: public_division, public_level_value: 'featured') }
  let!(:public_div_featured_completed_loan) { create(:loan, :active, division: public_division, public_level_value: 'featured') }
  let!(:public_div_featured_other_loan) { create(:loan, status_value: "prospective", division: public_division, public_level_value: 'featured') }
  let!(:public_div_hidden_active_loan) { create(:loan, :active, division: public_division, public_level_value: 'hidden') }
  let!(:hidden_division) { create(:division, public: false, parent: public_division) }

  describe 'with user, as in madeline usage' do
    let!(:user) { create(:user, :admin, division: public_division) }

    it 'returns the correct loans' do
      expect(loan_scope(user).resolve).to contain_exactly(
        public_div_featured_active_loan,
        public_div_featured_completed_loan,
        public_div_featured_other_loan,
        public_div_hidden_active_loan
      )
    end

    it 'allows the show action' do
      permit_action [:show]
    end
  end

  describe 'without user, as in public usage' do
    let!(:user) { nil }

    it 'returns the correct loans' do
      expect(loan_scope(user).resolve).to contain_exactly(
        public_div_featured_active_loan,
        public_div_featured_completed_loan
      )
    end

    it 'allows the show action' do
      permit_action [:show]
    end
  end

  def loan_scope(user, conditions = nil)
    LoanPolicy::Scope.new(user, Loan.where(conditions))
  end
end
