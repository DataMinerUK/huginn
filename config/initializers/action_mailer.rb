# Read smtp config out of a config/smtp.yml file

# smtp_config = YAML::load(ERB.new(File.read(Rails.root.join('config', 'smtp.yml'))).result)
# if smtp_config.keys.include? Rails.env
#   Huginn::Application.config.action_mailer.smtp_settings = smtp_config[Rails.env].symbolize_keys
# end

Hugin::Application.configure do
  config.action_mailer.smtp_settings = {
    :address   => "smtp.mandrillapp.com",
    :port      => 587, # ports 25 and 2525 are also supported with STARTTLS
    :enable_starttls_auto => true, # detects and uses STARTTLS
    :user_name => ENV['MANDRILL_USERNAME'],
    :password  => ENV['MANDRILL_APIKEY'], # SMTP password is any valid API key
    :authentication => 'login', # Mandrill supports 'plain' or 'login'
    :domain => 'yourdomain.com', # your domain to identify your server when connecting
  }
end

# Huginn::Application.config.action_mailer.smtp_settings = {
#   address: ENV['SMTP_SERVER'] || 'smtp.gmail.com',
#   port: ENV['SMTP_PORT'] || 587,
#   domain: ENV['SMTP_DOMAIN'],
#   authentication: ENV['SMTP_AUTHENTICATION'] || 'plain',
#   enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'true' ? true : false,
#   user_name: ENV['SMTP_USER_NAME'],
#   password: ENV['SMTP_PASSWORD']
# }
