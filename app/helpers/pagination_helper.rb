# Custom Kaminari paginate helper that adds turbo frame support
module PaginationHelper
  def paginate_with_turbo_frame(scope, turbo_frame: nil, **options)
    if turbo_frame
      # Generate pagination with turbo frame data attribute
      paginate(scope, **options).gsub(/<a /, %(<a data-turbo-frame="#{turbo_frame}" ))
    else
      paginate(scope, **options)
    end
  end
end
