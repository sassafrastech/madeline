require 'rails_helper'

describe DivisionPolicy do
  subject { DivisionPolicy.new(user, division) }
  # 'record_type' must be defined for the 'index' action tests to use the correct policy instance.
  let(:record_type) { Division }

  let!(:parent_division) { create(:division) }
  let!(:division) { create(:division, parent: parent_division) }
  let!(:child_division) { create(:division, parent: division) }
  let!(:private_division) { create(:division, parent: division, public: false) }

  context 'being a member of a division' do
    let(:user) { create(:user, :member, division: division) }

    permit_actions [:show]
    forbid_actions [:index, :create, :edit, :update, :destroy]
  end

  context 'being an admin of a division' do
    let(:user) { create(:user, :admin, division: division) }

    permit_actions [:index, :show, :edit, :update]
    forbid_actions [:create, :destroy]
  end

  context 'being a member of a parent division' do
    let(:user) { create(:user, :member, division: parent_division) }

    permit_actions [:show]
    forbid_actions [:index, :create, :edit, :update, :destroy]
  end

  context 'being an admin of a parent division' do
    let(:user) { create(:user, :admin, division: parent_division) }

    permit_actions [:index, :show, :create, :edit, :update]
    it 'cannot delete division with a child' do
      should forbid_action :destroy
    end
    it 'can delete division without children' do
      expect(DivisionPolicy.new(user, child_division).destroy?).to be_truthy
    end

  end

  context 'being a member of a child division' do
    let(:user) { create(:user, :member, division: child_division) }

    forbid_all
  end

  context 'being an admin of a child division' do
    let(:user) { create(:user, :admin, division: child_division) }

    forbid_all_but_index
  end

  describe 'Scope' do
    context 'being a member of a division' do
      let(:user) { create(:user, :member, division: division) }
      it 'cannot resolve the parent division' do
        expect(division_id_scope(user, parent_division.id)).not_to exist
      end
      it 'can resolve the division' do
        expect(division_id_scope(user, division.id)).to exist
      end
      it 'can resolve the child division' do
        expect(division_id_scope(user, child_division.id)).to exist
      end
    end

    context 'being an admin of a division' do
      let(:user) { create(:user, :admin, division: division) }
      it 'cannot resolve the parent division' do
        expect(division_id_scope(user, parent_division.id)).not_to exist
      end
      it 'can resolve the division' do
        expect(division_id_scope(user, division.id)).to exist
      end
      it 'can resolve the child division' do
        expect(division_id_scope(user, child_division.id)).to exist
      end
    end

    context 'being owned by, but without roll association with a division' do
      let(:user) { create(:user, division: division) }
      it 'cannot resolve any division' do
        expect(division_scope(user)).not_to exist
      end
    end

    context 'with a signed user' do
      let(:user) { create(:user, :admin, division: parent_division) }

      it 'shows all divisions' do
        expect(division_scope(user)).to contain_exactly(parent_division, division, child_division, private_division)
      end
    end

    context 'without a signed user' do
      let(:user) { nil }

      it 'shows all divisions' do
        expect(division_scope(user)).to contain_exactly(parent_division, division, child_division)
      end
    end

    def division_id_scope(user, division_id)
      division_scope(user, id: division_id)
    end

    def division_scope(user, conditions = nil)
      DivisionPolicy::Scope.new(user, Division.where(conditions)).resolve
    end
  end

end

