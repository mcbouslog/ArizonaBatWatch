require 'bson'
require 'json'
require 'csv'
require 'open3'
require 'shellwords'
require 'yaml'

class ErrorLogger
  def initialize
    @error_file = File.open File.join(Dir.pwd, 'errors.txt'), 'w'
  end

  def log(file, message)
    @error_file.puts "#{ file }, #{ message }"
  end
end

config = YAML.load_file File.join Dir.pwd, 'config.yml'
# mysql = Mysql2::Client.new(
#   host: config['mysql']['host'],
#   username: config['mysql']['username'],
#   password: config['mysql']['password'],
#   database: config['mysql']['database']
# )

DESIRED_SUBJECT_LENGTH = 20
DESIRED_OVERLAP = 0

# Setup
input_directories = config['manifest']['input']
logger = ErrorLogger.new

# Go
files = input_directories.collect { |directory| Dir["#{ File.expand_path(directory) }/**/*"] }.flatten
files.reject! { |file| File.directory? file }

total = files.length
files.each.with_index do |file, index|
  puts "#{ index + 1 } / #{ total }"

  command = "ffprobe -v debug -report -print_format json -show_format -show_streams #{ Shellwords.escape file }"
  output = `#{ command }`
  json_output = JSON.parse output


  unless json_output['streams']
    logger.log file, 'could not parse file streams'
    next
  end

  video_stream = json_output['streams'].select { |stream| stream['codec_type'] == 'video'}.first
  audio_stream = json_output['streams'].select { |stream| stream['codec_type'] == 'audio'}.first

  unless video_stream
    logger.log file, 'could not find video stream'
    next
  end

  unless audio_stream
    logger.log file, 'could not find audio stream'
  end

  CSV.open('manifest.csv', 'wb') do |csv|
    puts "Creating CSV with #{total} files"
    csv << ["file_name", "start_time", "duration", "source_file"]
    
  end
  # video_codec = video_stream['codec_name']
  # duration = video_stream['duration'].to_i
  # width = video_stream['width']
  # height = video_stream['height']
  # pix_fmt = video_stream['pix_fmt']

  # escaped_file = mysql.escape file
  # mysql.query <<-SQL
  #     delete from manifest where source_file='#{ escaped_file }'
  #   SQL

  # pointer = 0
  # until pointer > duration
  #   id = BSON::ObjectId.new.to_s

  #   mysql.query <<-SQL
  #     insert into manifest
  #       (source_file, bson_id)
  #     values (
  #       '#{ file }',
  #       '#{ id }',
  #     )
  #   SQL

  #   pointer = pointer + DESIRED_SUBJECT_LENGTH - DESIRED_OVERLAP
  # end
end

        #{ pointer },
        # '#{ pix_fmt }',
        # '#{ video_codec }',
        #{ DESIRED_SUBJECT_LENGTH },
        # '#{ ARGV[0] }'