require 'sinatra'
require 'json/ext'
require 'open-uri'
require 'google/cloud/storage'
require 'benchmark'

port = ENV['PORT'] || '8080'

set :server_settings, timeout: 3600
set :bind, '0.0.0.0'
set :port, port

get '/' do
  name = ENV['NAME'] || 'World'
  "Hello #{name}!"
end

get "/details" do
  port = ENV['PORT'] || 'Unknown'
  service = ENV['K_SERVICE'] || 'Unknown'
  revision = ENV['K_REVISION'] || 'Unknown'
  configuration = ENV['K_CONFIGURATION'] || 'Unknown'

  project_id = URI.open('http://metadata.google.internal/computeMetadata/v1/project/project-id', { 'Metadata-Flavor' => 'Google' }).read
  project_number = URI.open('http://metadata.google.internal/computeMetadata/v1/project/numeric-project-id', { 'Metadata-Flavor' => 'Google' }).read
  region = URI.open('http://metadata.google.internal/computeMetadata/v1/instance/region', { 'Metadata-Flavor' => 'Google' }).read.split('/').last
  instance_id = URI.open('http://metadata.google.internal/computeMetadata/v1/instance/id', { 'Metadata-Flavor' => 'Google' }).read
  service_account_email = URI.open('http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email', { 'Metadata-Flavor' => 'Google' }).read

  {
    port: port,
    service: service,
    revision: revision,
    configuration: configuration,
    project_id: project_id,
    project_number: project_number,
    region: region,
    instance_id: instance_id,
    service_account_email: service_account_email,
  }.to_json
end

get '/gcs-status' do
  storage = Google::Cloud::Storage.new

  gcs_status_bucket = ENV.fetch('GCS_STATUS_BUCKET')
  gcs_file = params.fetch(:file)

  bucket = storage.bucket gcs_status_bucket
  file = bucket.file gcs_file

  downloaded = file.download
  downloaded.rewind
  status_code = downloaded.read

  status Integer(status_code)
  status_code
end

get '/gcs-write' do
  storage = Google::Cloud::Storage.new
  gcs_status_bucket = ENV.fetch('GCS_STATUS_BUCKET')
  local_file_obj = StringIO.new("A" * 8 * 1000000000)
  file_name   = "large-file-#{DateTime.now.iso8601(3)}.txt"

  storage = Google::Cloud::Storage.new
  bucket  = storage.bucket gcs_status_bucket

  local_file_obj.rewind

  file = nil
  time = Benchmark.realtime do
    file = bucket.create_file local_file_obj, file_name
   end

   size_in_bytes = file.size

  status 200
  "File uploaded in #{time} seconds --- #{size_in_bytes} bytes --- #{(size_in_bytes / 1024 / 1024) / time} MB/s"
end