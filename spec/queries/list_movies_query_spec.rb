require 'rails_helper'

RSpec.describe ListMoviesQuery do
  let(:year) { 2099 }
  let(:other_year) { year - 1 }
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:movie1) { create(:movie, title: 'Avatar', runtime: 180, rating: 8) }
  let(:movie2) { create(:movie, title: 'Batman', english_title: 'The Dark Knight', runtime: 120, rating: 7) }
  let(:movie3) { create(:movie, title: 'Cats', runtime: 90, rating: 5) }
  let!(:nomination1) { create(:nomination, movie: movie1, category: category, year: year) }
  let!(:nomination2) { create(:nomination, movie: movie2, category: category, year: year) }
  let!(:nomination3) { create(:nomination, movie: movie3, category: category, year: other_year) }

  describe '#results' do
    context 'without any filters' do
      it 'returns all movies for the year ordered by title' do
        query = described_class.new({}, user, year)

        result = query.results

        expect(result).to eq([movie1, movie2])
        expect(result).not_to include(movie3)
      end
    end

    context 'with search query' do
      it 'returns movies matching the title' do
        query = described_class.new({ query: 'avatar' }, user, year)

        result = query.results

        expect(result).to include(movie1)
        expect(result).not_to include(movie2)
      end

      it 'returns movies matching the english title' do
        query = described_class.new({ query: 'knight' }, user, year)

        result = query.results

        expect(result).to include(movie2)
        expect(result).not_to include(movie1)
      end

    end

    context 'with filter_by unwatched' do
      let!(:review) { create(:review, user: user, movie: movie1) }

      it 'returns only unwatched movies' do
        query = described_class.new({ filter_by: 'unwatched' }, user, year)

        result = query.results

        expect(result).to include(movie2)
        expect(result).not_to include(movie1)
      end

      it 'excludes movies with unrated reviews from watched' do
        create(:review, user: user, movie: movie2, stars: nil)
        query = described_class.new({ filter_by: 'unwatched' }, user, year)

        result = query.results

        expect(result).to include(movie2) # Unrated = unwatched
        expect(result).not_to include(movie1)
      end
    end

    context 'with filter_by watched' do
      let!(:review) { create(:review, user: user, movie: movie1) }

      it 'returns only watched movies' do
        query = described_class.new({ filter_by: 'watched' }, user, year)

        result = query.results

        expect(result).to include(movie1)
        expect(result).not_to include(movie2)
      end

      it 'excludes movies with only unrated reviews' do
        create(:review, user: user, movie: movie2, stars: nil)
        query = described_class.new({ filter_by: 'watched' }, user, year)

        result = query.results

        expect(result).to include(movie1)
        expect(result).not_to include(movie2) # Unrated = not watched
      end
    end

    context 'with sort_by duration' do
      it 'returns movies sorted by runtime descending' do
        query = described_class.new({ sort_by: 'duration' }, user, year)

        result = query.results

        expect(result.first).to eq(movie1)
        expect(result.last).to eq(movie2)
      end
    end

    context 'with sort_by shortest' do
      it 'returns movies sorted by runtime ascending' do
        query = described_class.new({ sort_by: 'shortest' }, user, year)

        result = query.results

        expect(result.first).to eq(movie2)
        expect(result.last).to eq(movie1)
      end
    end

    context 'with sort_by imdb_rating' do
      it 'returns movies sorted by rating descending' do
        query = described_class.new({ sort_by: 'imdb_rating' }, user, year)

        result = query.results

        expect(result.first).to eq(movie1)
        expect(result.last).to eq(movie2)
      end
    end

    context 'with sort_by my_rating' do
      let!(:review1) { create(:review, user: user, movie: movie1, stars: 5) }
      let!(:review2) { create(:review, user: user, movie: movie2, stars: 9) }

      it 'returns movies sorted by user rating descending' do
        query = described_class.new({ sort_by: 'my_rating' }, user, year)

        result = query.results.to_a

        expect(result.first).to eq(movie2)
        expect(result.last).to eq(movie1)
      end
    end

    context 'without user' do
      it 'ignores user-specific filters' do
        query = described_class.new({ filter_by: 'unwatched' }, nil, year)

        result = query.results

        expect(result).to include(movie1, movie2)
      end
    end

    context 'with sort_by most_nominated' do
      let(:category2) { create(:category) }
      let(:category3) { create(:category) }

      before do
        # movie1 has 1 nomination (from base setup)
        # movie2 has 3 nominations
        create(:nomination, movie: movie2, category: category2, year: year)
        create(:nomination, movie: movie2, category: category3, year: year)
      end

      it 'returns movies sorted by nomination count descending' do
        query = described_class.new({ sort_by: 'most_nominated' }, user, year)

        result = query.results.to_a

        # movie2 should appear before movie1 since it has more nominations
        movie1_index = result.index(movie1)
        movie2_index = result.index(movie2)
        expect(movie2_index).to be < movie1_index
      end

      it 'includes nominations_count attribute' do
        query = described_class.new({ sort_by: 'most_nominated' }, user, year)

        result = query.results.to_a

        movie2_result = result.find { |m| m.id == movie2.id }
        movie1_result = result.find { |m| m.id == movie1.id }

        expect(movie2_result['nominations_count'].to_i).to eq(3)
        expect(movie1_result['nominations_count'].to_i).to eq(1)
      end

      it 'only counts nominations for the specified year' do
        # movie3 has a nomination in another year, should not be counted for the selected year
        query = described_class.new({ sort_by: 'most_nominated' }, user, year)

        result = query.results

        expect(result).not_to include(movie3)
      end
    end

    context 'with category_id filter' do
      let(:category2) { create(:category, name: 'Best Director') }
      let!(:nomination_movie2_cat2) { create(:nomination, movie: movie2, category: category2, year: year) }

      it 'returns only movies nominated in the specified category' do
        query = described_class.new({ category_id: category2.id }, user, year)

        result = query.results

        expect(result).to include(movie2)
        expect(result).not_to include(movie1)
      end

      it 'filters by both category and year' do
        # Create a nomination for movie1 in another year
        create(:nomination, movie: movie1, category: category2, year: other_year)

        query = described_class.new({ category_id: category2.id }, user, year)

        result = query.results

        expect(result).to include(movie2)
        expect(result).not_to include(movie1) # movie1's nomination is for another year
      end

      it 'works with other filters' do
        create(:review, user: user, movie: movie2, stars: 8)

        query = described_class.new({ category_id: category2.id, filter_by: 'watched' }, user, year)

        result = query.results

        expect(result).to include(movie2)
      end

      it 'works with sorting' do
        movie4 = create(:movie, title: 'Dune', runtime: 155, rating: 8.5)
        create(:nomination, movie: movie4, category: category2, year: year)

        query = described_class.new({ category_id: category2.id, sort_by: 'imdb_rating' }, user, year)

        result = query.results.to_a

        expect(result.first).to eq(movie4) # rating 8.5
        expect(result.last).to eq(movie2)  # rating 7
      end
    end
  end
end
