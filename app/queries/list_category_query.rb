class ListCategoryQuery
  attr_reader :matched_movies_count

  def initialize(params, year)
    @query = params[:query]
    @year = year
    @matched_movies_count = 0
  end

  def results
    categories = if @query.blank?
                   Category.all
                 else
                   # Search both category names and movie titles
                   category_ids = Category.joins(nominations: :movie)
                                          .where(nominations: { year: @year })
                                          .where(
                                            'categories.name LIKE ? OR movies.title LIKE ? OR movies.english_title LIKE ?',
                                            "%#{@query}%", "%#{@query}%", "%#{@query}%"
                                          )
                                          .distinct
                                          .pluck(:id)

                   # Count matched movies for display
                   @matched_movies_count = Movie.joins(:nominations)
                                                 .where(nominations: { year: @year, category_id: category_ids })
                                                 .where('movies.title LIKE ? OR movies.english_title LIKE ?',
                                                        "%#{@query}%", "%#{@query}%")
                                                 .distinct
                                                 .count

                   Category.where(id: category_ids)
                 end

    # Only return categories that have nominations in the selected year
    categories.for_year(@year)
  end
end
