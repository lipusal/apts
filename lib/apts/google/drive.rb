# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'stringio'
require_relative 'auth'

module Apts
  module Google
    class Drive
      SEEN_FILE_NAME = 'seen.txt'
      @file_id = nil

      def initialize
        @service = ::Google::Apis::DriveV3::DriveService.new
        @service.client_options.application_name = Auth::APPLICATION_NAME
        # @service.client_options.log_http_requests = true
        @service.authorization = Auth.new.authenticate

        @file_id = seen_file_id
      end

      def seen
        return [] if @file_id.nil?

        dest = StringIO.new
        @service.get_file(@file_id, download_dest: dest)
        dest.string.split "\n"
      end

      def mark_as_seen(unseen_listings)
        return if unseen_listings.empty?

        new_seen =
          if @file_id.nil?
            @file_id = create_seen_file # TODO NOW define what to extract from this
            []
          else
            seen
          end

        new_seen.concat unseen_listings.map(&:id)
        content = StringIO.new(new_seen.join("\n") << "\n")
        file_metadata = ::Google::Apis::DriveV3::File.new
        @service.update_file(@file_id, file_metadata, upload_source: content, content_type: 'text/plain')
      end

      private

      def create_seen_file
        file_metadata = ::Google::Apis::DriveV3::File.new(name: SEEN_FILE_NAME, content_type: 'text/plain', fields: 'id')
        @service.create_file(file_metadata)
      end

      def seen_file_id
        response = @service.list_files(page_size: 10, fields: 'nextPageToken, files(id, name)')
        response.files.find { |f| f.name == SEEN_FILE_NAME }&.id
      end
    end
  end
end
