module DataParseHelper

  def trending_show_url
    'https://api-v2launch.trakt.tv/shows/trending?limit=25'
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'trakt-api-version' => '2',
      'trakt-api-key' => 'aec1b396a60919ff527a8137010c2da0e6ba48fece269d86158c860bfdc5f98b'
    }
  end

  def search_url(id)
    'https://api-v2launch.trakt.tv/search?id_type=tvdb&id=' + id.to_s
  end

  def show_url(id)
    'http://thetvdb.com/api/9DD79C4EF5C3AE90/series/' + id + '/all'
  end

  def image_base_url
    'http://www.thetvdb.com/banners/'
  end

  def search_url_name(show_name)
    'https://api-v2launch.trakt.tv/search?type=show&query=' + show_name
  end

  def tvdb_banner_url(tvdb_id)
    'http://thetvdb.com/api/9DD79C4EF5C3AE90/series/' + tvdb_id + '/banners.xml'
  end
end