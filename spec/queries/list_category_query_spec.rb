require 'rails_helper'

RSpec.describe ListCategoryQuery do
  let(:year) { 2099 }
  let(:other_year) { year - 1 }
  let(:category1) { create(:category, name: 'Best Picture') }
  let(:category2) { create(:category, name: 'Best Director') }
  let(:category3) { create(:category, name: 'Best Actor') }
  let(:movie) { create(:movie, title: 'Grand Hotel') }
  let(:movie_with_english_title) { create(:movie, title: 'Sen to Chihiro', english_title: 'Spirited Away') }
  let!(:nomination1) { create(:nomination, movie: movie, category: category1, year: year) }
  let!(:nomination2) { create(:nomination, movie: movie, category: category2, year: year) }
  let!(:nomination3) { create(:nomination, movie: movie, category: category3, year: other_year) }
  let!(:nomination4) { create(:nomination, movie: movie_with_english_title, category: category1, year: year) }

  describe '#results' do
    context 'without search query' do
      it 'returns all categories for the year' do
        query = described_class.new({}, year)

        result = query.results

        expect(result).to include(category1, category2)
        expect(result).not_to include(category3)
      end
    end

    context 'with search query' do
      it 'returns categories matching the query for the year' do
        query = described_class.new({ query: 'Picture' }, year)

        result = query.results

        expect(result).to include(category1)
        expect(result).not_to include(category2)
        expect(query.matched_movies_count).to eq(0)
      end

      it 'is case insensitive' do
        query = described_class.new({ query: 'director' }, year)

        result = query.results

        expect(result).to include(category2)
      end

      it 'returns categories matching movie titles in the selected year' do
        query = described_class.new({ query: 'Grand' }, year)

        result = query.results

        expect(result).to include(category1, category2)
        expect(result).not_to include(category3)
        expect(query.matched_movies_count).to eq(1)
      end

      it 'returns categories matching english movie titles' do
        query = described_class.new({ query: 'Spirited' }, year)

        result = query.results

        expect(result).to include(category1)
        expect(query.matched_movies_count).to eq(1)
      end

      it 'escapes special LIKE characters (%) as literal characters' do
        movie_with_percent = create(:movie, title: '100% Wolf')
        create(:nomination, movie: movie_with_percent, category: category1, year: year)

        query = described_class.new({ query: '100%' }, year)

        result = query.results

        expect(result).to include(category1)
        expect(query.matched_movies_count).to eq(1)
      end

      it 'escapes special LIKE characters (_) as literal characters' do
        movie_with_underscore = create(:movie, title: 'S_pecial Movie')
        create(:nomination, movie: movie_with_underscore, category: category2, year: year)

        query = described_class.new({ query: 'S_pecial' }, year)

        result = query.results

        expect(result).to include(category2)
        expect(query.matched_movies_count).to eq(1)
      end
    end

    context 'when no categories match' do
      it 'returns empty collection' do
        query = described_class.new({ query: 'Nonexistent' }, year)

        result = query.results

        expect(result).to be_empty
      end
    end
  end
end
