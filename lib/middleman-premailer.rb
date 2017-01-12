require "middleman-core"

Middleman::Extensions.register :premailer do
  require "middleman-premailer/extension"
  ::MiddlemanPremailer::Extension
end
