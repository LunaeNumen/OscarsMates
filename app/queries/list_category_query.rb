class ListCategoryQuery
  attr_reader :matched_movies_count

  def initialize(params, year)
    @query = params[:query]
    @year = year
    @matched_movies_count = 0
  end

  def results
    return Category.all.for_year(@year) if @query.blank?

    categories_with_query.for_year(@year)
  end

  private

  def categories_with_query
    category_ids = Category.joins(nominations: :movie)
                           .where(nominations: { year: @year })
                           .where(category_search_sql, *query_terms)
                           .distinct
                           .pluck(:id)

    @matched_movies_count = Movie.joins(:nominations)
                                 .where(nominations: { year: @year, category_id: category_ids })
                                 .where(movie_search_sql, *query_terms)
                                 .distinct
                                 .count

    Category.where(id: category_ids)
  end

  def query_terms
    term = "%#{@query}%"
    [term, term, term]
  end

  def category_search_sql
    'categories.name LIKE ? OR movies.title LIKE ? OR movies.english_title LIKE ?'
  end

  def movie_search_sql
    'movies.title LIKE ? OR movies.english_title LIKE ?'
  end
end
