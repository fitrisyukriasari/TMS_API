class DataParseController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'crack/xml'
  include DataParseHelper

  # Retrieve Trending Shows
  def trending

    # Initialise Final Data Response
    data = Array.new

    # Get data from server
    # Store retrieved data
    # into response variable
    response = HTTParty.get(trending_show_url, headers: headers)

    # Parse JSON Data
    # into json_response variable
    json_response = JSON.parse(response.body)

    # Loop through each JSON Object
    json_response.each do |show|

      # Get TVDB Show ID
      tvdb_show_id = show['show']['ids']['tvdb'].to_s

      # Get more data for show
      # Using tvdb_show_id
      # Store data into trakt_response
      trakt_response = HTTParty.get(
        search_url(tvdb_show_id),
        headers: headers
      )

      # Parse JSON
      # and
      # Store into trakt_json_response
      trakt_json_response = JSON.parse(trakt_response.body)

      # Initialise Variables
      show_title = show['show']['title']
      watchers = show['watchers']
      thumb_url = trakt_json_response[0]['show']['images']['fanart']['thumb']
      tvdb_id = show['show']['ids']['tvdb']
      overview = trakt_json_response[0]['show']['overview']
      year = trakt_json_response[0]['show']['year']
      status = trakt_json_response[0]['show']['status'].titleize
      poster_url = trakt_json_response[0]['show']['images']['poster']['medium']

      # Check for nil data
      unless trakt_json_response.nil?
        data << {
          show_title: show_title,
          watchers_count: watchers,
          thumb_image_url: thumb_url,
          tvdb_id: tvdb_id,
          overview: overview,
          year: year,
          status: status,
          poster_image_url: poster_url
        }
      end
    end

    # Render data
    render json: {
      response: data
    }
  end

  # Retrieve Shows By Their ID
  def id

    # TVDB ID
    tvdb_id = params[:tvdb_id]

    # Retrieve XML Response
    # From TVDB
    xml_reponse = HTTParty.get(show_url(tvdb_id))

    # Parse XML -> JSON
    json_parsed_response = Crack::XML.parse(xml_reponse.body)

    # Show and Episode Object
    show_data = json_parsed_response['Data']['Series']
    episodes_data = json_parsed_response['Data']['Episode']

    # Initialise Variables
    seasons = Array.new
    season = Array.new
    season_no = 0
    show_id = json_parsed_response['id']
    show_title = json_parsed_response['SeriesName']
    show_actors = json_parsed_response['Actors']
    show_genre = json_parsed_response['Genre']
    show_first_aired = json_parsed_response['FirstAired']
    show_air_time = json_parsed_response['Airs_Time']
    show_network = json_parsed_response['Network']
    show_overview = json_parsed_response['Overview']
    show_rating = json_parsed_response['Rating'].to_f
    show_rating_count = json_parsed_response['RatingCount'].to_i
    show_runtime = json_parsed_response['Runtime'].to_i
    show_status = json_parsed_response['Status'].titleize
    show_banner_url = image_base_url + json_parsed_response['banner']
    show_fanart_url = image_base_url + json_parsed_response['fanart']
    show_poster_url = image_base_url + json_parsed_response['poster']


    episodes_data.each do |episode|

      # Initialise Variables
      image = episode['filename']
      title = episode['EpisodeName']
      combined_season = episode['Combined_season'].to_i
      episode_id = episode['id']
      first_aired = episode['FirstAired']
      air_time = show_data['Airs_Time']
      overview = episode['Overview']
      rating = episode['Rating'].to_f
      rating_count = episode['RatingCount'].to_i
      writer = episode['Writer']
      episode_no = episode['EpisodeNumber'].to_i

      # Use conditionals for assignment
      image_url = nil ? image.nil : image_base_url + image
      episode_title = 'TBA' ? title.nil? : title
      air_date_time = if first_aired.nil? or air_time.nil?
                        nil
                      else
                        first_aired + ' ' + air_time
                      end

      # Check if Special Episode Season
      if combined_season = season_no
        season << {
          id: episode_id,
          title: episode_title,
          air_date_time: air_date_time,
          overview: overview,
          image: image_url,
          rating: rating,
          rating_count: rating_count,
          writer: writer,
          episode: episode_no
        }
      else
        if season.any?
          seasons << {
            episodes: season,
            'season' => season_no
          }
        end
        season_no += 1
        season = []
        season << {
          id: episode_id,
          title: episode_title,
          air_date_time: air_date_time,
          overview: overview,
          image: image_url,
          rating: rating,
          rating_count: rating_count,
          writer: writer,
          episode: episode_no
        }
      end
    end

    seasons << {
      episodes: season,
      'season' => season_no
    }

    data = {
      id: show_id,
      title: show_title,
      actors: show_actors,
      genre: show_genre,
      first_aired: show_first_aired,
      air_time: show_air_time,
      network: show_network,
      overview: show_overview,
      rating: show_rating,
      rating_count: show_rating_count,
      runtime: show_runtime,
      status: show_status,
      banner: show_banner_url,
      fanart: show_fanart_url,
      poster: show_poster_url,
      seasons: seasons
    }

    # Render Data
    render json: data
  end

  # Retrieve Show by Their Name
  def name

    # Show Name
    show_name = params[:show_name]

    # Get JSON Reponse
    response = HTTParty.get(
      search_url_name(show_name),
      headers: headers
    )

    # Check if response null
    json_response = response.body.length >= 2 ? JSON.parse(response.body) : nil

    # Initialise data
    data = Array.new

    # Add Rescue in case
    # data not retrieved
    begin
      json_response.each do |show|

        # Initialize variables
        score = show['score']
        show_obj = show['show']
        poster_image_url = show_obj['images']['poster']['medium']
        tvdb_id = show_obj['ids']['tvdb'].to_s
        banner_image_url = ''
        show_title = show_obj['title']
        show_overview = show_obj['overview']
        show_year = show_obj['year']
        show_status = show_obj['status'].titleize

        # Check for null
        unless poster_image_url.nil? or tvdb_id.nil?
          response = Nokogiri::XML(open(tvdb_banner_url(tvdb_id)))
          response.css('Banner').each do |obj|
            if obj.xpath('Language').inner_text == 'en' && obj.xpath('BannerType2').inner_text == 'graphical'
              banner_image_url = image_base_url + obj.xpath('BannerPath').inner_text
              break
            end
          end

        end

        # Check for null
        unless banner_image_url.empty? or show_year.nil?
          data << {
            title: show_title,
            overview: show_overview,
            year: show_year,
            status: show_status,
            tvdb_id: tvdb_id,
            banner: banner_image_url,
            poster: poster_image_url,
            score: score
          }
        end
      end

    rescue

      # Error Response
      data << {
        message: 'Error fetching data'
      }
    end

    # Render Data
    render json: {
      results: data
    }
  end
end
