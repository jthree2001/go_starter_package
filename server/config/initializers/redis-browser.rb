# Connects to redis server
config = Rails.root.join('config', 'secrets.yml')
settings = YAML.load(ERB.new(IO.read(config)).result)
RedisBrowser.configure(settings)
