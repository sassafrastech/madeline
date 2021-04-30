# == Schema Information
#
# Table name: divisions
#
#  accent_fg_color                :string
#  accent_main_color              :string
#  banner_bg_color                :string
#  banner_fg_color                :string
#  closed_books_date              :date
#  created_at                     :datetime         not null
#  currency_id                    :integer
#  custom_data                    :json
#  description                    :text
#  id                             :integer          not null, primary key
#  interest_income_account_id     :integer
#  interest_receivable_account_id :integer
#  internal_name                  :string
#  locales                        :json
#  logo                           :string
#  logo_content_type              :string
#  logo_file_name                 :string
#  logo_file_size                 :integer
#  logo_text                      :string
#  logo_updated_at                :datetime
#  name                           :string
#  notify_on_new_logs             :boolean          default(FALSE)
#  organization_id                :integer
#  parent_id                      :integer
#  principal_account_id           :integer
#  public                         :boolean          default(FALSE), not null
#  qb_parent_class_id             :string
#  qb_read_only                   :boolean          default(TRUE), not null
#  short_name                     :string
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_divisions_on_currency_id                     (currency_id)
#  index_divisions_on_interest_income_account_id      (interest_income_account_id)
#  index_divisions_on_interest_receivable_account_id  (interest_receivable_account_id)
#  index_divisions_on_organization_id                 (organization_id)
#  index_divisions_on_principal_account_id            (principal_account_id)
#  index_divisions_on_short_name                      (short_name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (currency_id => currencies.id)
#  fk_rails_...  (interest_income_account_id => accounting_accounts.id)
#  fk_rails_...  (interest_receivable_account_id => accounting_accounts.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (principal_account_id => accounting_accounts.id)
#

require 'rails_helper'

describe Division, type: :model do
  it 'has a valid factory' do
    expect(create(:division)).to be_valid
  end

  it 'can only have one root' do
    root_division
    expect { create(:division, parent: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context 'short name' do
    let(:uuid_1) { 'a123uuid' }
    let(:uuid_2) { 'b123uuid' }
    let(:uuid_3) { 'c123uuid' }
    let(:uuid_4) { 'd123uuid' }

    before {
      allow(SecureRandom).to receive(:uuid).and_return(uuid_1, uuid_2, uuid_3, uuid_4)
      create(:division, name: "preexisting")
    }


    let!(:division_1) { create(:division, name: 'trouble') }
    let!(:division_2) { create(:division, name: 'trouble', notify_on_new_logs: true) }
    let!(:division_3) { create(:division, name: '---') }

    it 'generates a short name if one is not provided' do
      expect(division_1.short_name).to eq('trouble')
    end

    it 'generates a unique short name if division name is a repeat' do
      new_division = create(:division, name: "preexisting")
      expect(new_division.reload.short_name).to include("preexisting-", "uuid")
    end

    it 'generates a unique short name if provided short_name is a repeat' do
      new_division = create(:division, name: "preexisting", short_name: "preexisting")
      expect(new_division.reload.short_name).to include("preexisting-", "uuid")
    end

    it 'leaves pre-existing uuid alone when re-saving division' do
      division_1.save!
      expect(division_1.reload.short_name).to eq ('trouble')
    end

    it 'allows manual update of short_name on a division' do
      division_1.short_name = "mytrouble"
      division_1.save!
      expect(division_1.reload.short_name).to eq ('mytrouble')
    end

    it 'generates a short name for division with the same name' do
      expect(division_2.short_name).to include("trouble-", "uuid")
    end

    it 'generates short name for division with just hyphens' do
      expect(division_3.short_name).to include("uuid")
    end
  end

  describe '#qb_division' do
    subject { division.qb_division }

    context 'for root division' do
      let(:division) { root_division }

      context 'with no qb connection' do
        it { is_expected.to be_nil }
      end

      context 'with connection on root division' do
        let!(:connection) { create(:accounting_qb_connection, division: division) }
        it { is_expected.to eq(division) }
      end
    end

    context 'for descendant division' do
      let(:parent) { create(:division, parent: root_division) }
      let(:division) { create(:division, parent: parent) }

      context 'with no qb connection' do
        it { is_expected.to be_nil }
      end

      context 'with connection on self' do
        let!(:connection) { create(:accounting_qb_connection, division: division) }
        it { is_expected.to eq(division) }
      end

      context 'with connection on parent division' do
        let!(:connection) { create(:accounting_qb_connection, division: parent) }
        it { is_expected.to eq(parent) }
      end

      context 'with connection on root division' do
        let!(:connection) { create(:accounting_qb_connection, division: root_division) }
        it { is_expected.to eq(root_division) }
      end
    end
  end
end
