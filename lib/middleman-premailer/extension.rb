# Require core library
require 'middleman-core'

# Extension namespace
module MiddlemanPremailer
  class Extension < ::Middleman::Extension
    option :premailer_options, {
      preserve_styles: true,
      output_encoding: 'UTF-8',
      replace_html_entities: true,
      escape_url_attributes: true
    }, 'Premailer options to pass in'

    option :plain_text, true, 'Create plain text version'

    option :show_warnings, false, 'Show Premailer warnings'

    def initialize(app, options_hash={}, &block)
      # Call super to build options from the options_hash
      super

      require 'premailer'

      app.after_build do |builder|
        files = ::Middleman::Util.all_files_under(config[:build_dir])

        options = extensions[:premailer].options

        files.each do |file|
          next unless file.extname == '.html'

          premailer = ::Premailer.new(file.to_s, options.premailer_options)

          builder.thor.say_status :premailer, file.to_s

          if options.plain_text
            File.open(file.to_s.gsub('html', 'txt'), 'w') do |fout|
              fout.puts premailer.to_plain_text
            end
          end

          File.open(file, 'w') do |fout|
            fout.puts premailer.to_inline_css
          end

          if options.show_warnings
            premailer.warnings.each do |w|
              builder.thor.say_status :premailer, "(#{w[:level]}) #{w[:message]} may not render properly in #{w[:clients]}"
            end
          end
        end

      end
    end

    def manipulate_resource_list(resources)
      if app.extensions[:premailer].options.plain_text
        res = []

        files = ::Middleman::Util.all_files_under(app.config[:build_dir])

        files.each do |file|
          next unless file.extname == '.html'

          file_path = file.to_s.split('/')
          file_path.shift
          text_file = file_path.join('/').gsub('.html', '.txt')

          source_file = File.join(app.root, app.config[:build_dir], text_file)

          if File.exist? source_file
            res << Middleman::Sitemap::Resource.new(app.sitemap, text_file, source_file)
          end
        end

        resources + res
      else
        resources
      end
    end
  end
end
