require 'rails_helper'

feature 'visit loan index page' do
  let!(:div_us) { create(:division, name: "United States", short_name: "us") }
  let!(:div_pkmn) { create(:division, name: "The Pokémon", short_name: "pkmn") }
  let!(:div_pika) { create(:division, name: "The Pikachu", short_name: "pika", parent: div_pkmn) }
  let!(:div_kale) { create(:division, name: "The Kale", short_name: "kale", public: false) }

  let!(:loan_us) { create(:loan, :active, :featured, name: 'US loan', division: div_us) }
  let!(:loan_pkmn) { create(:loan, :active, :featured, name: 'Pokémon loan', division: div_pkmn) }
  let!(:loan_pika) { create(:loan, :active, :featured, name: 'Pikachu Loan', division: div_pika) }
  let!(:loan_kale) { create(:loan, :active, :featured, name: 'Kale Loan', division: div_kale) }

  let!(:loans) { [loan_us, loan_pkmn, loan_pika, loan_kale] }

  context 'on the loan index page' do
    #before { visit public_loans_path("us", division: "all") }

    it 'shows active loans' do
      # redirect to appropriate division
    end

    # TODO move
    xcontext 'show only public divisions on dropdown' do
      scenario 'non-public divisions do not show' do
        expect(page.all('select#division option').map(&:value)).to eq %w(all pkmn pika us)
      end
    end
  end
end
